# JVHD-apk

Android TV launcher (`com.bintv.launcher`) packaged as `JVHD.apk`.

The repository is the **decompiled apktool project** of the app, not an Android
Studio project. The build therefore assembles the checked-in Smali sources into
real DEX files instead of recompiling Java/Kotlin:

```
AndroidManifest.xml + res/ + assets/ + lib/
smali/          -> classes.dex
smali_classes2/ -> classes2.dex
        |
        v
   apktool 2.10.0 "b"   (Smali assembly + aapt2 resource link)
        |
        v
   build/outputs/apk/JVHD-unsigned.apk
        |
        v
   zipalign -p 4  ->  apksigner (debug keystore)  ->  build/outputs/apk/JVHD.apk
        |
        v
   scripts/verify_apk.py  (DEX class parsing, sha256, alignment, manifest)
```

## Build

Requirements: JDK 17, `python3`, and either the Android SDK build-tools
(`zipalign`, `apksigner`, `aapt2`) or the built-in fallbacks. apktool 2.10.0 is
downloaded automatically from GitHub releases and its version is checked.

```bash
# single entry point (same pipeline Gradle and CI use)
bash scripts/build-apk.sh

# equivalent
gradle assembleDebug
```

Environment overrides: `JAVA_HOME`, `ANDROID_HOME`, `APKTOOL_JAR`,
`APKTOOL_VERSION`, `APKTOOL_SHA256`, `ZIPALIGN`, `APKSIGNER_JAR`, `KEYSTORE`,
`OUT_APK`.

Output: **`build/outputs/apk/JVHD.apk`** (signed, zipaligned) plus
`build/outputs/apk/JVHD.apk.sha256` and `build/badging.txt`.

### GitHub Actions

Workflow `.github/workflows/build-apk.yml` (`Build JVHD APK`) runs on
`workflow_dispatch`, on pushes to `main` / `arena/**` and on pull requests. It
installs JDK 17, Android platform 33, build-tools 34.0.0, downloads apktool
2.10.0, runs the pipeline above, re-verifies the artifact with the SDK tools and
uploads the artifact **`JVHD-apk-debug`**.

To build manually: *GitHub -> Actions -> Build JVHD APK -> Run workflow ->
branch `main` -> Run workflow*. When the run finishes, download the
`JVHD-apk-debug` artifact and unzip it (the download is a zip containing
`JVHD.apk`).

## Install

```bash
adb install -r JVHD.apk            # Android TV / TV box over ADB
```
Or copy `JVHD.apk` to a USB stick and install it with a file manager on the TV
(enable "Unknown sources" for the file manager first).

## What the build guarantees

| Item | Value |
| --- | --- |
| applicationId | `com.bintv.launcher` |
| launcher activity | `com.bintv.launcher.MainActivity` (LAUNCHER + LEANBACK_LAUNCHER) |
| minSdk / targetSdk | 21 / 33 |
| orientation | landscape |
| DEX | `classes.dex` (from `smali/`), `classes2.dex` (from `smali_classes2/`) |

Verified classes in the DEX files: `com.bintv.launcher.MainActivity`,
`com.bintv.launcher.TizenBridge`, `com.bintv.launcher.MediaProxyServer`,
`com.bintv.launcher.BtK`.

Native libraries are **never rebuilt or modified**: `lib/arm64-v8a/libbtcore.so`
and `lib/armeabi-v7a/libbtcore.so` are copied byte-for-byte into the APK
(`System.loadLibrary("btcore")` in `TizenBridge.smali` is untouched). The
verifier compares their SHA-256 against the checked-in files.

## Runtime configuration

* JVHD backend: `https://jvhd-server.onrender.com`
  (`POST /auth/start`, `POST /auth/verify`, `POST /auth/bind`, `GET /config`,
  `GET /health`).
* The JVHD menu is server driven: sources are read from `GET /config`,
  `sourceN.name` / `sourceN.url` are rendered in numeric order, incomplete
  sources are skipped, `parse_mode: "extract_stream"` and `extractor` are kept.
* `MOVIE_CONFIG_URL` (the separate "Phim" module) is untouched.

## Signing

`keystore/jvhd-debug.keystore` (alias `jvhddebug`, store/key password
`android`) is a throw-away debug key committed so that every build - locally and
on CI - is signed by the same certificate. Replace it (or pass `KEYSTORE`) when
you need a release keystore; no production secret is stored in this repository.
