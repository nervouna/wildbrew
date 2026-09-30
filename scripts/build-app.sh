#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch="${WILDBREW_BUILD_PATH:-/private/tmp/wildbrew-build}"
swift build --configuration release --disable-sandbox --scratch-path "$scratch" --jobs 2
bin_dir="$(swift build --configuration release --disable-sandbox --scratch-path "$scratch" --show-bin-path)"
app="dist/Wildbrew.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/Wildbrew" "$app/Contents/MacOS/Wildbrew"
cp "$bin_dir/wildbrew-check" dist/wildbrew-check
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.nervouna.wildbrew</string>
<key>CFBundleName</key><string>Wildbrew</string>
<key>CFBundleDisplayName</key><string>Wildbrew</string>
<key>CFBundleExecutable</key><string>Wildbrew</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSAppleEventsUsageDescription</key><string>在终端执行 Homebrew 命令。</string>
</dict></plist>
PLIST
xcrun actool Resources/AppIcon/WildbrewAppIcon.icon \
  --compile "$app/Contents/Resources" \
  --platform macosx --minimum-deployment-target 15.0 \
  --app-icon WildbrewAppIcon \
  --output-partial-info-plist "$scratch/wildbrew-icon-info.plist"
/usr/libexec/PlistBuddy -c "Merge '$scratch/wildbrew-icon-info.plist'" "$app/Contents/Info.plist"
codesign --force --sign - "$app"
codesign --force --sign - dist/wildbrew-check
codesign --verify --strict "$app"
