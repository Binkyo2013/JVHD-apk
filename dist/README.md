# dist/ - prebuilt JVHD.apk

`JVHD.apk` in this folder is the APK assembled from this repository's
apktool project (`smali/`, `smali_classes2/`, `res/`, `assets/`, `lib/`)
by the repository's own one-command pipeline, `scripts/build-apk.sh` - the
exact script the `Build JVHD APK` workflow runs (apktool 2.9.3 Smali
assembly + aapt2 2.19 resource link, `scripts/zipalign.py`, apksigner 0.9,
then `scripts/verify_apk.py` + `scripts/verify_original_manifest.py`):

```
smali/ + smali_classes2/  -> apktool 2.9.3 b --use-aapt2  -> classes.dex + classes2.dex
res/ + AndroidManifest.xml + assets/
                          -> apktool's bundled aapt2 2.19 (framework from the jar)
                          -> zipalign -f -p 4 (scripts/zipalign.py)
                          -> apksigner 0.9 (keystore/jvhd-debug.keystore, v1+v2+v3)
                          -> verify_apk.py PASSED (0 failures)
                          -> verify_original_manifest.py PASSED
```

This build includes the `LAYER_TYPE_SOFTWARE` WebView fix in
`MainActivity.smali` (commit `c6f8caf`, "Add WebView software rendering to
prevent crashes on emulators/TVs"); the previous dist copy (SHA-256
`46660c19...`, commit `2289919`) predates that fix.

| | |
| --- | --- |
| File | `dist/JVHD.apk` |
| SHA-256 | `037a167f0564149e98ecae37539c62f819add4d52de85ef81ccbdd7c8f0715a5` |
| Size | 914,394 bytes |
| applicationId | `com.JVHD.vip` |
| Launcher activity | `com.JVHD.vip.MainActivity` |
| minSdk / targetSdk | 21 / 33 (landscape) |
| App label | `JVHD Vip2` (`application-label` in the compiled manifest) |
| Signature | APK Signature Scheme v1 + v2 + v3 (debug key `jvhddebug`) |
| Signer cert SHA-256 | `29c7c79c2e6ee788882fbf8f5dfcc095f00f569907223d9b9d0fc3b7efdab020` |
| Built from source commit | `c6f8caf6f8982a9656373a3a9dbff55d3d07745c` (main) |

`build-info.txt` holds the toolchain versions and the verification output
of this exact file.

Download (private repository, needs to be logged in as a collaborator):

```
https://github.com/Binkyo2013/JVHD-apk/raw/main/dist/JVHD.apk
```

Install:

```bash
adb install -r dist/JVHD.apk
```

This folder is a convenience copy so the APK stays downloadable while the
GitHub Actions job is rejected by GitHub's billing gate ("The job was not
started because recent account payments have failed or your spending limit
needs to be increased"). Once billing is fixed, `Build JVHD APK` produces
the same APK from the same sources and publishes it as the `JVHD-apk-debug`
artifact plus a `build.log` artifact for debugging
(*Actions -> Build JVHD APK -> Run workflow -> main*).
