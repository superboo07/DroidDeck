#!/usr/bin/env bash
# Installs the Android SDK packages DroidDeck builds with into $ANDROID_HOME (a
# volume, so it survives rebuilds). Google's SDK licence is shown for you to
# accept; it is never accepted on your behalf. Safe to rerun after a version bump.
set -euo pipefail

cd "$(dirname "$0")/.."

: "${ANDROID_HOME:?}"
clt_zip=commandlinetools-linux-16111833_latest.zip
clt_sha256=0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8

if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT
    curl -fsSL -o "$work/$clt_zip" "https://dl.google.com/android/repository/$clt_zip"
    echo "$clt_sha256  $work/$clt_zip" | sha256sum -c -
    unzip -q "$work/$clt_zip" -d "$work"
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    rm -rf "$ANDROID_HOME/cmdline-tools/latest"
    mv "$work/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi

ndk=$(sed -n 's/^ndkVersion=//p' gradle.properties)
cmake=$(sed -n "s/^ *version '\([0-9.]*\)'.*/\1/p" app/build.gradle | head -1)
compile_sdk=$(sed -n 's/^ *compileSdk \([0-9]*\).*/\1/p' app/build.gradle | head -1)
# AGP 8.8's default build-tools.
build_tools=35.0.0

sdkmanager --licenses
sdkmanager --install \
    platform-tools \
    "platforms;android-${compile_sdk}" \
    "build-tools;${build_tools}" \
    "ndk;${ndk}" \
    "cmake;${cmake}"
