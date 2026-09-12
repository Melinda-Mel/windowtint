#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
version="0.3.0"
dist="$root/dist"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

"$root/build-app.sh"
mkdir -p "$dist"

appPackage="$stage/WindowTint-$version"
mkdir -p "$appPackage"
ditto "$root/WindowTint.app" "$appPackage/WindowTint.app"
ditto "$root/install.command" "$appPackage/install.command"
ditto "$root/README.md" "$appPackage/README.md"
ditto --norsrc -c -k --keepParent "$appPackage" "$dist/WindowTint-$version-macos.zip"

sourcePackage="$stage/WindowTint-$version-source"
mkdir -p "$sourcePackage"
for file in LICENSE README.md WindowTint.m build-app.sh install.command package-release.sh; do
  ditto "$root/$file" "$sourcePackage/$file"
done
ditto --norsrc -c -k --keepParent "$sourcePackage" "$dist/WindowTint-$version-source.zip"
echo "发布包已生成：$dist"
