# QuotaKnot

Codex의 5시간·주간 남은 사용량과 초기화까지 남은 시간을 한눈에 묶어 보여주는 비공식 macOS 메뉴바 앱입니다.

> 이 프로젝트는 OpenAI의 공식 제품이 아니며 OpenAI와 제휴하거나 보증받지 않았습니다.

```text
5시간 5% (2시간 14분) · 주간 85% (6일 21시간)
```

- 24시간 미만: `6시간 23분`
- 24시간 이상: `1일 5시간`
- 질문을 전송할 때와 응답이 완료될 때 자동으로 다시 읽습니다.
- 사용 중이 아니어도 1분마다 자동으로 다시 읽고, 남은 시간은 30초마다 갱신합니다.
- 별도 API 키 없이 설치된 Codex 데스크톱 앱/CLI의 현재 로그인 정보를 사용합니다.
- 새로고침은 모델 호출이 아닌 `account/rateLimits/read` 메타데이터 요청이므로 코덱스 토큰을 사용하지 않습니다.
- 청록·보라 사용량 링과 주황색 한도 구간을 사용한 전용 앱 아이콘을 포함합니다.

## 요구 사항

- macOS 13 Ventura 이상
- Codex 또는 ChatGPT 데스크톱 앱, 혹은 Codex CLI
- ChatGPT 계정으로 Codex에 로그인된 상태
- 소스에서 빌드할 때는 Swift 5.10 이상

Apple Silicon과 Intel Mac을 모두 지원하는 유니버설 앱으로 빌드됩니다.

## 설치

```zsh
# GitHub의 Code 버튼에서 저장소 주소를 복사합니다.
git clone <복사한_저장소_주소>
cd QuotaKnot
./build-app.sh
./install-app.sh
```

앱은 `~/Applications/QuotaKnot.app`에 설치됩니다. 앱을 끄려면 메뉴바의 사용량 표시를 누르고 `종료`를 선택하세요.

서명·공증되지 않은 GitHub 배포 파일은 macOS가 처음 실행을 막을 수 있습니다. 이 경우 Finder에서 앱을 Control-클릭한 뒤 `열기`를 선택하거나, 소스에서 직접 빌드하세요. 정식 배포에서는 Apple Developer ID 서명과 공증을 권장합니다.

## Codex 설치 위치 탐색

다음 위치를 자동으로 탐색합니다.

- `/Applications`와 `~/Applications`의 Codex 또는 ChatGPT 앱
- Apple Silicon·Intel Homebrew의 `codex`
- 현재 `PATH`, `~/.local/bin`, `~/.cargo/bin`, `~/.npm-global/bin`

사용자 지정 설치라면 앱을 터미널에서 다음처럼 직접 실행할 수 있습니다.

```zsh
CODEX_CLI_PATH=/custom/path/codex CODEX_HOME=/custom/codex-home \
  "$HOME/Applications/QuotaKnot.app/Contents/MacOS/QuotaKnot"
```

## 검증과 배포 파일 만들기

```zsh
swift run QuotaKnotCoreChecks
./package-release.sh
```

GitHub Actions는 push와 pull request마다 기능 검사를 실행하고 유니버설 macOS ZIP을 artifact로 만듭니다.

## 개인정보와 네트워크

- 이름, 이메일, 사용자 홈 경로 같은 개인정보가 소스에 포함되어 있지 않습니다.
- 별도 API 키를 저장하거나 요구하지 않습니다.
- 설치된 Codex의 `account/rateLimits/read`를 호출하며 질문이나 답변을 전송하지 않습니다.
- 자동 갱신을 위해 로컬 세션 파일에 새로 추가된 이벤트 줄만 확인하고, `task_started`와 `task_complete` 문자열만 구별합니다.
- 마지막 사용량 퍼센트와 초기화 시각만 macOS `UserDefaults`에 캐시합니다.
- 분석 도구, 광고 SDK, 외부 추적 서버를 사용하지 않습니다.

## 알려진 제한

사용량 조회는 현재 Codex의 실험적 app-server 프로토콜에 의존합니다. Codex 버전이 해당 메서드를 제공하지 않거나 향후 프로토콜이 변경되면 조회가 실패할 수 있습니다.

## 라이선스

[MIT License](LICENSE)

`Codex`와 `OpenAI` 이름은 호환되는 서비스와의 연동을 설명하기 위해서만 사용합니다.
