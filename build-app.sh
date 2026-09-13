#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
app_dir="$project_dir/dist/QuotaKnot.app"

cd "$project_dir"
swift build -c release --arch arm64 --arch x86_64
binary_dir=$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)

mkdir -p "$app_dir/Contents/MacOS"
mkdir -p "$app_dir/Contents/Resources"
cp "$project_dir/Info.plist" "$app_dir/Contents/Info.plist"
cp "$binary_dir/QuotaKnot" "$app_dir/Contents/MacOS/QuotaKnot"
cp "$project_dir/Assets/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
chmod +x "$app_dir/Contents/MacOS/QuotaKnot"

codesign --force --deep --sign - "$app_dir"
echo "$app_dir"
