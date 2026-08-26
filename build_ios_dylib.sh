#!/bin/bash
set -euo pipefail

# Определяем SDK
if [[ -z "${SDKROOT:-}" ]]; then
    SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
else
    SDK="$SDKROOT"
fi

CLANG="$(xcrun --find clang)"
ARCH="arm64"
MIN_VERSION="15.0"

echo "🔨 Building for iOS ${MIN_VERSION}+ on ${ARCH}..."
echo "📁 SDK: $SDK"

mkdir -p build

# Сборка всех .m и .mm файлов из папки Sources
SOURCES=$(find Sources -name "*.m" -o -name "*.mm" | tr '\n' ' ')

# Добавляем флаги для C++ поддержки и исключений
"$CLANG" \
  -fobjc-arc \
  -fobjc-weak \
  -fcxx-exceptions \
  -fexceptions \
  -stdlib=libc++ \
  -isysroot "$SDK" \
  -miphoneos-version-min=$MIN_VERSION \
  -arch $ARCH \
  -dynamiclib \
  -framework UIKit \
  -framework QuartzCore \
  -framework Foundation \
  -framework CoreGraphics \
  -lc++ \
  -ldl \
  $SOURCES \
  -install_name @rpath/Lucky77.dylib \
  -o build/Lucky77.dylib

if [ -f "build/Lucky77.dylib" ]; then
    echo "✅ Built: build/Lucky77.dylib"
    file build/Lucky77.dylib
    ls -la build/
else
    echo "❌ Build failed!"
    exit 1
fi
