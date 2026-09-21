# dist/ - prebuilt JVHD.apk

`JVHD.apk` in this folder is the APK assembled from this repository's
apktool project (`smali/`, `smali_classes2/`, `smali_classes3/`, `res/`,
`assets/`, `lib/`) by the repository's own one-command pipeline,
`scripts/build-apk.sh` - the exact script the `Build JVHD APK` workflow runs
(apktool Smali assembly + aapt2 resource link, `scripts/zipalign.py`,
apksigner, then `scripts/verify_apk.py` + `scripts/verify_dex_links.py` +
`scripts/verify_original_manifest.py`):

```
smali/ + smali_classes2/ + smali_classes3/
                          -> apktool b --use-aapt2 -> classes.dex + classes2.dex + classes3.dex
res/ + AndroidManifest.xml + assets/
                          -> apktool's bundled aapt2 (framework from the jar)
                          -> zipalign -f -p 4 (scripts/zipalign.py)
                          -> apksigner (keystore/jvhd-debug.keystore, v1+v2+v3)
                          -> verify_apk.py PASSED (0 failures)
                          -> verify_dex_links.py PASSED (every class/type/member reference resolves)
                          -> verify_original_manifest.py PASSED
```

**This build fixes the "app closes itself immediately after launch" bug.**
The previous dist copy (`037a167f...`) shipped `classes.dex` + `classes2.dex`
but no Kotlin runtime: the app's own classes (written in Kotlin, built with
Kotlin 1.8.22) referenced `kotlin/jvm/internal/Intrinsics`, `kotlin/Unit`,
`kotlin/jvm/functions/Function1`, `kotlin/UShort`, ... which were simply not
in the APK, so the process died with a `NoClassDefFoundError` during
`MainActivity.onCreate` before the first frame. `scripts/verify_dex_links.py`
run against the old artifact reported 352 dangling references; run against
this artifact it reports `RESULT: PASSED`.

Two fixes went into this build:

1. **Kotlin standard library restored** - 105 classes copied from an
   authentic `kotlin-stdlib-1.8.22` tree into `smali_classes3/`
   (`scripts/restore_kotlin_runtime.py`, provenance list in
   `smali_classes3/RESTORED-CLASSES.txt`), so the app's own Kotlin code can
   link.
2. **`com.JVHD.vip.RawResponse$1` restored** - an anonymous subclass used by
   the DoH/raw-HTTP layer (`smali_classes2/com/JVHD/vip/RawResponse.smali`)
   that no public source contains; re-created as a behaviour-transparent
   subclass of `RawResponse` with the exact constructor the call site uses.

`MainActivity.onCreate` also installs `com.JVHD.vip.CrashLogger` (an
`UncaughtExceptionHandler`) so that any future uncaught exception - including
ones raised on the JavaScript bridge thread - is written with its full stack
trace to logcat (`JVHD-CRASH`) and to `jvhd-crash.txt` next to the app's
external files, instead of vanishing silently.

| | |
| --- | --- |
| File | `dist/JVHD.apk` |
| SHA-256 | `432566fb5caf5013832c2eda53670e64a263fc2d0d435bb8ff0ff8e62ed92ee6` |
| Size | 975,782 bytes |
| applicationId | `com.JVHD.vip` |
| Launcher activity | `com.JVHD.vip.MainActivity` |
| minSdk / targetSdk | 21 / 33 (landscape) |
| App label | `JVHD Vip2` (`application-label` in the compiled manifest) |
| Signature | APK Signature Scheme v1 + v2 + v3 (debug key `jvhddebug`) |
| Signer cert SHA-256 | `29c7c79c2e6ee788882fbf8f5dfcc095f00f569907223d9b9d0fc3b7efdab020` |
| DEX files | `classes.dex` (838) + `classes2.dex` (10) + `classes3.dex` (116) = 964 classes |
| Built from source commit | `65ca78ba` + the `dist/` refresh commit (see `build-info.txt`) |

The signing key is unchanged, so this APK installs over the previous one
(`adb install -r dist/JVHD.apk`) and `apksigner` reports the same signer
certificate.

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
