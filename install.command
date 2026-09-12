#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
app="$root/WindowTint.app"
destination="$HOME/Applications/WindowTint.app"
label="com.ilenia.windowtint"
agent="$HOME/Library/LaunchAgents/$label.plist"

if [[ ! -d "$app" ]]; then
  echo "找不到 WindowTint.app。请确认 install.command 与应用在同一文件夹。"
  exit 1
fi

mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
ditto "$app" "$destination"
cat > "$agent" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$destination/Contents/MacOS/WindowTint</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
PLIST
plutil -lint "$agent" >/dev/null
launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$agent"
launchctl kickstart -k "gui/$(id -u)/$label"
echo "安装完成：WindowTint 已添加到个人应用目录，并会在下次登录时自动启动。"
