#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
app="$root/WindowTint.app"
mkdir -p "$root/.build-cache"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
CLANG_MODULE_CACHE_PATH="$root/.build-cache" clang -fobjc-arc "$root/WindowTint.m" -o "$app/Contents/MacOS/WindowTint" -framework AppKit -framework CoreGraphics -framework CoreVideo
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleDisplayName</key><string>WindowTint</string>
  <key>CFBundleExecutable</key><string>WindowTint</string>
  <key>CFBundleIdentifier</key><string>com.windowtint.app</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>WindowTint</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.3.0</string>
  <key>CFBundleVersion</key><string>3</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app" >/dev/null
echo "Built $app"
