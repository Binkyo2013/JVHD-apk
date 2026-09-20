# dist/ - prebuilt JVHD.apk

`JVHD.apk` in this folder is the APK assembled from this repository by
`scripts/build-apk.sh` (the same pipeline the `Build JVHD APK` workflow runs):

```
apktool project (smali/, smali_classes2/, res/, assets/, lib/)
   -> apktool 2.10.0 assembly  ->  classes.dex + classes2.dex
   -> zipalign -f -p 4
   -> apksigner (keystore/jvhd-debug.keystore)
   -> scripts/verify_apk.py + scripts/verify_original_manifest.py
```

| | |
| --- | --- |
| File | `dist/JVHD.apk` |
| SHA-256 | `8739ef1743b8bdc517229704d5452c7dd7f2490ebdf1276d9de97e1dcd24f643` |
| Size | 899,647 bytes |
| applicationId | `com.bintv.launcher` |
| Launcher activity | `com.bintv.launcher.MainActivity` |
| minSdk / targetSdk | 21 / 33 (landscape) |
| Signature | APK Signature Scheme v1 + v2 + v3 (debug key `jvhddebug`) |
| Source commit | `9757d479f0f86b0db1e472530b4f8e455fee7e5b` |

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
GitHub Actions job is blocked on the account billing issue. Once Actions runs
again, `dist/JVHD.apk` can be deleted again: *Actions -> Build JVHD APK -> Run
workflow -> main* publishes the freshly built APK as the `JVHD-apk-debug`
artifact.
