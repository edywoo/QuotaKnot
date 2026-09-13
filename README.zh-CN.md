<div align="center">
  <img src="Assets/AppIcon-1024.png" width="160" height="160" alt="QuotaKnot 应用图标">
  <h1>QuotaKnot</h1>
  <p><strong>在 Codex 配额用完之前，一眼掌握剩余用量。</strong></p>
  <p>
    <a href="README.md">English</a> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.ja.md">日本語</a> ·
    <strong>简体中文</strong>
  </p>
  <p>
    <a href="https://github.com/edywoo/QuotaKnot/actions/workflows/build.yml"><img src="https://github.com/edywoo/QuotaKnot/actions/workflows/build.yml/badge.svg" alt="构建状态"></a>
    <img src="https://img.shields.io/badge/macOS-13%2B-000000?logo=apple" alt="macOS 13 或更高版本">
    <img src="https://img.shields.io/badge/Swift-5.10%2B-F05138?logo=swift&amp;logoColor=white" alt="Swift 5.10 或更高版本">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-4B32C3" alt="MIT 许可证"></a>
  </p>
</div>

<p align="center">
  <img src="Assets/QuotaKnot-preview.svg" width="760" alt="QuotaKnot 菜单栏预览">
</p>

QuotaKnot 是一款非官方 macOS 菜单栏应用，用于显示 Codex 五小时和每周配额的剩余百分比，以及距离各配额重置的时间。

> QuotaKnot 不是 OpenAI 官方产品，也未与 OpenAI 建立合作关系或获得其认可。

## 主要功能

- 在菜单栏中同时显示五小时、每周配额的剩余百分比和重置倒计时。
- 不足24小时时显示为 `6小时23分钟`，达到24小时后显示为 `1天5小时`。
- 发送问题和响应完成时自动刷新。
- 每分钟刷新使用量，每30秒更新一次剩余时间文字。
- 界面、时间单位、状态文字和错误消息支持英语、韩语、日语和简体中文。
- 使用已安装的 Codex 桌面应用或 CLI 登录状态，无需单独的 API 密钥。
- 读取 `account/rateLimits/read` 元数据，不会发起模型请求，因此刷新不会消耗 Codex token。
- 构建为同时支持 Apple Silicon 和 Intel Mac 的通用应用。

## 系统要求

- macOS 13 Ventura 或更高版本
- Codex 或 ChatGPT 桌面应用，或者 Codex CLI
- 已使用 ChatGPT 账户登录 Codex
- 从源码构建时需要 Swift 5.10 或更高版本

## 从源码安装

```zsh
git clone https://github.com/edywoo/QuotaKnot.git
cd QuotaKnot
./build-app.sh
./install-app.sh
```

应用会安装到 `~/Applications/QuotaKnot.app`。如需退出，请点击菜单栏中的用量信息并选择 **退出**。

GitHub 构建未使用 Apple Developer ID 签名和公证，因此 macOS 可能会阻止首次启动。遇到这种情况时，请在 Finder 中按住 Control 键点击应用并选择 **打开**，或者直接从源码构建。

## 自动查找 Codex

QuotaKnot 会自动检查以下位置：

- `/Applications` 和 `~/Applications` 中的 Codex 或 ChatGPT 应用
- 通过 Apple Silicon 或 Intel Homebrew 安装的 Codex
- `PATH`、`~/.local/bin`、`~/.cargo/bin` 和 `~/.npm-global/bin`

如果安装在自定义位置，可以指定路径启动：

```zsh
CODEX_CLI_PATH=/custom/path/codex CODEX_HOME=/custom/codex-home \
  "$HOME/Applications/QuotaKnot.app/Contents/MacOS/QuotaKnot"
```

## 验证与打包

```zsh
swift run QuotaKnotCoreChecks
./package-release.sh
```

GitHub Actions 会在每次 push 和 pull request 时运行功能检查，并生成通用 macOS ZIP artifact。

## 隐私与网络访问

- 源码不包含个人姓名、电子邮箱或固定的用户主目录路径。
- 不需要也不会保存单独的 API 密钥。
- 仅调用已安装 Codex 的 `account/rateLimits/read`，不会发送你的问题或响应。
- 为了根据事件自动刷新，只读取本地会话文件中新追加的行，并仅识别 `task_started` 和 `task_complete` 事件名称。
- 只在 macOS `UserDefaults` 中缓存最新的使用百分比和重置时间。
- 不使用分析工具、广告 SDK 或外部跟踪服务器。

## 已知限制

目前，用量查询依赖 Codex 的实验性 app-server 协议。如果已安装的 Codex 版本不提供相应方法，或今后协议发生变化，查询可能会失败。

## 许可证

本项目基于 [MIT License](LICENSE) 发布。

`Codex` 和 `OpenAI` 名称仅用于说明与相应服务的兼容性。
