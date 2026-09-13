<div align="center">
  <img src="Assets/AppIcon-1024.png" width="160" height="160" alt="QuotaKnot 앱 아이콘">
  <h1>QuotaKnot</h1>
  <p><strong>Codex 한도가 끝나기 전에 한눈에 확인하세요.</strong></p>
  <p>
    <a href="README.md">English</a> ·
    <strong>한국어</strong> ·
    <a href="README.ja.md">日本語</a> ·
    <a href="README.zh-CN.md">简体中文</a>
  </p>
  <p>
    <a href="https://github.com/edywoo/QuotaKnot/actions/workflows/build.yml"><img src="https://github.com/edywoo/QuotaKnot/actions/workflows/build.yml/badge.svg" alt="빌드 상태"></a>
    <img src="https://img.shields.io/badge/macOS-13%2B-000000?logo=apple" alt="macOS 13 이상">
    <img src="https://img.shields.io/badge/Swift-5.10%2B-F05138?logo=swift&amp;logoColor=white" alt="Swift 5.10 이상">
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-4B32C3" alt="MIT 라이선스"></a>
  </p>
</div>

<p align="center">
  <img src="Assets/QuotaKnot-preview.svg" width="760" alt="QuotaKnot 메뉴바 미리보기">
</p>

QuotaKnot은 Codex의 5시간·주간 남은 사용량과 각 한도의 초기화까지 남은 시간을 보여주는 비공식 macOS 메뉴바 앱입니다.

> QuotaKnot은 OpenAI의 공식 제품이 아니며 OpenAI와 제휴하거나 보증받지 않았습니다.

## 주요 기능

- 메뉴바에서 5시간·주간 남은 퍼센트와 초기화 카운트다운을 함께 보여줍니다.
- 24시간 미만은 `6시간 23분`, 24시간 이상은 `1일 5시간`처럼 표시합니다.
- 질문을 전송할 때와 응답이 완료될 때 자동으로 다시 읽습니다.
- 사용량은 1분마다, 남은 시간 문구는 30초마다 갱신합니다.
- 화면, 시간 단위, 상태 문구와 오류 메시지를 영어·한국어·일본어·중국어(간체)로 표시할 수 있습니다.
- 별도 API 키 없이 설치된 Codex 데스크톱 앱 또는 CLI의 현재 로그인 정보를 사용합니다.
- 모델 호출이 아닌 `account/rateLimits/read` 메타데이터를 읽으므로 새로고침에 Codex 토큰을 사용하지 않습니다.
- Apple Silicon과 Intel Mac을 모두 지원하는 유니버설 앱으로 빌드됩니다.

## 요구 사항

- macOS 13 Ventura 이상
- Codex 또는 ChatGPT 데스크톱 앱, 혹은 Codex CLI
- ChatGPT 계정으로 Codex에 로그인된 상태
- 소스에서 빌드할 때 Swift 5.10 이상

## 소스에서 설치

```zsh
git clone https://github.com/edywoo/QuotaKnot.git
cd QuotaKnot
./build-app.sh
./install-app.sh
```

앱은 `~/Applications/QuotaKnot.app`에 설치됩니다. 앱을 끄려면 메뉴바의 사용량 표시를 누르고 **종료**를 선택하세요.

GitHub 빌드는 Apple Developer ID로 서명·공증되지 않아 macOS가 처음 실행을 막을 수 있습니다. 이 경우 Finder에서 앱을 Control-클릭한 뒤 **열기**를 선택하거나 소스에서 직접 빌드하세요.

## Codex 설치 위치 탐색

QuotaKnot은 다음 위치를 자동으로 확인합니다.

- `/Applications`와 `~/Applications`의 Codex 또는 ChatGPT 앱
- Apple Silicon·Intel Homebrew로 설치된 Codex
- `PATH`, `~/.local/bin`, `~/.cargo/bin`, `~/.npm-global/bin`

사용자 지정 설치라면 경로를 지정해 실행할 수 있습니다.

```zsh
CODEX_CLI_PATH=/custom/path/codex CODEX_HOME=/custom/codex-home \
  "$HOME/Applications/QuotaKnot.app/Contents/MacOS/QuotaKnot"
```

## 검증과 배포 파일 만들기

```zsh
swift run QuotaKnotCoreChecks
./package-release.sh
```

GitHub Actions는 push와 pull request마다 기능 검사를 실행하고 유니버설 macOS ZIP artifact를 만듭니다.

## 개인정보와 네트워크

- 소스에 개인 이름, 이메일 주소, 고정된 사용자 홈 경로가 포함되어 있지 않습니다.
- 별도 API 키를 요구하거나 저장하지 않습니다.
- 설치된 Codex의 `account/rateLimits/read`를 호출하며 질문이나 답변을 전송하지 않습니다.
- 이벤트 기반 자동 갱신을 위해 로컬 세션 파일에 새로 추가된 줄만 읽고 `task_started`와 `task_complete` 이벤트 이름만 구별합니다.
- 마지막 사용량 퍼센트와 초기화 시각만 macOS `UserDefaults`에 캐시합니다.
- 분석 도구, 광고 SDK, 외부 추적 서버를 사용하지 않습니다.

## 알려진 제한

사용량 조회는 현재 Codex의 실험적 app-server 프로토콜에 의존합니다. 설치된 Codex 버전이 해당 메서드를 제공하지 않거나 향후 프로토콜이 변경되면 조회가 실패할 수 있습니다.

## 라이선스

[MIT License](LICENSE)로 배포됩니다.

`Codex`와 `OpenAI` 이름은 해당 서비스와의 호환성을 설명하기 위해서만 사용합니다.
