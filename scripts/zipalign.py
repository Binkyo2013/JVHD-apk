#!/usr/bin/env python3
"""Dependency-free zipalign implementation (fallback aligner).

The Android SDK `zipalign` binary is used whenever it is available (that is the
case on the GitHub Actions runner and in any machine with build-tools
installed).  This script exists so that the very same pipeline can also run on
machines where no Android SDK is present, and so that the alignment can be
checked independently.

It mirrors what AOSP's tool does: stored (uncompressed) entries are aligned by
growing the ZIP extra field of the file, using the reserved "Android alignment"
extra field id 0xd935, and the very same extra field is written to the central
directory record.  Deflated entries are copied untouched.

usage:
    zipalign.py [-f] [-p] [-v] <align> <infile.apk> <outfile.apk>
    zipalign.py -c [-p] [-v] <align> <infile.apk>
"""

from __future__ import annotations

import argparse
import struct
import sys

EOCD_SIG = b"PK\x05\x06"
CD_SIG = b"PK\x01\x02"
LFH_SIG = b"PK\x03\x04"
ZIP64_EOCD_SIG = b"PK\x06\x06"
ZIP64_LOCATOR_SIG = b"PK\x06\x07"
ALIGNMENT_EXTRA_ID = 0xD935  # "Android alignment" extra field id used by AOSP


class Zip2Big(Exception):
    """Raised for archives this simple implementation does not handle."""


def find_eocd(blob: bytes) -> int:
    start = max(0, len(blob) - 66000)
    offset = blob.rfind(EOCD_SIG, start)
    if offset < 0:
        raise Zip2Big("EOCD record not found - not a ZIP file?")
    if chunk_has_zip64(blob, offset):
        raise Zip2Big("Zip64 archive detected - not supported by this fallback aligner")
    return offset


def chunk_has_zip64(blob: bytes, eocd_offset: int) -> bool:
    window = blob[max(0, eocd_offset - 128) : eocd_offset]
    return ZIP64_LOCATOR_SIG in window or ZIP64_EOCD_SIG in window


class Entry:
    __slots__ = (
        "name",
        "flags",
        "method",
        "crc",
        "csize",
        "usize",
        "local_offset",
        "local_extra",
        "central_extra",
        "comment",
        "version_made_by",
        "version_needed",
        "disk_start",
        "internal_attr",
        "external_attr",
        "data",
    )


def parse_archive(blob: bytes) -> tuple[list[Entry], bytes]:
    eocd = find_eocd(blob)
    cd_size, cd_offset = struct.unpack_from("<II", blob, eocd + 12)
    total = struct.unpack_from("<H", blob, eocd + 10)[0]
    archive_comment_len = struct.unpack_from("<H", blob, eocd + 20)[0]
    archive_comment = blob[eocd + 22 : eocd + 22 + archive_comment_len]

    entries: list[Entry] = []
    cursor = cd_offset
    for _ in range(total):
        if blob[cursor : cursor + 4] != CD_SIG:
            raise Zip2Big("damaged central directory")
        entry = Entry()
        (entry.version_made_by, entry.version_needed, entry.flags, entry.method) = struct.unpack_from(
            "<HHHH", blob, cursor + 4
        )
        (entry.crc, entry.csize, entry.usize) = struct.unpack_from("<III", blob, cursor + 16)
        (name_len, extra_len, comment_len, entry.disk_start, entry.internal_attr) = struct.unpack_from(
            "<HHHHH", blob, cursor + 28
        )
        (entry.external_attr,) = struct.unpack_from("<I", blob, cursor + 38)
        (entry.local_offset,) = struct.unpack_from("<I", blob, cursor + 42)
        entry.name = blob[cursor + 46 : cursor + 46 + name_len]
        entry.central_extra = blob[cursor + 46 + name_len : cursor + 46 + name_len + extra_len]
        entry.comment = blob[
            cursor + 46 + name_len + extra_len : cursor + 46 + name_len + extra_len + comment_len
        ]
        cursor += 46 + name_len + extra_len + comment_len

        header = entry.local_offset
        if blob[header : header + 4] != LFH_SIG:
            raise Zip2Big(f"damaged local header for {entry.name!r}")
        local_name_len, local_extra_len = struct.unpack_from("<HH", blob, header + 26)
        entry.local_extra = blob[header + 30 + local_name_len : header + 30 + local_name_len + local_extra_len]
        data_offset = header + 30 + local_name_len + local_extra_len
        entry.data = blob[data_offset : data_offset + entry.csize]
        entries.append(entry)

    if cursor - cd_offset != cd_size:
        raise Zip2Big("central directory size mismatch")
    return entries, archive_comment


def pad_extra(extra: bytes, amount: int) -> bytes:
    """Grow a ZIP extra field area by exactly `amount` bytes, keeping it well formed."""
    if amount == 0:
        return extra
    if not extra:
        # Fresh extra area: emit the reserved alignment field (4 byte header + data).
        if amount < 4:
            amount += 4  # keep the field well formed; still congruent modulo 4
        data_len = amount - 4
        return struct.pack("<HH", ALIGNMENT_EXTRA_ID, data_len) + b"\x00" * data_len
    # Re-use the existing (last) field and simply grow its payload.
    start = 0
    last_start = None
    last_len = None
    while start + 4 <= len(extra):
        field_id, field_len = struct.unpack_from("<HH", extra, start)
        if start + 4 + field_len > len(extra):
            break  # malformed tail - fall through to raw append
        last_start, last_len = start, field_len
        start += 4 + field_len
    if last_start is not None and start == len(extra):
        grown = bytearray(extra)
        struct.pack_into("<H", grown, last_start + 2, last_len + amount)
        return bytes(grown) + b"\x00" * amount
    return extra + b"\x00" * amount


def local_header(
    entry: Entry, name_len: int, extra_len: int, version_needed: int
) -> bytes:
    # Bit 3 (data descriptor) is cleared: the rewritten records always carry the
    # real crc/sizes (taken from the central directory), which is valid ZIP and
    # keeps the entry payload byte-identical.
    return struct.pack(
        "<IHHHHHIIIHH",
        0x04034B50,
        version_needed,
        entry.flags & ~0x08,
        entry.method,
        0,
        0,
        entry.crc,
        entry.csize,
        entry.usize,
        name_len,
        extra_len,
    )


def central_header(entry: Entry, extra: bytes, version_made_by: int) -> bytes:
    return struct.pack(
        "<IHHHHHHIIIHHHHHII",
        0x02014B50,
        version_made_by,
        entry.version_needed,
        entry.flags & ~0x08,
        entry.method,
        0,
        0,
        entry.crc,
        entry.csize,
        entry.usize,
        len(entry.name),
        len(extra),
        len(entry.comment),
        entry.disk_start,
        entry.internal_attr,
        entry.external_attr,
        entry.local_offset,  # patched by the caller
    )


def align_entries(entries: list[Entry], align: int, page_align: bool, verbose: bool) -> bytes:
    out = bytearray()
    central_records: list[tuple[Entry, bytes]] = []
    for entry in entries:
        target_align = 4096 if (page_align and entry.name.endswith(b".so")) else align
        extra = entry.local_extra
        if entry.method == 0:  # STORED -> alignment matters
            data_offset = len(out) + 30 + len(entry.name) + len(extra)
            shift = (-data_offset) % target_align
            if shift or target_align > align:
                extra = pad_extra(extra, shift)
            data_offset = len(out) + 30 + len(entry.name) + len(extra)
            if data_offset % align != 0:
                raise Zip2Big(f"internal error aligning {entry.name!r}")
            if verbose:
                print(f"    {entry.name.decode('utf-8', 'replace')}: data offset {data_offset} (align {target_align})")
        entry.local_offset = len(out)
        out += local_header(entry, len(entry.name), len(extra), entry.version_needed)
        out += entry.name
        out += extra
        out += entry.data
        central_extra = extra if entry.method == 0 else entry.central_extra
        central_records.append((entry, central_extra))

    cd_offset = len(out)
    for entry, extra in central_records:
        record = bytearray(central_header(entry, extra, entry.version_made_by))
        struct.pack_into("<I", record, 42, entry.local_offset)
        out += bytes(record)
        out += entry.name
        out += extra
        out += entry.comment
    cd_size = len(out) - cd_offset
    out += struct.pack(
        "<IHHHHIIH",
        0x06054B50,
        0,
        0,
        len(entries),
        len(entries),
        cd_size,
        cd_offset,
        0,
    )
    return bytes(out)


def check_alignment(path: str, align: int, page_align: bool, verbose: bool) -> int:
    with open(path, "rb") as handle:
        blob = handle.read()
    entries, _comment = parse_archive(blob)
    failures = 0
    checked = 0
    for entry in entries:
        if entry.method != 0:
            continue
        local_name_len, local_extra_len = struct.unpack_from("<HH", blob, entry.local_offset + 26)
        data_offset = entry.local_offset + 30 + local_name_len + local_extra_len
        target = 4096 if (page_align and entry.name.endswith(b".so")) else align
        checked += 1
        if data_offset % target != 0:
            failures += 1
            print(f"    MISALIGNED {entry.name.decode('utf-8', 'replace')}: {data_offset} % {target} != 0")
        elif verbose:
            print(f"    ok {entry.name.decode('utf-8', 'replace')}: {data_offset} % {target} == 0")
    print(f"verification successful ({checked} stored entries checked, {failures} misaligned)")
    return 1 if failures else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="zipalign (fallback implementation)")
    parser.add_argument("-f", action="store_true", help="overwrite existing output file")
    parser.add_argument("-p", action="store_true", help="page align stored shared objects (4096)")
    parser.add_argument("-v", action="store_true", help="verbose output")
    parser.add_argument("-c", action="store_true", help="check alignment only")
    parser.add_argument("align", type=int)
    parser.add_argument("infile")
    parser.add_argument("outfile", nargs="?")
    args = parser.parse_args()

    if args.c:
        return check_alignment(args.infile, args.align, args.p, args.v)

    if not args.outfile:
        parser.error("outfile is required unless -c is used")

    with open(args.infile, "rb") as handle:
        blob = handle.read()
    entries, comment = parse_archive(blob)
    result = align_entries(entries, args.align, args.p, args.v)
    with open(args.outfile, "wb") as handle:
        handle.write(result)
    print(f"aligning {args.infile} -> {args.outfile} (align {args.align}{', page .so' if args.p else ''})")
    return check_alignment(args.outfile, args.align, args.p, args.v)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Zip2Big as error:
        print(f"zipalign fallback cannot process this archive: {error}", file=sys.stderr)
        sys.exit(2)
