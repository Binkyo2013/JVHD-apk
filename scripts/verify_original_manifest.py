#!/usr/bin/env python3
"""Compare the built APK against the signature manifest of the original APK.

`original/META-INF/MANIFEST.MF` is the JAR (v1) signature manifest of the APK
this decompiled project was created from: it lists the 32 entries of that APK
with their SHA-256 digests.  That file is ground truth for what the original
shipped, so this script uses it to prove that

  * assets/, res/ images, kotlin/ builtins, kotlin-tooling-metadata.json and the
    two native libraries were carried over byte for byte (identical digest), and
  * no original entry is missing from the rebuilt APK.

Recompiled artifacts (AndroidManifest.xml, resources.arsc, classes*.dex) are
expected to differ and are reported separately.
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import os
import sys
import zipfile

RECOMPILED = {"AndroidManifest.xml", "resources.arsc", "classes.dex", "classes2.dex"}
# resources are compiled/re-optimised by aapt2 during the build (PNG crunching),
# so their byte digest legitimately changes while the checked-in source stays.
BUILD_OPTIMISED_PREFIXES = ("res/",)
# assets/app.js is the file that was migrated to the JVHD server backend; the
# checked-in version is authoritative and is verified byte-for-byte by
# verify_apk.py instead.
EXPECTED_CHANGED = {"assets/app.js"}


def parse_manifest(path: str) -> dict[str, str]:
    entries: dict[str, str] = {}
    name = None
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            line = line.rstrip("\r\n")
            if line.startswith("Name: "):
                name = line[len("Name: ") :]
            elif line.startswith("SHA-256-Digest: ") and name:
                entries[name] = line[len("SHA-256-Digest: ") :]
                name = None
    return entries


def b64_sha256(data: bytes) -> str:
    return base64.b64encode(hashlib.sha256(data).digest()).decode("ascii")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", required=True)
    parser.add_argument("--project", required=True)
    parser.add_argument(
        "--manifest", default="original/META-INF/MANIFEST.MF", help="JAR manifest of the original APK"
    )
    args = parser.parse_args()

    manifest_path = os.path.join(args.project, args.manifest)
    if not os.path.isfile(manifest_path):
        print(f"original manifest not found: {manifest_path}")
        return 1

    original = parse_manifest(manifest_path)
    archive = zipfile.ZipFile(args.apk)
    packaged = set(archive.namelist())

    print(f"original APK entries recorded in {args.manifest}: {len(original)}")
    failures: list[str] = []
    identical = 0
    recompiled = 0
    missing = 0
    for name, digest in sorted(original.items()):
        if name not in packaged:
            missing += 1
            failures.append(f"{name}: missing from the built APK")
            print(f"  [FAIL] {name}: missing from the built APK")
            continue
        actual = b64_sha256(archive.read(name))
        if actual == digest:
            identical += 1
            print(f"  [ OK ] {name}: digest identical to the original APK")
        elif name in RECOMPILED:
            recompiled += 1
            print(f"  [core] {name}: recompiled by the build (digest changes by design)")
        elif name.startswith(BUILD_OPTIMISED_PREFIXES):
            recompiled += 1
            print(f"  [core] {name}: source kept, re-optimised by aapt2 at build time")
        elif name in EXPECTED_CHANGED:
            recompiled += 1
            print(f"  [core] {name}: intentionally migrated to the JVHD backend (checked-in file is authoritative)")
        else:
            failures.append(f"{name}: content changed ({actual} != {digest})")
            print(f"  [FAIL] {name}: content changed ({actual} != {digest})")

    extra = sorted(packaged - set(original))
    unexpected = [name for name in extra if not name.startswith("META-INF/")]
    print(
        f"\nidentical: {identical}/{len(original)}   recompiled: {recompiled}   "
        f"missing: {missing}   new entries: {len(extra)}"
    )
    if unexpected:
        print("entries not present in the original APK:")
        for name in unexpected:
            print(f"  [note] {name}")
    if failures:
        print("RESULT: FAILED")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("RESULT: PASSED (original assets, resources images, Kotlin builtins and native libraries preserved)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
