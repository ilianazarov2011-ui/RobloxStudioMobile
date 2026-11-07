#!/usr/bin/env bash
# Builds the Roblox Studio Mobile APK: Winlator (LGPL-2.1) at a pinned commit + patches/*.patch.
#
# Requirements: JDK 17+, Android SDK with platform 35, build-tools 35, NDK 24.0.8215888, CMake 3.22.1
# (ANDROID_HOME must point at it). For a signed APK, create keystore.properties next to this script:
#   storeFile=/absolute/path/to/your.jks
#   storePassword=...
#   keyAlias=...
#   keyPassword=...
set -euo pipefail

WINLATOR_APP_REPO=https://github.com/brunodev85/winlator-app
WINLATOR_APP_COMMIT=3981d86efa4f333b2a34a7da8b6521476cd8c8b9

ROOT=$(cd "$(dirname "$0")" && pwd)
SRC="$ROOT/build/winlator-app"

if [ ! -d "$SRC/.git" ]; then
    mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" remote add origin "$WINLATOR_APP_REPO"
fi
git -C "$SRC" fetch -q --depth 1 origin "$WINLATOR_APP_COMMIT"
git -C "$SRC" checkout -q -f FETCH_HEAD
git -C "$SRC" clean -q -fdx -e keystore.properties -e local.properties
git -C "$SRC" apply "$ROOT"/patches/*.patch

if [ -f "$ROOT/keystore.properties" ]; then cp "$ROOT/keystore.properties" "$SRC/keystore.properties"; fi
if [ -n "${ANDROID_HOME:-}" ]; then echo "sdk.dir=$ANDROID_HOME" > "$SRC/local.properties"; fi

# gradle/maven-mirror.gradle routes Maven Central through Google's mirror (repo.maven.apache.org
# rate-limits some cloud machines with HTTP 429).
(cd "$SRC" && chmod +x gradlew && ./gradlew --no-daemon --init-script "$ROOT/gradle/maven-mirror.gradle" assembleDebug --stacktrace)

mkdir -p "$ROOT/apk"
cp "$SRC/app/build/outputs/apk/debug/app-debug.apk" "$ROOT/apk/RobloxStudioMobile.apk"
ls -la "$ROOT/apk"
