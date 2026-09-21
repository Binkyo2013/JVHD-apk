#!/usr/bin/env bash
#
# JVHD.apk build pipeline.
#
#   decompiled apktool project (smali/ + smali_classes2/ + smali_classes3/
#   + res/ + assets/ + lib/)
#        -> apktool "b" (Smali assembly, aapt2 resource link)
#        -> build/outputs/apk/JVHD-unsigned.apk
#        -> zipalign -p 4
#        -> apksigner (debug keystore)
#        -> build/outputs/apk/JVHD.apk   (signed, aligned, verified)
#
# The script is the single source of truth for the build; `gradle assembleDebug`
# and the GitHub Actions workflow both call it.
#
# Environment overrides (all optional):
#   JAVA_HOME            JDK 17 installation
#   APKTOOL_JAR          path of an existing apktool jar (otherwise downloaded)
#   APKTOOL_VERSION      apktool version to download          (default 2.10.0)
#   APKTOOL_SHA256       expected sha256 of the downloaded jar (optional)
#   ANDROID_HOME         Android SDK (uses build-tools zipalign/apksigner/aapt2)
#   ZIPALIGN             explicit zipalign binary
#   APKSIGNER_JAR        explicit apksigner jar
#   KEYSTORE / KS_PASS / KS_ALIAS / KEY_PASS   signing material
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
TOOLING_DIR="$BUILD_DIR/tooling"
STAGING_DIR="$BUILD_DIR/apktool-project"
OUT_DIR="$BUILD_DIR/outputs/apk"
UNSIGNED_APK="$OUT_DIR/JVHD-unsigned.apk"
FINAL_APK="${OUT_APK:-$OUT_DIR/JVHD.apk}"
BADGING_TXT="$BUILD_DIR/badging.txt"
SIGN_REPORT="$BUILD_DIR/apksigner-verify.txt"

APKTOOL_VERSION="${APKTOOL_VERSION:-2.10.0}"
APKTOOL_JAR="${APKTOOL_JAR:-$TOOLING_DIR/apktool_${APKTOOL_VERSION}.jar}"
APKTOOL_URL="${APKTOOL_URL:-https://github.com/iBotPeaches/Apktool/releases/download/v${APKTOOL_VERSION}/apktool_${APKTOOL_VERSION}.jar}"
APKTOOL_FALLBACK_URL="${APKTOOL_FALLBACK_URL:-https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_${APKTOOL_VERSION}.jar}"

KEYSTORE="${KEYSTORE:-$ROOT_DIR/keystore/jvhd-debug.keystore}"
KS_PASS="${KS_PASS:-android}"
KS_ALIAS="${KS_ALIAS:-jvhddebug}"
KEY_PASS="${KEY_PASS:-android}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# --------------------------------------------------------------------------- #
# 0. toolchain discovery
# --------------------------------------------------------------------------- #
JAVA_BIN="${JAVA_BIN:-}"
if [ -z "$JAVA_BIN" ] && [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_BIN="$JAVA_HOME/bin/java"
fi
if [ -z "$JAVA_BIN" ]; then
    JAVA_BIN="$(command -v java || true)"
fi
[ -n "$JAVA_BIN" ] || die "java not found - install JDK 17 or set JAVA_HOME"

KEYTOOL_BIN="${KEYTOOL_BIN:-}"
if [ -x "${JAVA_HOME:-/nonexistent}/bin/keytool" ]; then
    KEYTOOL_BIN="$JAVA_HOME/bin/keytool"
else
    KEYTOOL_BIN="$(command -v keytool || true)"
fi

sdk_root() {
    for candidate in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
                     "$HOME/Android/Sdk" "$HOME/android-sdk" \
                     /usr/lib/android-sdk /opt/android-sdk /opt/android/sdk; do
        [ -n "$candidate" ] && [ -d "$candidate" ] && { printf '%s' "$candidate"; return 0; }
    done
    return 1
}

SDK_ROOT="$(sdk_root || true)"
BUILD_TOOLS=""
if [ -n "$SDK_ROOT" ] && [ -d "$SDK_ROOT/build-tools" ]; then
    BUILD_TOOLS="$(find "$SDK_ROOT/build-tools" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort -Vr | head -1)"
    [ -n "$BUILD_TOOLS" ] && BUILD_TOOLS="$SDK_ROOT/build-tools/$BUILD_TOOLS"
fi

log "Toolchain"
echo "  java           : $JAVA_BIN ($("$JAVA_BIN" -version 2>&1 | head -1))"
echo "  android sdk    : ${SDK_ROOT:-<not found>}"
echo "  build-tools    : ${BUILD_TOOLS:-<not found>}"
echo "  project root   : $ROOT_DIR"
echo "  output apk     : $FINAL_APK"

# --------------------------------------------------------------------------- #
# 1. apktool 2.10.0
# --------------------------------------------------------------------------- #
fetch_apktool() {
    [ -f "$APKTOOL_JAR" ] && return 0
    mkdir -p "$(dirname "$APKTOOL_JAR")"
    for url in "$APKTOOL_URL" "$APKTOOL_FALLBACK_URL"; do
        echo "  downloading $url"
        if curl -fsSL --retry 3 --connect-timeout 20 -o "$APKTOOL_JAR.part" "$url" \
           || wget -q -O "$APKTOOL_JAR.part" "$url"; then
            mv "$APKTOOL_JAR.part" "$APKTOOL_JAR"
            return 0
        fi
        rm -f "$APKTOOL_JAR.part"
    done
    return 1
}

log "apktool $APKTOOL_VERSION"
if ! fetch_apktool; then
    die "could not obtain apktool (set APKTOOL_JAR=/path/to/apktool_${APKTOOL_VERSION}.jar)"
fi
if [ -n "${APKTOOL_SHA256:-}" ]; then
    echo "${APKTOOL_SHA256}  ${APKTOOL_JAR}" | sha256sum -c - \
        || die "apktool jar checksum mismatch"
    echo "  sha256 verified against APKTOOL_SHA256"
fi
# A jar is a zip; make sure the file really is the apktool fat jar.
unzip -l "$APKTOOL_JAR" brut/apktool/Main.class >/dev/null \
    || die "$APKTOOL_JAR is not a valid apktool jar"
APKTOOL_REPORTED_VERSION="$("$JAVA_BIN" -jar "$APKTOOL_JAR" --version 2>/dev/null | tail -1 | tr -d '\r')"
echo "  apktool reports: ${APKTOOL_REPORTED_VERSION:-unknown}"

APKTOOL_BUILD_FLAGS=()
if [ "$(printf '%s\n%s\n' "2.12.0" "${APKTOOL_REPORTED_VERSION:-0.0.0}" | sort -V | head -1)" != "2.12.0" ]; then
    # apktool < 2.12 needs the explicit aapt2 switch; 2.12+ always uses aapt2.
    APKTOOL_BUILD_FLAGS+=("--use-aapt2")
fi

# --------------------------------------------------------------------------- #
# 2. stage the decompiled project (never build in the repository tree)
# --------------------------------------------------------------------------- #
log "Staging apktool project"
rm -rf "$STAGING_DIR" "$OUT_DIR"
mkdir -p "$STAGING_DIR" "$OUT_DIR" "$TOOLING_DIR"
for item in AndroidManifest.xml apktool.yml assets res smali smali_classes2 smali_classes3 kotlin lib unknown original; do
    [ -e "$ROOT_DIR/$item" ] || die "required project item missing: $item"
    cp -r "$ROOT_DIR/$item" "$STAGING_DIR/"
    echo "  staged $item"
done

python3 - "$STAGING_DIR/apktool.yml" <<'PY'
import re, sys
path = sys.argv[1]
with open(path, encoding='utf-8') as handle:
    text = handle.read()
# The checked-in AndroidManifest.xml (package com.JVHD.vip) is
# authoritative.  The historical renameManifestPackage entry would overwrite it
# with the old com.bintv.jvhd application id, so it is dropped here as well as in
# the checked-in apktool.yml.
stripped = re.sub(r'(?m)^\s*renameManifestPackage:.*\r?\n', '', text)
if stripped != text:
    with open(path, 'w', encoding='utf-8', newline='') as handle:
        handle.write(stripped)
    print("  dropped historical renameManifestPackage from staged apktool.yml")
else:
    print("  apktool.yml has no renameManifestPackage")
PY

# --------------------------------------------------------------------------- #
# 3. assemble (Smali -> classes.dex / classes2.dex / classes3.dex + resources + manifest)
# --------------------------------------------------------------------------- #
log "Assembling Smali and resources with apktool"
"$JAVA_BIN" -jar "$APKTOOL_JAR" b "$STAGING_DIR" -o "$UNSIGNED_APK" "${APKTOOL_BUILD_FLAGS[@]}"
[ -s "$UNSIGNED_APK" ] || die "apktool produced no APK"
echo "  unsigned apk: $UNSIGNED_APK ($(wc -c < "$UNSIGNED_APK") bytes)"

# --------------------------------------------------------------------------- #
# 4. zipalign
# --------------------------------------------------------------------------- #
ZIPALIGN_BIN="${ZIPALIGN:-}"
if [ -z "$ZIPALIGN_BIN" ] && [ -n "$BUILD_TOOLS" ] && [ -x "$BUILD_TOOLS/zipalign" ]; then
    ZIPALIGN_BIN="$BUILD_TOOLS/zipalign"
fi
if [ -z "$ZIPALIGN_BIN" ]; then
    ZIPALIGN_BIN="$(command -v zipalign || true)"
fi

log "zipalign -f -p 4"
if [ -n "$ZIPALIGN_BIN" ]; then
    echo "  using $ZIPALIGN_BIN"
    "$ZIPALIGN_BIN" -f -p 4 "$UNSIGNED_APK" "$FINAL_APK"
    "$ZIPALIGN_BIN" -c -v -p 4 "$FINAL_APK" | tail -3
else
    warn "no zipalign binary found - using scripts/zipalign.py fallback"
    python3 "$ROOT_DIR/scripts/zipalign.py" -f -p 4 "$UNSIGNED_APK" "$FINAL_APK" -v | tail -5
fi

# --------------------------------------------------------------------------- #
# 5. sign
# --------------------------------------------------------------------------- #
APKSIGNER_BIN="${APKSIGNER:-}"
APKSIGNER_JAR="${APKSIGNER_JAR:-}"
if [ -z "$APKSIGNER_BIN" ] && [ -z "$APKSIGNER_JAR" ] && [ -n "$BUILD_TOOLS" ]; then
    if [ -x "$BUILD_TOOLS/apksigner" ]; then
        APKSIGNER_BIN="$BUILD_TOOLS/apksigner"
    elif [ -f "$BUILD_TOOLS/lib/apksigner.jar" ]; then
        APKSIGNER_JAR="$BUILD_TOOLS/lib/apksigner.jar"
    fi
fi

log "Signing with the debug keystore"
if [ ! -f "$KEYSTORE" ]; then
    [ -n "$KEYTOOL_BIN" ] || die "keystore $KEYSTORE missing and keytool unavailable"
    echo "  generating $KEYSTORE"
    mkdir -p "$(dirname "$KEYSTORE")"
    "$KEYTOOL_BIN" -genkeypair -keystore "$KEYSTORE" -storepass "$KS_PASS" -alias "$KS_ALIAS" \
        -keypass "$KEY_PASS" -dname "CN=JVHD Debug,O=JVHD,C=VN" -keyalg RSA -keysize 2048 \
        -validity 10000 >/dev/null 2>&1
fi
echo "  keystore: $KEYSTORE (alias $KS_ALIAS)"

if [ -n "$APKSIGNER_BIN" ]; then
    echo "  using $APKSIGNER_BIN"
    "$APKSIGNER_BIN" sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" --ks-key-alias "$KS_ALIAS" \
        --key-pass "pass:$KEY_PASS" "$FINAL_APK"
    "$APKSIGNER_BIN" verify --verbose --print-certs "$FINAL_APK" | tee "$SIGN_REPORT"
elif [ -n "$APKSIGNER_JAR" ] || [ -n "${ANDROID_HOME:-}" ]; then
    [ -n "$APKSIGNER_JAR" ] || die "apksigner not found in build-tools"
    echo "  using java -jar $APKSIGNER_JAR"
    # apksigner signs the input in place when --out is not given, which keeps
    # this compatible with old and new build-tools releases.
    "$JAVA_BIN" -jar "$APKSIGNER_JAR" sign --ks "$KEYSTORE" --ks-pass "pass:$KS_PASS" \
        --ks-key-alias "$KS_ALIAS" --key-pass "pass:$KEY_PASS" "$FINAL_APK"
    "$JAVA_BIN" -jar "$APKSIGNER_JAR" verify --verbose --print-certs "$FINAL_APK" | tee "$SIGN_REPORT"
else
    die "no apksigner available (install build-tools or set APKSIGNER_JAR)"
fi

# --------------------------------------------------------------------------- #
# 6. verify
# --------------------------------------------------------------------------- #
log "Verifying that the DEX files link (no dangling class/member references)"
python3 "$ROOT_DIR/scripts/verify_dex_links.py" --apk "$FINAL_APK"

log "Reading compiled manifest with aapt2/aapt"
AAPT2_BIN="${AAPT2:-}"
if [ -z "$AAPT2_BIN" ] && [ -n "$BUILD_TOOLS" ] && [ -x "$BUILD_TOOLS/aapt2" ]; then
    AAPT2_BIN="$BUILD_TOOLS/aapt2"
fi
if [ -z "$AAPT2_BIN" ]; then
    AAPT2_BIN="$(command -v aapt2 || true)"
fi
if [ -z "$AAPT2_BIN" ]; then
    # apktool ships prebuilt aapt/aapt2 binaries inside its own jar.
    mkdir -p "$TOOLING_DIR"
    for candidate in prebuilt/linux/aapt2_64 prebuilt/linux/aapt2; do
        if unzip -p "$APKTOOL_JAR" "$candidate" > "$TOOLING_DIR/aapt2" 2>/dev/null && [ -s "$TOOLING_DIR/aapt2" ]; then
            chmod +x "$TOOLING_DIR/aapt2"
            AAPT2_BIN="$TOOLING_DIR/aapt2"
            break
        fi
    done
fi
[ -n "$AAPT2_BIN" ] || die "no aapt2 binary available for manifest verification"
echo "  using $AAPT2_BIN"
"$AAPT2_BIN" dump badging "$FINAL_APK" > "$BADGING_TXT"
grep -E "^(package|sdkVersion|targetSdkVersion|launchable-activity)" "$BADGING_TXT" | sed 's/^/  /' || true

log "Verifying the produced APK"
python3 "$ROOT_DIR/scripts/verify_apk.py" \
    --apk "$FINAL_APK" \
    --project "$ROOT_DIR" \
    --badging "$BADGING_TXT" \
    --signature-report "$SIGN_REPORT"

log "Comparing with the signature manifest of the original APK"
python3 "$ROOT_DIR/scripts/verify_original_manifest.py" --apk "$FINAL_APK" --project "$ROOT_DIR"

sha256sum "$FINAL_APK" | tee "$FINAL_APK.sha256"
printf '\n\033[1;32mBUILD SUCCESS: %s\033[0m\n' "$FINAL_APK"
