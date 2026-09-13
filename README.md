<div align="center">
  <img src="Assets/AppIcon-1024.png" width="160" height="160" alt="QuotaKnot app icon">
  <h1>QuotaKnot</h1>
  <p><strong>Know your Codex quota before it runs out.</strong></p>
  <p>
    <strong>English</strong> ·
    <a href="README.ko.md">한국어</a> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.zh-CN.md">简体中文</a>
  </p>
  <p>
    <a href="https://github.com/edywoo/QuotaKnot/actions/workflows/build.yml"><img src="https://github.com/edywoo/QuotaKnot/actions/workflows/build.yml/badge.svg" alt="Build status"></a>
    <img src="https://img.shields.io/badge/macOS-13%2B-000000?logo=apple" alt="macOS 13 or later">
    <img src="https://img.shields.io/badge/Swift-5.10%2B-F05138?logo=swift&amp;logoColor=white" alt="Swift 5.10 or later">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-4B32C3" alt="MIT License"></a>
  </p>
</div>

<p align="center">
  <img src="Assets/QuotaKnot-preview.svg" width="760" alt="QuotaKnot menu bar preview">
</p>

QuotaKnot is an unofficial macOS menu bar app that shows your remaining Codex 5-hour and weekly usage limits, together with the time left until each limit resets.

> QuotaKnot is not an official OpenAI product and is not affiliated with or endorsed by OpenAI.

## Features

- Shows both remaining percentages and reset countdowns in the menu bar.
- Formats countdowns as `6h 23m` under 24 hours and `1d 5h` from 24 hours onward.
- Refreshes when you send a question and when a response finishes.
- Refreshes usage every minute and updates countdown text every 30 seconds.
- Localizes the interface, time units, status text, and errors in English, Korean, Japanese, and Simplified Chinese.
- Uses your existing Codex desktop app or CLI login—no separate API key required.
- Reads `account/rateLimits/read` metadata without making a model request, so refreshing does not consume Codex tokens.
- Builds as a universal app for both Apple Silicon and Intel Macs.

## Requirements

- macOS 13 Ventura or later
- Codex or ChatGPT desktop app, or the Codex CLI
- A ChatGPT account signed in to Codex
- Swift 5.10 or later when building from source

## Install from source

```zsh
git clone https://github.com/edywoo/QuotaKnot.git
cd QuotaKnot
./build-app.sh
./install-app.sh
```

The app is installed at `~/Applications/QuotaKnot.app`. To quit, select the usage text in the menu bar and choose **Quit**.

Because GitHub builds are not signed and notarized with an Apple Developer ID, macOS may block the first launch. If that happens, Control-click the app in Finder and choose **Open**, or build it directly from source.

## Codex discovery

QuotaKnot automatically checks:

- Codex or ChatGPT in `/Applications` and `~/Applications`
- Codex installed by Homebrew on Apple Silicon or Intel Macs
- `PATH`, `~/.local/bin`, `~/.cargo/bin`, and `~/.npm-global/bin`

For a custom installation, launch QuotaKnot with explicit paths:

```zsh
CODEX_CLI_PATH=/custom/path/codex CODEX_HOME=/custom/codex-home \
  "$HOME/Applications/QuotaKnot.app/Contents/MacOS/QuotaKnot"
```

## Verify and package

```zsh
swift run QuotaKnotCoreChecks
./package-release.sh
```

GitHub Actions runs the behavior checks on every push and pull request, then creates a universal macOS ZIP artifact.

## Privacy and network access

- The source contains no personal name, email address, or fixed user home path.
- QuotaKnot neither requires nor stores a separate API key.
- It calls the installed Codex `account/rateLimits/read` method and does not send your questions or responses.
- For event-based refreshes, it reads only newly appended local session lines and distinguishes the `task_started` and `task_complete` event names.
- Only the latest usage percentages and reset times are cached in macOS `UserDefaults`.
- There are no analytics, advertising SDKs, or external tracking servers.

## Known limitation

Usage lookup currently depends on Codex's experimental app-server protocol. It may stop working if an installed Codex version does not provide the method or if the protocol changes.

## License

Released under the [MIT License](LICENSE).

The names `Codex` and `OpenAI` are used only to describe compatibility with the corresponding service.
