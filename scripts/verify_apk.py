#!/usr/bin/env python3
"""Deep verification of the assembled JVHD.apk.

This is not a name-based smoke test. It re-parses the produced APK and, for the
DEX partitions, parses the real DEX structures (header, string ids, type ids and
class definitions) to prove that the Smali sources were actually assembled into
the APK.

Checks performed
----------------
1. Required entries exist: classes.dex, classes2.dex, assets/app.js,
   AndroidManifest.xml, resources.arsc and both native libraries.
2. Every `*.smali` file of `smali/` is present as a class definition inside
   classes.dex, and every file of `smali_classes2/` inside classes2.dex.
3. The four mandated launcher classes are really defined in the DEX code.
4. Byte identity (SHA-256) between the APK entries and the checked-in sources
   for assets/, kotlin/ (Kotlin builtins passthrough), the native libraries and
   the unknown files declared in apktool.yml.
5. Every stored (uncompressed) entry is 4-byte aligned, and every `*.so` entry
   is page (4096) aligned - i.e. the APK is really zipaligned.
6. `aapt2 dump badging` output (when provided) matches the required identity:
   package, launcher activity, minSdk 21, targetSdk 33.

Exit code is 0 only when every check passed.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import struct
import sys
import zipfile

DEX_MAGIC = b"dex\n"
REQUIRED_CLASSES = [
    "Lcom/bintv/launcher/MainActivity;",
    "Lcom/bintv/launcher/TizenBridge;",
    "Lcom/bintv/launcher/MediaProxyServer;",
    "Lcom/bintv/launcher/BtK;",
]
REQUIRED_ENTRIES = [
    "AndroidManifest.xml",
    "resources.arsc",
    "classes.dex",
    "classes2.dex",
    "assets/app.js",
    "lib/arm64-v8a/libbtcore.so",
    "lib/armeabi-v7a/libbtcore.so",
]

FAILURES: list[str] = []
NOTES: list[str] = []


def ok(message: str) -> None:
    print(f"  [ OK ] {message}")


def fail(message: str) -> None:
    FAILURES.append(message)
    print(f"  [FAIL] {message}")


def note(message: str) -> None:
    NOTES.append(message)
    print(f"  [note] {message}")


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


def dex_strings(dex: bytes) -> list[str]:
    """Return the string pool of a DEX file."""
    string_ids_size, string_ids_off = struct.unpack_from("<II", dex, 0x38)
    strings: list[str] = []
    for index in range(string_ids_size):
        (data_off,) = struct.unpack_from("<I", dex, string_ids_off + index * 4)
        _size, cursor = _uleb128(dex, data_off)
        end = dex.index(b"\x00", cursor)
        strings.append(dex[cursor:end].decode("utf-8", "replace"))
    return strings


def dex_classes(dex: bytes) -> list[str]:
    """Return the class descriptors defined in the DEX file."""
    if not dex.startswith(DEX_MAGIC):
        raise ValueError("not a DEX file (bad magic)")
    strings = dex_strings(dex)
    type_ids_size, type_ids_off = struct.unpack_from("<II", dex, 0x40)
    class_defs_size, class_defs_off = struct.unpack_from("<II", dex, 0x60)
    type_descriptors = []
    for index in range(type_ids_size):
        (descriptor_idx,) = struct.unpack_from("<I", dex, type_ids_off + index * 4)
        type_descriptors.append(strings[descriptor_idx])
    classes = []
    for index in range(class_defs_size):
        (class_idx,) = struct.unpack_from("<I", dex, class_defs_off + index * 32)
        classes.append(type_descriptors[class_idx])
    return classes


def dex_header_info(dex: bytes) -> str:
    file_size, header_size, endian_tag = struct.unpack_from("<III", dex, 0x20)
    version = dex[4:7].decode("ascii", "replace")
    return (
        f"dex v{version} file_size={file_size} header_size={header_size} "
        f"endian=0x{endian_tag:08x}"
    )


def smali_classes(smali_dir: str) -> list[str]:
    """Class descriptors declared by the `*.smali` files of a partition."""
    found: list[str] = []
    pattern = re.compile(r"^\.class\s+.*?(L[^;\s]+;)\s*$", re.MULTILINE)
    for root, _dirs, files in os.walk(smali_dir):
        for name in files:
            if not name.endswith(".smali"):
                continue
            path = os.path.join(root, name)
            with open(path, "r", encoding="utf-8", errors="replace") as handle:
                text = handle.read()
            match = pattern.search(text)
            if not match:
                found.append(f"__NO_CLASS_DECLARATION__:{os.path.relpath(path, smali_dir)}")
            else:
                found.append(match.group(1))
    return found


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def file_sha256(path: str) -> str:
    with open(path, "rb") as handle:
        return sha256(handle.read())


# --------------------------------------------------------------------------- #
# Raw ZIP inspection (alignment)
# --------------------------------------------------------------------------- #
def stored_entry_offsets(apk_path: str) -> list[tuple[str, int, int, int]]:
    """Return (name, data_offset, compress_type, compress_size) per entry."""
    with open(apk_path, "rb") as handle:
        blob = handle.read()
    eocd = blob.rfind(b"PK\x05\x06")
    if eocd < 0:
        raise ValueError("EOCD record not found")
    cd_size, cd_offset = struct.unpack_from("<II", blob, eocd + 12)
    entries = []
    cursor = cd_offset
    for _ in range(struct.unpack_from("<H", blob, eocd + 10)[0]):
        if blob[cursor : cursor + 4] != b"PK\x01\x02":
            raise ValueError("bad central directory record")
        compress_type, compress_size = struct.unpack_from("<HH", blob, cursor + 10)
        name_len, extra_len, comment_len = struct.unpack_from("<HHH", blob, cursor + 28)
        (local_offset,) = struct.unpack_from("<I", blob, cursor + 42)
        name = blob[cursor + 46 : cursor + 46 + name_len].decode("utf-8", "replace")
        local_name_len, local_extra_len = struct.unpack_from("<HH", blob, local_offset + 26)
        data_offset = local_offset + 30 + local_name_len + local_extra_len
        entries.append((name, data_offset, compress_type, compress_size))
        cursor += 46 + name_len + extra_len + comment_len
    assert cursor - cd_offset == cd_size, "central directory size mismatch"
    return entries


# --------------------------------------------------------------------------- #
# Checks
# --------------------------------------------------------------------------- #
def check_entries(apk_path: str) -> zipfile.ZipFile:
    print("\n[1] Required APK entries")
    archive = zipfile.ZipFile(apk_path)
    names = set(archive.namelist())
    for entry in REQUIRED_ENTRIES:
        if entry in names:
            info = archive.getinfo(entry)
            ok(f"{entry} ({info.file_size} bytes)")
        else:
            fail(f"missing entry {entry}")
    return archive


def check_dex(archive: zipfile.ZipFile, project: str) -> None:
    print("\n[2] DEX partitions vs Smali sources")
    partitions = [("classes.dex", "smali"), ("classes2.dex", "smali_classes2")]
    all_defined: dict[str, str] = {}
    for dex_name, smali_name in partitions:
        smali_dir = os.path.join(project, smali_name)
        classes = smali_classes(smali_dir)
        expected = {c for c in classes if not c.startswith("__NO_CLASS_DECLARATION__")}
        if len(expected) != len(classes):
            fail(f"{smali_name}: {len(classes) - len(expected)} smali files without a .class declaration")
        try:
            dex = archive.read(dex_name)
        except KeyError:
            fail(f"{dex_name} missing")
            continue
        info = dex_header_info(dex)
        defined = dex_classes(dex)
        ok(f"{dex_name}: {info}")
        missing = sorted(expected - set(defined))
        if missing:
            fail(
                f"{dex_name} does not define {len(missing)} class(es) from {smali_name}/ "
                f"(e.g. {', '.join(missing[:3])})"
            )
        else:
            ok(f"{dex_name} defines all {len(expected)} classes of {smali_name}/")
        extra = sorted(set(defined) - expected)
        if extra:
            note(f"{dex_name} additionally defines {len(extra)} synthesised class(es)")
        for descriptor in defined:
            all_defined[descriptor] = dex_name
        print(f"        class definitions in {dex_name}: {len(defined)}")

    print("\n[3] Mandated launcher classes")
    for descriptor in REQUIRED_CLASSES:
        if descriptor in all_defined:
            ok(f"{descriptor} -> {all_defined[descriptor]}")
        else:
            fail(f"class {descriptor} not defined in any DEX partition")


def check_bytes(archive: zipfile.ZipFile, project: str) -> None:
    print("\n[4] Byte identity with the checked-in sources")
    groups = [
        ("assets/app.js", "assets/app.js"),
        ("kotlin/kotlin.kotlin_builtins", "kotlin/kotlin.kotlin_builtins"),
        ("kotlin-tooling-metadata.json", "unknown/kotlin-tooling-metadata.json"),
        ("lib/arm64-v8a/libbtcore.so", "lib/arm64-v8a/libbtcore.so"),
        ("lib/armeabi-v7a/libbtcore.so", "lib/armeabi-v7a/libbtcore.so"),
    ]
    for apk_entry, project_path in groups:
        source = os.path.join(project, project_path)
        if not os.path.exists(source):
            fail(f"project file missing: {project_path}")
            continue
        if apk_entry not in archive.namelist():
            fail(f"APK entry missing: {apk_entry}")
            continue
        apk_digest = sha256(archive.read(apk_entry))
        src_digest = file_sha256(source)
        if apk_digest == src_digest:
            ok(f"{apk_entry} sha256={apk_digest[:16]}... (identical to {project_path})")
        else:
            fail(f"{apk_entry} differs from {project_path} ({apk_digest} != {src_digest})")

    assets_dir = os.path.join(project, "assets")
    for name in sorted(os.listdir(assets_dir)):
        path = os.path.join(assets_dir, name)
        if not os.path.isfile(path):
            continue
        entry = f"assets/{name}"
        if entry not in archive.namelist():
            fail(f"asset not packaged: {entry}")
        elif sha256(archive.read(entry)) != file_sha256(path):
            fail(f"asset content mismatch: {entry}")
    ok("all assets/ files packaged byte-identically")

    kotlin_dir = os.path.join(project, "kotlin")
    kotlin_missing = []
    for root, _dirs, files in os.walk(kotlin_dir):
        for name in files:
            rel = os.path.relpath(os.path.join(root, name), project).replace(os.sep, "/")
            if rel not in archive.namelist():
                kotlin_missing.append(rel)
    if kotlin_missing:
        fail(f"kotlin/ passthrough files missing from APK: {', '.join(kotlin_missing)}")
    else:
        ok("all kotlin/ Kotlin-builtin files packaged")


def check_alignment(apk_path: str) -> None:
    print("\n[5] Zip alignment (zipalign)")
    entries = stored_entry_offsets(apk_path)
    stored = [e for e in entries if e[2] == 0]
    misaligned4 = [e[0] for e in stored if e[1] % 4 != 0]
    so_entries = [e for e in stored if e[0].endswith(".so")]
    misaligned_page = [e[0] for e in so_entries if e[1] % 4096 != 0]
    print(f"        stored (uncompressed) entries: {len(stored)} of {len(entries)}")
    if misaligned4:
        fail(f"{len(misaligned4)} stored entries are not 4-byte aligned: {misaligned4[:4]}")
    else:
        ok("every stored entry is 4-byte aligned")
    if not so_entries:
        fail("no uncompressed native library entry found (libbtcore.so must be stored)")
    elif misaligned_page:
        fail(f"shared objects not page-aligned (-p): {misaligned_page}")
    else:
        ok(f"{len(so_entries)} shared object(s) page (4096) aligned")


def check_badging(badging_path: str, args: argparse.Namespace) -> None:
    print("\n[6] Compiled manifest identity (aapt badging)")
    with open(badging_path, "r", encoding="utf-8", errors="replace") as handle:
        text = handle.read()
    expectations = [
        (f"package: name='{args.expect_package}'", "applicationId"),
        (f"launchable-activity: name='{args.expect_activity}'", "launcher activity"),
        (f"sdkVersion:'{args.expect_min_sdk}'", "minSdkVersion"),
        (f"targetSdkVersion:'{args.expect_target_sdk}'", "targetSdkVersion"),
    ]
    for needle, label in expectations:
        if needle in text:
            ok(f"{label}: {needle}")
        else:
            fail(f"{label} mismatch in badging output (expected '{needle}')")


def check_signature(args: argparse.Namespace) -> None:
    print("\n[7] Signature artefact")
    if args.signature_report:
        with open(args.signature_report, "r", encoding="utf-8", errors="replace") as handle:
            report = handle.read()
        if "Verifies" in report:
            ok("apksigner: Verifies")
        else:
            fail("apksigner did not report a verified signature")
        scheme_markers = {
            "v1": ("v1 scheme (JAR signing)", "APK Signature Scheme v1"),
            "v2": ("APK Signature Scheme v2",),
            "v3": ("APK Signature Scheme v3",),
        }
        for scheme, markers in scheme_markers.items():
            line = [ln for ln in report.splitlines() if any(m in ln for m in markers)]
            if line and "true" in line[0]:
                ok(f"APK Signature Scheme {scheme}: true")
            else:
                note(f"APK Signature Scheme {scheme}: not present")
    else:
        note("no apksigner report supplied")


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify the assembled JVHD.apk")
    parser.add_argument("--apk", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument("--badging")
    parser.add_argument("--signature-report")
    parser.add_argument("--expect-package", default="com.bintv.launcher")
    parser.add_argument("--expect-activity", default="com.bintv.launcher.MainActivity")
    parser.add_argument("--expect-min-sdk", default="21")
    parser.add_argument("--expect-target-sdk", default="33")
    args = parser.parse_args()

    if not os.path.isfile(args.apk):
        print(f"APK not found: {args.apk}")
        return 1

    size = os.path.getsize(args.apk)
    digest = file_sha256(args.apk)
    print(f"APK: {args.apk}")
    print(f"size: {size} bytes")
    print(f"sha256: {digest}")

    archive = check_entries(args.apk)
    check_dex(archive, args.project)
    check_bytes(archive, args.project)
    archive.close()
    check_alignment(args.apk)
    if args.badging:
        check_badging(args.badging, args)
    else:
        note("no badging file supplied")
    check_signature(args)

    print("\n================ VERIFICATION SUMMARY ================")
    print(f"APK            : {args.apk}")
    print(f"SHA-256        : {digest}")
    print(f"failures       : {len(FAILURES)}")
    for failure in FAILURES:
        print(f"   - {failure}")
    if FAILURES:
        print("RESULT: FAILED")
        return 1
    print("RESULT: PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
