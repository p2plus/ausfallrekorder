#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
swift build -c release
bin_dir=$(swift build -c release --show-bin-path)
app=dist/Ausfallrekorder.app
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Ausfallrekorder" "$app/Contents/MacOS/"
cp "$bin_dir/ausfallrekorder-cli" dist/
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Ausfallrekorder</string>
<key>CFBundleDisplayName</key><string>Ausfallrekorder</string>
<key>CFBundleIdentifier</key><string>dev.p2plus.ausfallrekorder</string>
<key>CFBundleExecutable</key><string>Ausfallrekorder</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
ditto -c -k --keepParent "$app" dist/Ausfallrekorder-macOS.zip
printf 'App: %s\nCLI: %s\n' "$app" dist/ausfallrekorder-cli
