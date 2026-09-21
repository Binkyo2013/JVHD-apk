#!/usr/bin/env python3
"""Link-level verification of the DEX files inside the built APK.

This is the check that the crash this repository shipped with needed: the APK
defined `com.JVHD.vip.MainActivity`, but **not** `kotlin.jvm.internal.Intrinsics`
(351 references), `kotlin.Unit`, `kotlin.jvm.functions.Function*`,
`kotlin.jvm.internal.Lambda`, ... nor the app's own `com.JVHD.vip.RawResponse$1`.
Installing it succeeded, the launcher icon appeared, and the app died with
`java.lang.NoClassDefFoundError: kotlin.jvm.internal.Intrinsics` before the first
frame was drawn - which on Android looks exactly like "the app closes itself".

`verify_apk.py` proves that every `*.smali` file of the project ended up in the
right DEX file; it cannot see a class that no `.smali` file defines in the first
place.  This script re-parses the produced DEX structures and checks the
*program* instead of the file list:

  [1] no dangling types      - every type descriptor referenced anywhere in the
                               DEX is either defined by the APK or provided by
                               the platform.  (Catches stubs such as
                               `Lkotlin/jvm/internal/Intrinsics;` or
                               `Lcom/JVHD/vip/RawResponse$1;`.)
  [2] no dangling members    - every field/method id owned by a class the APK
                               defines resolves on that class or one of its
                               supertypes (walking into platform classes is
                               accepted).  (Catches "class exists but the method
                               the caller expects does not".)
  [3] no dangling supertypes - the superclass/interface chain of every defined
                               class is defined or platform.

Usage:

    python3 scripts/verify_dex_links.py --apk build/outputs/apk/JVHD.apk

Exit code 0 only when every check passed.
"""

from __future__ import annotations

import argparse
import os
import struct
import sys
import zipfile
from collections import defaultdict

DEX_MAGIC = b"dex\n"

# Namespaces the Android platform (or the JVM) provides at runtime.  Everything
# else referenced by the DEX must be defined by the APK itself.
PLATFORM_PREFIXES = (
    "Landroid/",
    "Landroidx/",
    "Ljava/",
    "Ljavax/",
    "Ldalvik/",
    "Llibcore/",
    "Lsun/",
    "Lorg/apache/",
    "Lorg/json/",
    "Lorg/w3c/",
    "Lorg/xmlpull/",
    "Lorg/xml/",
    "Lorg/kxml2/",
    "Lorg/ietf/",
    "Lorg/chromium/",
    "Lorg/slf4j/",
    "Lcom/android/",
    "Lcom/google/android/",
    "Ljunit/",
)

FAILURES: list[str] = []


def ok(message: str) -> None:
    print(f"  [ OK ] {message}")


def fail(message: str) -> None:
    FAILURES.append(message)
    print(f"  [FAIL] {message}")


PRIMITIVE_DESCRIPTORS = set("VZBSCIJFD")


def is_primitive(descriptor: str) -> bool:
    return len(descriptor) == 1 and descriptor in PRIMITIVE_DESCRIPTORS


def base_type(descriptor: str) -> str:
    """`[[Lcom/x/Y;` -> `Lcom/x/Y;`, `[I` -> `I`."""
    return descriptor.lstrip("[")


def is_platform(descriptor: str) -> bool:
    base = base_type(descriptor)
    if is_primitive(base):
        return True
    return base.startswith(PLATFORM_PREFIXES)


# --------------------------------------------------------------------------- #
# DEX parsing
# --------------------------------------------------------------------------- #
def _uleb128(data: bytes, offset: int) -> tuple[int, int]:
    result = 0
    shift = 0
    while True:
        byte = data[offset]
        offset += 1
        result |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return result, offset
        shift += 7


class Dex:
    """The parts of a DEX file this check needs."""

    def __init__(self, name: str, data: bytes):
        if not data.startswith(DEX_MAGIC):
            raise ValueError(f"{name}: not a DEX file")
        self.name = name
        self.data = data
        self.version = data[4:7].decode("ascii", "replace")
        self.strings = self._strings()
        self.types = self._types()
        self.protos = self._protos()
        self.method_ids = self._method_ids()
        self.field_ids = self._field_ids()
        self.classes = self._class_defs()

    def _strings(self) -> list[str]:
        size, off = struct.unpack_from("<II", self.data, 0x38)
        out = []
        for i in range(size):
            (data_off,) = struct.unpack_from("<I", self.data, off + i * 4)
            # string_data_item: uleb128 utf16 length, then MUTF-8 bytes, NUL terminated
            _utf16_length, cursor = _uleb128(self.data, data_off)
            end = self.data.index(b"\x00", cursor)
            out.append(self.data[cursor:end].decode("utf-8", "replace"))
        return out

    def _types(self) -> list[str]:
        size, off = struct.unpack_from("<II", self.data, 0x40)
        return [self.strings[struct.unpack_from("<I", self.data, off + i * 4)[0]]
                for i in range(size)]

    def _protos(self) -> list[tuple[str, list[str]]]:
        """proto id -> (return type descriptor, [parameter descriptors])"""
        out = []
        size, off = struct.unpack_from("<II", self.data, 0x48)
        for i in range(size):
            shorty, ret, params = struct.unpack_from("<III", self.data, off + i * 12)
            param_types = []
            if params:
                (count,) = struct.unpack_from("<I", self.data, params)
                param_types = [self.types[struct.unpack_from("<H", self.data, params + 4 + j * 2)[0]]
                               for j in range(count)]
            out.append((self.types[ret], param_types))
        return out

    def _method_ids(self) -> list[tuple[str, str, str, list[str]]]:
        """(owner, name, return type, parameter types)"""
        out = []
        size, off = struct.unpack_from("<II", self.data, 0x58)
        for i in range(size):
            class_idx, proto_idx, name_idx = struct.unpack_from("<HHI", self.data, off + i * 8)
            ret, params = self.protos[proto_idx]
            out.append((self.types[class_idx], self.strings[name_idx], ret, params))
        return out

    def _field_ids(self) -> list[tuple[str, str, str]]:
        """(owner, name, type)"""
        out = []
        size, off = struct.unpack_from("<II", self.data, 0x50)
        for i in range(size):
            class_idx, type_idx, name_idx = struct.unpack_from("<HHI", self.data, off + i * 8)
            out.append((self.types[class_idx], self.strings[name_idx], self.types[type_idx]))
        return out

    def _class_defs(self) -> dict[str, dict]:
        """descriptor -> {super, interfaces, methods, fields}"""
        size, off = struct.unpack_from("<II", self.data, 0x60)
        out: dict[str, dict] = {}
        for i in range(size):
            base = off + i * 32
            class_idx, _access, super_idx, interfaces_off, _src, _ann, class_data_off, _static = \
                struct.unpack_from("<IIIIIIII", self.data, base)
            descriptor = self.types[class_idx]
            entry = {
                "super": self.types[super_idx] if super_idx != 0xFFFFFFFF else None,
                "interfaces": [],
                "methods": set(),
                "fields": set(),
            }
            if interfaces_off:
                (count,) = struct.unpack_from("<I", self.data, interfaces_off)
                entry["interfaces"] = [
                    self.types[struct.unpack_from("<H", self.data, interfaces_off + 4 + j * 2)[0]]
                    for j in range(count)
                ]
            # the encoded members themselves are resolved in class_data_members()
            out[descriptor] = entry
        return out

    def class_data_members(self) -> dict[str, dict]:
        """Second pass: resolve the member indexes of every class_data_item."""
        size, off = struct.unpack_from("<II", self.data, 0x60)
        out: dict[str, dict] = {}
        for i in range(size):
            base = off + i * 32
            class_idx, _access, _super, _iface, _src, _ann, class_data_off, _static = \
                struct.unpack_from("<IIIIIIII", self.data, base)
            descriptor = self.types[class_idx]
            methods: set[tuple[str, str, tuple[str, ...]]] = set()
            fields: set[tuple[str, str]] = set()
            if class_data_off:
                cursor = class_data_off
                static_fields, cursor = _uleb128(self.data, cursor)
                instance_fields, cursor = _uleb128(self.data, cursor)
                direct_methods, cursor = _uleb128(self.data, cursor)
                virtual_methods, cursor = _uleb128(self.data, cursor)
                field_index = 0
                for position in range(static_fields + instance_fields):
                    if position == static_fields:
                        field_index = 0
                    idx_diff, cursor = _uleb128(self.data, cursor)
                    _access, cursor = _uleb128(self.data, cursor)
                    field_index += idx_diff
                    owner, name, type_ = self.field_ids[field_index]
                    fields.add((name, type_))
                # `method_idx_diff` is a delta inside each list: the first direct
                # method is encoded directly and the virtual list restarts its own
                # running index (verified against real DEX files: continuing the
                # index across the boundary resolves 229 members to the wrong
                # owner, restarting resolves none).
                method_index = 0
                for position in range(direct_methods + virtual_methods):
                    if position == direct_methods:
                        method_index = 0
                    idx_diff, cursor = _uleb128(self.data, cursor)
                    _access, cursor = _uleb128(self.data, cursor)
                    _code_off, cursor = _uleb128(self.data, cursor)
                    method_index += idx_diff
                    owner, name, ret, params = self.method_ids[method_index]
                    methods.add((name, ret, tuple(params)))
            out[descriptor] = {"methods": methods, "fields": fields}
        return out


# --------------------------------------------------------------------------- #
# checks
# --------------------------------------------------------------------------- #
def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apk", required=True)
    args = parser.parse_args()

    with zipfile.ZipFile(args.apk) as archive:
        dex_names = sorted(n for n in archive.namelist()
                           if n.startswith("classes") and n.endswith(".dex"))
        dexes = [Dex(name, archive.read(name)) for name in dex_names]

    print(f"APK: {args.apk}")
    for dex in dexes:
        print(f"  {dex.name}: dex v{dex.version}, {len(dex.classes)} classes, "
              f"{len(dex.types)} types, {len(dex.method_ids)} method ids")

    defined: dict[str, dict] = {}
    for dex in dexes:
        defined.update(dex.classes)
    members: dict[str, dict] = {}
    for dex in dexes:
        members.update(dex.class_data_members())
    for descriptor, entry in defined.items():
        entry.update(members.get(descriptor, {"methods": set(), "fields": set()}))

    print(f"\n[1] dangling type references ({len(defined)} classes defined, "
          f"{sum(len(d.types) for d in dexes)} type ids)")
    dangling: dict[str, set[str]] = defaultdict(set)
    for dex in dexes:
        for descriptor in dex.types:
            base = base_type(descriptor)
            if descriptor in defined or base in defined or is_platform(descriptor):
                continue
            dangling[base].add(dex.name)
    if dangling:
        for descriptor in sorted(dangling):
            fail(f"{descriptor} is referenced but not defined "
                 f"({', '.join(sorted(dangling[descriptor]))})")
    else:
        ok("every non-platform type id is defined by the APK")

    print("\n[2] dangling superclass/interface references")
    bad_supers = []
    for descriptor, entry in defined.items():
        if entry["super"] and entry["super"] not in defined and not is_platform(entry["super"]):
            bad_supers.append((descriptor, entry["super"]))
        for interface in entry["interfaces"]:
            if interface not in defined and not is_platform(interface):
                bad_supers.append((descriptor, interface))
    if bad_supers:
        for descriptor, parent in bad_supers:
            fail(f"{descriptor} extends/implements the undefined type {parent}")
    else:
        ok("every superclass/interface of every defined class is defined or platform")

    print("\n[3] dangling member references (field/method ids owned by app classes)")

    def resolves(descriptor: str, kind: str, name: str, signature) -> bool:
        seen = set()
        stack = [descriptor]
        while stack:
            current = stack.pop()
            if current in seen:
                continue
            seen.add(current)
            entry = defined.get(current)
            if entry is None:
                # walking out of the APK: the platform owns the rest of the chain
                return is_platform(current)
            if kind == "method":
                if any(m[0] == name and (m[1], m[2]) == signature for m in entry["methods"]):
                    return True
            else:
                if any(f[0] == name and f[1] == signature for f in entry["fields"]):
                    return True
            if entry["super"]:
                stack.append(entry["super"])
            stack.extend(entry["interfaces"])
        return False

    unresolved: list[str] = []
    checked = 0
    for dex in dexes:
        for owner, name, ret, params in dex.method_ids:
            if owner not in defined:
                continue  # platform owner (java.*, android.*, ...) - not our concern
            checked += 1
            if not resolves(owner, "method", name, (ret, tuple(params))):
                unresolved.append(f"method {owner}->{name}({''.join(params)}){ret}")
        for owner, name, type_ in dex.field_ids:
            if owner not in defined:
                continue
            checked += 1
            if not resolves(owner, "field", name, type_):
                unresolved.append(f"field {owner}->{name}:{type_}")
    if unresolved:
        for item in sorted(set(unresolved)):
            fail(f"unresolved {item}")
    else:
        ok(f"{checked} field/method ids owned by APK classes all resolve")

    print()
    if FAILURES:
        print(f"RESULT: FAILED ({len(FAILURES)} problem(s))")
        return 1
    print("RESULT: PASSED (the DEX files link completely)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
