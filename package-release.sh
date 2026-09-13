#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$project_dir/Info.plist")
archive="$project_dir/dist/QuotaKnot-v$version-macos.zip"

"$project_dir/build-app.sh"
ditto --norsrc -c -k --keepParent \
    "$project_dir/dist/QuotaKnot.app" \
    "$archive"

echo "$archive"
