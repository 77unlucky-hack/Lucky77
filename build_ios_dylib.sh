#!/bin/bash
set -euo pipefail

SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
CLANG="$(xcrun --find clang)"
ARCH="arm64"
MIN_VERSION="15.0"

mkdir -p build

"$CLANG" \
  -fobjc-arc \
  -fobjc-weak \
  -isysroot "$SDK" \
  -miphoneos-version-min=$MIN_VERSION \
  -arch $ARCH \
  -dynamiclib \
  -framework UIKit \
  -framework AudioToolbox \
  -framework QuartzCore \
  -framework Foundation \
  -framework CoreGraphics \
  Tweak.mm \
  -o build/Lucky77.dylib

echo "✅ Built: build/Lucky77.dylib"
