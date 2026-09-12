# WindowTint — 在 Mission Control 里一眼认出窗口

WindowTint 是一个轻量的 macOS 菜单栏应用。它只在 **Mission Control** 中为窗口加上不拦截鼠标的彩色边框和名称，让你快速区分 Codex、ChatGPT、WorkBuddy、Claude、飞书、浏览器等窗口；回到普通工作界面，标识会自动消失，不遮挡红黄绿窗口按钮，也不干扰办公。

适合经常同时开很多应用窗口的人：AI 使用者、产品与运营、开发者、研究者，以及需要快速在多个项目之间切换的 Mac 用户。

## 直接使用（普通用户）

1. 下载 [WindowTint-0.3.0-macos.zip](dist/WindowTint-0.3.0-macos.zip) 并解压。
2. 双击同一文件夹里的 `install.command`。它会把应用装到你的 `~/Applications`，并设为登录后自动启动；不需要管理员密码。
3. 打开 Mission Control（触控板上推或按你的快捷键），查看彩色标识。

如果 macOS 第一次阻止打开，请确认下载来源可信，然后在应用上右键选择“打开”。菜单栏里的图标可以临时关闭边框或退出 WindowTint。

## 工作方式与隐私

- 只读取系统提供的公开窗口位置和应用名称，用于绘制边框。
- 不读取屏幕内容、键盘输入、剪贴板、文件或账号信息。
- 不需要辅助功能或屏幕录制权限。
- 常见 AI 应用使用预设色；其它应用自动获得稳定颜色。
- 边框在显示器刷新时更新；Mission Control 的动画由 macOS 合成器控制，极高速动画中仍可能有极轻微的位置差。

## 给开发者：构建与定制

需要 Xcode Command Line Tools：

```sh
chmod +x build-app.sh package-release.sh install.command
./build-app.sh
open WindowTint.app
```

改 `WindowTint.m` 中的 `styles` 就能增加应用的名称和固定颜色。要重新生成两个分享包：

```sh
./package-release.sh
```

## 下载包说明

| 文件 | 给谁用 | 内容 |
|---|---|---|
| `WindowTint-0.3.0-macos.zip` | 想直接使用的 Mac 用户 | 应用、安装命令、中文说明 |
| `WindowTint-0.3.0-source.zip` | 想改颜色或参与开发的人 | 完整源码、构建与打包脚本 |

## 发布状态

当前应用使用本地临时签名，尚未经过 Apple Developer ID 签名和 Apple 公证。它适合从本仓库下载、自己构建或技术用户试用；面向更广泛的普通用户发布前，建议完成 Developer ID 签名和公证。

这不是一个 Codex Skill：它是一个需要持续运行的原生 macOS 应用，才能在 Mission Control 中创建窗口叠加层。

## License

[MIT](LICENSE)
