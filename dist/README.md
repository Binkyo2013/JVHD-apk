# dist/ - prebuilt JVHD.apk

`JVHD.apk` in this folder is the APK assembled from this repository by
`scripts/build-apk.sh` (the same pipeline the `Build JVHD APK` workflow runs):

```
apktool project (smali/, smali_classes2/, res/, assets/, lib/)
   -> apktool 2.9.3 assembly   ->  classes.dex + classes2.dex
   -> zipalign -f -p 4
   -> apksigner (keystore/jvhd-debug.keystore)
   -> scripts/verify_apk.py + scripts/verify_original_manifest.py
```

| | |
| --- | --- |
| File | `dist/JVHD.apk` |
| SHA-256 | `92cb785134040d97047af492ee033813665cda9cae1d625ca103db45d5baecf3` |
| Size | 910,644 bytes |
| applicationId | `com.bintv.launcher` |
| Launcher activity | `com.bintv.launcher.MainActivity` |
| minSdk / targetSdk | 21 / 33 (landscape) |
| App label | `JVHD Vip2` (`application-label` in the compiled manifest) |
| Signature | APK Signature Scheme v1 + v2 + v3 (debug key `jvhddebug`) |
| Source commit | `855548716cf73df3199767599de5131a68aaa2e3` |

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
spending limit needs to be increased"). A clean clone of `main` rebuilt through
`scripts/build-apk.sh` produces an APK with the same 32 payload entries,
byte for byte - only the outer container hash differs (zip timestamps and
signature material), see `build-info.txt`. Once Actions runs
again, `dist/JVHD.apk` can be deleted again: *Actions -> Build JVHD APK -> Run
workflow -> main* publishes the freshly built APK as the `JVHD-apk-debug`
artifact.
