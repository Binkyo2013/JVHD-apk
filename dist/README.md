# dist/ - prebuilt JVHD.apk

`JVHD.apk` in this folder is the APK assembled from this repository's
apktool project (`smali/`, `smali_classes2/`, `res/`, `assets/`, `lib/`)
with the same tools and versions the `Build JVHD APK` workflow uses
(apktool 2.9.3 dex assembly, aapt2 2.19 resource link, `scripts/zipalign.py`,
apksigner 0.9, `scripts/verify_apk.py` +
`scripts/verify_original_manifest.py`):

```
smali/ + smali_classes2/  -> apktool 2.9.3 Smali  -> classes.dex + classes2.dex
res/ + AndroidManifest.xml + assets/
                          -> aapt2 2.19 link (-I minimal android framework
                             built locally, IDs pinned from the previous build)
package (arsc + lib/*.so STORED, rest DEFLATED)
                          -> scripts/zipalign.py -f -p 4
                          -> apksigner 0.9 (keystore/jvhd-debug.keystore)
                          -> scripts/verify_apk.py + scripts/verify_original_manifest.py
```

`scripts/build-apk.sh` documents the one-command CI equivalent of this
pipeline; the exact commands used for this file are recorded in
`build-info.txt` (the workflow itself currently cannot run - see below).

| | |
| --- | --- |
| File | `dist/JVHD.apk` |
| SHA-256 | `46660c1927c1ccaba2fdbf02222919d80ad5bcca7575f8dabae87119e783d2bf` |
| Size | 904,989 bytes |
| applicationId | `com.JVHD.vip` |
| Launcher activity | `com.JVHD.vip.MainActivity` |
| minSdk / targetSdk | 21 / 33 (landscape) |
| App label | `JVHD Vip2` (`application-label` in the compiled manifest) |
| Signature | APK Signature Scheme v1 + v2 + v3 (debug key `jvhddebug`) |
| Source commit | `2289919fdb909fadc511f7362af43c4f8882f75e` |

`build-info.txt` holds the toolchain versions and the full verification output
of this exact file.

Download (private repository, needs to be logged in as a collaborator):

```
https://github.com/Binkyo2013/JVHD-apk/raw/main/dist/JVHD.apk
```

Install:

```bash
adb install -r dist/JVHD.apk
```

This folder is a convenience copy so the APK is downloadable even while the
GitHub Actions job is rejected by GitHub's billing gate
("The job was not started because recent account payments have failed or your
spending limit needs to be increased"). A clean rebuild with the commands in
`build-info.txt` produces a byte-identical file (same SHA-256) - only the
outer container hash differs from the previous release because the package
name changed. Once Actions runs again, `dist/JVHD.apk` can be deleted again:
*Actions -> Build JVHD APK -> Run workflow -> main* publishes the freshly
built APK as the `JVHD-apk-debug` artifact.
