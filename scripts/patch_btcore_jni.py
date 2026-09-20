#!/usr/bin/env python3
"""Rename the JNI export of libbtcore.so after the package rename.

The native library exports exactly one JNI function, whose name encodes the
Java package of the declaring class:

    Java_com_bintv_launcher_TizenBridge_n0   (old package com.bintv.launcher)
    Java_com_JVHD_vip_TizenBridge_n0         (new package com.JVHD.vip)

`TizenBridge.c0()` (the only caller, reached from JavaScript as
`AndroidBridge.c0()`) resolves it through the normal JNI name mangling, so
after renaming the Java package the export must be renamed as well -
otherwise `UnsatisfiedLinkError` makes `c0()` return "" and the fail-closed
user gate blocks every login ("Thiet bi khong ho tro xac thuc").

The new name is shorter (33 vs 39 chars), so it is patched in place inside
`.dynstr` (NUL-padded, later string offsets unchanged) and both dynamic hash
tables (`.hash` and `.gnu.hash`) are rebuilt from scratch.  No other byte of
the libraries changes.  Run:

    python3 scripts/patch_btcore_jni.py            # patch lib/* in place
    python3 scripts/patch_btcore_jni.py --check    # verify only

The static `.symtab`/`.strtab` (debug info, unused at runtime) is patched too
when present so that `readelf -s` stays consistent.
"""

from __future__ import annotations

import os
import struct
import sys

OLD_NAME = b"Java_com_bintv_launcher_TizenBridge_n0"
NEW_NAME = b"Java_com_JVHD_vip_TizenBridge_n0"

assert len(NEW_NAME) < len(OLD_NAME)

DT_HASH = 4
DT_STRTAB = 5
DT_SYMTAB = 6
DT_STRSZ = 10
DT_SYMENT = 11
DT_GNUHASH = 0x6FFFFEF5


def elf_hash(name: bytes) -> int:
    h = 0
    for c in name:
        h = (h << 4) + c
        g = h & 0xF0000000
        if g:
            h ^= g >> 24
        h &= ~g
    return h & 0xFFFFFFFF


def gnu_hash(name: bytes) -> int:
    h = 5381
    for c in name:
        h = ((h * 33) + c) & 0xFFFFFFFF
    return h


class Elf:
    def __init__(self, data: bytearray):
        self.d = data
        if data[:4] != b"\x7fELF":
            raise ValueError("not an ELF file")
        self.is64 = data[4] == 2
        if self.is64:
            (self.phoff, self.shoff, _, _, self.phentsz, self.phnum,
             self.shentsz, self.shnum, _) = struct.unpack_from("<QQIHHHHHH", data, 0x20)
            self.dynfmt = "<qQ"
        else:
            (self.phoff, self.shoff, _, _, self.phentsz, self.phnum,
             self.shentsz, self.shnum, _) = struct.unpack_from("<IIIHHHHHH", data, 0x1C)
            self.dynfmt = "<ii"
        self.dynsz = struct.calcsize(self.dynfmt)
        self.loads = []
        for i in range(self.phnum):
            o = self.phoff + i * self.phentsz
            if self.is64:
                (ptyp, _, poff, pvaddr, _, pfilesz, _, _) = struct.unpack_from("<IIQQQQQQ", data, o)
            else:
                (ptyp, poff, pvaddr, _, pfilesz, _, _, _) = struct.unpack_from("<IIIIIIII", data, o)
            if ptyp == 1:  # PT_LOAD
                self.loads.append((pvaddr, poff, pfilesz))

    def v2o(self, va: int) -> int:
        for v, o, s in self.loads:
            if v <= va < v + s:
                return va - v + o
        raise ValueError(f"vaddr 0x{va:x} not in a PT_LOAD segment")

    def dynamic(self) -> dict[int, int]:
        for i in range(self.phnum):
            o = self.phoff + i * self.phentsz
            (ptyp,) = struct.unpack_from("<I", self.d, o)
            if ptyp == 2:  # PT_DYNAMIC
                doff = struct.unpack_from("<I" if not self.is64 else "<Q",
                                          self.d, o + 4 if not self.is64 else o + 8)[0]
                out: dict[int, int] = {}
                j = 0
                while True:
                    tag, val = struct.unpack_from(self.dynfmt, self.d, doff + j * self.dynsz)
                    if tag == 0:
                        return out
                    out[tag] = val & 0xFFFFFFFFFFFFFFFF
                    j += 1
        raise ValueError("no PT_DYNAMIC segment")

    def sections(self):
        for i in range(self.shnum):
            o = self.shoff + i * self.shentsz
            if self.is64:
                (name, typ, _, _, off, size) = struct.unpack_from("<IIQQQQ", self.d, o)[:6]
            else:
                (name, typ, _, _, off, size) = struct.unpack_from("<IIIIII", self.d, o)[:6]
            yield typ, off, size


def read_cstr(data: bytes, off: int) -> bytes:
    end = data.index(b"\x00", off)
    return data[off:end]


def patch(path: str, check_only: bool = False) -> None:
    with open(path, "rb") as handle:
        original = handle.read()
    data = bytearray(original)
    elf = Elf(data)
    dyn = elf.dynamic()
    hash_off = elf.v2o(dyn[DT_HASH])
    strtab_off = elf.v2o(dyn[DT_STRTAB])
    symtab_off = elf.v2o(dyn[DT_SYMTAB])
    strsz = dyn[DT_STRSZ]
    syment = dyn[DT_SYMENT]
    gnuhash_off = elf.v2o(dyn[DT_GNUHASH])

    nbucket, nchain = struct.unpack_from("<II", data, hash_off)
    names: list[bytes] = []
    for i in range(nchain):
        (st_name,) = struct.unpack_from("<I", data, symtab_off + i * syment)
        names.append(read_cstr(data, strtab_off + st_name))

    old_idx = [i for i, n in enumerate(names) if n == OLD_NAME]
    new_idx = [i for i, n in enumerate(names) if n == NEW_NAME]
    if check_only:
        if old_idx:
            raise SystemExit(f"{path}: old JNI name still present")
        if len(new_idx) != 1:
            raise SystemExit(f"{path}: expected exactly 1 new JNI symbol, found {len(new_idx)}")
    else:
        if len(old_idx) != 1 or new_idx:
            raise SystemExit(
                f"{path}: expected exactly 1 old JNI symbol and 0 new "
                f"(found {len(old_idx)} old, {len(new_idx)} new)"
            )
    if not check_only:
        # 1. patch .dynstr in place (shorter name + NUL padding keeps every
        #    later string offset unchanged).
        (st_name,) = struct.unpack_from("<I", data, symtab_off + old_idx[0] * syment)
        at = strtab_off + st_name
        assert data[at : at + len(OLD_NAME)] == OLD_NAME
        data[at : at + len(OLD_NAME) + 1] = NEW_NAME + b"\x00" * (len(OLD_NAME) - len(NEW_NAME) + 1)
        names[old_idx[0]] = NEW_NAME

        # 2. rebuild .hash (SysV).
        buckets = [0] * nbucket
        chains = [0] * nchain
        for i in range(1, nchain):
            h = elf_hash(names[i]) % nbucket
            chains[i] = buckets[h]
            buckets[h] = i
        struct.pack_into(f"<{nbucket}I", data, hash_off + 8, *buckets)
        struct.pack_into(f"<{nchain}I", data, hash_off + 8 + 4 * nbucket, *chains)

        # 3. rebuild .gnu.hash.
        (nb, symoffset, bloom_size, bloom_shift) = struct.unpack_from("<IIII", data, gnuhash_off)
        word = 8 if elf.is64 else 4
        wfmt = "<Q" if elf.is64 else "<I"
        wbits = word * 8
        bloom_off = gnuhash_off + 16
        buckets_off = bloom_off + bloom_size * word
        chains_off = buckets_off + nb * 4
        hashes = [gnu_hash(n) for n in names]
        bloom = [0] * bloom_size
        gbuckets = [0] * nb
        gchains = [0] * (nchain - symoffset)
        by_bucket: dict[int, list[int]] = {}
        for i in range(symoffset, nchain):
            h = hashes[i]
            bloom[(h // wbits) % bloom_size] |= (1 << (h % wbits)) | (1 << ((h >> bloom_shift) % wbits))
            by_bucket.setdefault(h % nb, []).append(i)
        for b, members in by_bucket.items():
            gbuckets[b] = members[0]
            for k, i in enumerate(members):
                gchains[i - symoffset] = (hashes[i] & ~1) | (1 if k == len(members) - 1 else 0)
        struct.pack_into(f"<{bloom_size}{wfmt[1]}", data, bloom_off, *bloom)
        struct.pack_into(f"<{nb}I", data, buckets_off, *gbuckets)
        struct.pack_into(f"<{len(gchains)}I", data, chains_off, *gchains)

        # 4. patch static string tables too (debug info only, same padding).
        for typ, off, size in elf.sections():
            if typ != 3:  # SHT_STRTAB
                continue
            if off == strtab_off and size == strsz:
                continue  # already handled .dynstr
            seg = data[off : off + size]
            at = seg.find(OLD_NAME)
            if at >= 0:
                data[off + at : off + at + len(OLD_NAME) + 1] = (
                    NEW_NAME + b"\x00" * (len(OLD_NAME) - len(NEW_NAME) + 1)
                )
                print(f"  patched static strtab at file offset 0x{off + at:x}")

        if len(data) != len(original):
            raise SystemExit("size changed, refusing to write")
        with open(path, "wb") as handle:
            handle.write(data)
        # re-parse what was written
        elf = Elf(bytearray(data))
        dyn = elf.dynamic()
        hash_off = elf.v2o(dyn[DT_HASH])
        strtab_off = elf.v2o(dyn[DT_STRTAB])
        symtab_off = elf.v2o(dyn[DT_SYMTAB])
        gnuhash_off = elf.v2o(dyn[DT_GNUHASH])
        nbucket, nchain = struct.unpack_from("<II", data, hash_off)
        names = []
        for i in range(nchain):
            (st_name,) = struct.unpack_from("<I", data, symtab_off + i * syment)
            names.append(read_cstr(data, strtab_off + st_name))

    # 5. verify: simulate the dynamic linker's lookup in both tables.
    buckets = list(struct.unpack_from(f"<{nbucket}I", data, hash_off + 8))
    chains = list(struct.unpack_from(f"<{nchain}I", data, hash_off + 8 + 4 * nbucket))

    def lookup_sysv(target: bytes) -> int:
        i = buckets[elf_hash(target) % nbucket]
        while i:
            if names[i] == target:
                return i
            i = chains[i]
        return 0

    (nb, symoffset, bloom_size, bloom_shift) = struct.unpack_from("<IIII", data, gnuhash_off)
    word = 8 if elf.is64 else 4
    wfmt = "<Q" if elf.is64 else "<I"
    bloom_off = gnuhash_off + 16
    buckets_off = bloom_off + bloom_size * word
    chains_off = buckets_off + nb * 4
    gbuckets = list(struct.unpack_from(f"<{nb}I", data, buckets_off))
    gchains = list(struct.unpack_from(f"<{nchain - symoffset}I", data, chains_off))
    bloom = list(struct.unpack_from(f"<{bloom_size}{wfmt[1]}", data, bloom_off))

    def lookup_gnu(target: bytes) -> int:
        h = gnu_hash(target)
        wbits = word * 8
        w = bloom[(h // wbits) % bloom_size]
        if not (w >> (h % wbits)) & 1 and not (w >> ((h >> bloom_shift) % wbits)) & 1:
            return -1  # definitely absent
        i = gbuckets[h % nb]
        if i < symoffset:
            return -1
        while True:
            hi = gchains[i - symoffset]
            if (hi & ~1) == (h & ~1) and names[i] == target:
                return i
            if hi & 1:
                return -1
            i += 1

    for i, n in enumerate(names):
        if i == 0:
            continue
        if lookup_sysv(n) != i:
            raise SystemExit(f"{path}: SysV lookup of {n!r} failed")
        if lookup_gnu(n) != i:
            raise SystemExit(f"{path}: GNU lookup of {n!r} failed")
    if lookup_sysv(NEW_NAME) <= 0 or lookup_gnu(NEW_NAME) < 0:
        raise SystemExit(f"{path}: new JNI name does not resolve")
    print(f"  {path}: {nchain} symbols resolve in .hash and .gnu.hash; {NEW_NAME.decode()} OK")


def main() -> int:
    check_only = "--check" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--check"]
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    files = args or [
        os.path.join(root, "lib", "arm64-v8a", "libbtcore.so"),
        os.path.join(root, "lib", "armeabi-v7a", "libbtcore.so"),
    ]
    for path in files:
        patch(path, check_only)
    print("RESULT:", "CHECK PASSED" if check_only else "PATCHED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
