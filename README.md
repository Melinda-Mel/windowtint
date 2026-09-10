# WindowTint — Mission Control 彩色窗口标识

WindowTint 是一个轻量 macOS 菜单栏应用：只在 **Mission Control** 中为应用窗口绘制不拦截鼠标的彩色边框和名称，帮助你快速分辨 Codex、ChatGPT、WorkBuddy、Claude、飞书等窗口。回到正常工作窗口后，所有标识都会自动消失，不干扰视野或系统按钮。

> WindowTint is a lightweight macOS menu-bar app that adds colored, non-interactive outlines and labels to windows in **Mission Control** only. All markers disappear in normal working windows.

## 选哪个包？ / Choose a package

| 你是谁 | 下载 | 适合什么 | 怎么用 |
|---|---|---|---|
| 普通 Mac 用户 | [`WindowTint-0.2.0-macos.zip`](dist/WindowTint-0.2.0-macos.zip) | 想立刻试用，不改代码 | 解压后双击 `WindowTint.app`；菜单栏图标可关闭或退出。 |
| 开发者或想自定义的人 | [`WindowTint-0.2.0-source.zip`](dist/WindowTint-0.2.0-source.zip) 或直接克隆本仓库 | 改颜色、增加应用、自己构建 | 安装 Xcode Command Line Tools，运行 `./build-app.sh`，再打开生成的应用。 |

## 使用体验

- 进入 Mission Control：每个可见应用窗口会出现固定颜色和名称标签。
- 选中并回到任意窗口：所有边框和标签消失，正常办公不受干扰。
- 常见 AI 应用使用预设色；其它应用也会自动获得稳定颜色。
- Mission Control 的窗口变化按最高约 120 次/秒跟随；退出动画期间会暂时隐藏，避免边框乱飞。

## 本地构建

```sh
chmod +x build-app.sh
./build-app.sh
open WindowTint.app
```

已在 Apple Silicon Mac、macOS 26.6 上验证构建。应用只读取公开窗口位置；不会请求辅助功能或屏幕录制权限。

## 安全与发布状态

当前预构建试用包为本地临时签名，**尚未经过 Apple Developer ID 签名和 Apple 公证**。首次打开若被 macOS 拦截，请只对来自本仓库、你信任的副本右键选择“打开”。

面向普通用户的正式发布应先完成 Apple Developer ID 签名与公证，再提供 GitHub Release 的 ZIP 或 DMG。

## 这不是一个 Skill

WindowTint 是需要持续运行的原生 macOS 应用，才能创建窗口叠加层。Codex Skill 可以帮助开发者定制或构建它，但不能替代最终用户运行的 App。

## License

[MIT](LICENSE)
