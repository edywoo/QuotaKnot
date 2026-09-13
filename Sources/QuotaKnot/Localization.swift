import Foundation
import QuotaKnotCore

enum RefreshReason: Equatable {
    case appLaunch
    case scheduled
    case questionSent
    case responseCompleted
    case manual
}

enum PresentedError: Equatable {
    case executableNotFound
    case processFailed(String)
    case serverError(String)
    case missingRateLimits
    case timedOut
    case desktopAppNotFound
    case unexpected(String)
}

struct LocalizedCopy {
    let language: AppLanguage

    var usageTitle: String {
        switch language {
        case .english: "Codex usage limits"
        case .korean: "코덱스 사용 한도"
        case .japanese: "Codex 利用枠"
        case .simplifiedChinese: "Codex 使用限额"
        }
    }

    var fiveHourLimit: String {
        switch language {
        case .english: "5-hour limit"
        case .korean: "5시간 한도"
        case .japanese: "5時間の利用枠"
        case .simplifiedChinese: "五小时限额"
        }
    }

    var weeklyLimit: String {
        switch language {
        case .english: "Weekly limit"
        case .korean: "주간 한도"
        case .japanese: "週間利用枠"
        case .simplifiedChinese: "每周限额"
        }
    }

    var unavailable: String {
        switch language {
        case .english: "Unavailable"
        case .korean: "확인 불가"
        case .japanese: "確認できません"
        case .simplifiedChinese: "无法获取"
        }
    }

    var waitingForUsage: String {
        switch language {
        case .english: "Waiting for usage data"
        case .korean: "사용량 정보를 기다리는 중"
        case .japanese: "使用量データを待機中"
        case .simplifiedChinese: "正在等待用量数据"
        }
    }

    func resetsIn(_ time: String) -> String {
        switch language {
        case .english: "resets in \(time)"
        case .korean: "\(time) 뒤 초기화"
        case .japanese: "\(time)後にリセット"
        case .simplifiedChinese: "\(time)后重置"
        }
    }

    var resetUnavailable: String {
        switch language {
        case .english: "reset time unavailable"
        case .korean: "초기화 시각 확인 불가"
        case .japanese: "リセット時刻を確認できません"
        case .simplifiedChinese: "无法获取重置时间"
        }
    }

    var autoRefresh: String {
        switch language {
        case .english: "Auto-refresh"
        case .korean: "자동 새로고침"
        case .japanese: "自動更新"
        case .simplifiedChinese: "自动刷新"
        }
    }

    var autoRefreshTriggers: String {
        switch language {
        case .english: "questions · responses · every minute"
        case .korean: "질문 · 응답 · 1분마다"
        case .japanese: "質問 · 応答 · 1分ごと"
        case .simplifiedChinese: "提问 · 响应 · 每分钟"
        }
    }

    var lastUpdated: String {
        switch language {
        case .english: "Last updated"
        case .korean: "마지막 업데이트"
        case .japanese: "最終更新"
        case .simplifiedChinese: "上次更新"
        }
    }

    var notUpdatedYet: String {
        switch language {
        case .english: "Not updated yet"
        case .korean: "아직 업데이트되지 않음"
        case .japanese: "まだ更新されていません"
        case .simplifiedChinese: "尚未更新"
        }
    }

    var refreshNow: String {
        switch language {
        case .english: "Refresh now"
        case .korean: "지금 새로고침"
        case .japanese: "今すぐ更新"
        case .simplifiedChinese: "立即刷新"
        }
    }

    var refreshing: String {
        switch language {
        case .english: "Refreshing…"
        case .korean: "새로고침 중…"
        case .japanese: "更新中…"
        case .simplifiedChinese: "正在刷新…"
        }
    }

    var openCodex: String {
        switch language {
        case .english: "Open Codex"
        case .korean: "Codex 열기"
        case .japanese: "Codex を開く"
        case .simplifiedChinese: "打开 Codex"
        }
    }

    var quit: String {
        switch language {
        case .english: "Quit"
        case .korean: "종료"
        case .japanese: "終了"
        case .simplifiedChinese: "退出"
        }
    }

    var languageLabel: String {
        switch language {
        case .english: "Language"
        case .korean: "언어"
        case .japanese: "言語"
        case .simplifiedChinese: "语言"
        }
    }

    var refreshFailed: String {
        switch language {
        case .english: "Couldn't refresh usage"
        case .korean: "사용량을 새로고침하지 못했습니다"
        case .japanese: "使用量を更新できませんでした"
        case .simplifiedChinese: "无法刷新使用量"
        }
    }

    func reason(_ reason: RefreshReason) -> String {
        switch (language, reason) {
        case (.english, .appLaunch): "App launch"
        case (.english, .scheduled): "Every minute"
        case (.english, .questionSent): "Question sent"
        case (.english, .responseCompleted): "Response completed"
        case (.english, .manual): "Manual"
        case (.korean, .appLaunch): "앱 시작"
        case (.korean, .scheduled): "1분 주기"
        case (.korean, .questionSent): "질문 전송"
        case (.korean, .responseCompleted): "응답 완료"
        case (.korean, .manual): "수동"
        case (.japanese, .appLaunch): "アプリ起動"
        case (.japanese, .scheduled): "1分ごと"
        case (.japanese, .questionSent): "質問送信"
        case (.japanese, .responseCompleted): "応答完了"
        case (.japanese, .manual): "手動"
        case (.simplifiedChinese, .appLaunch): "应用启动"
        case (.simplifiedChinese, .scheduled): "每分钟"
        case (.simplifiedChinese, .questionSent): "已发送问题"
        case (.simplifiedChinese, .responseCompleted): "响应完成"
        case (.simplifiedChinese, .manual): "手动"
        }
    }

    func errorMessage(for error: PresentedError) -> String {
        switch error {
        case .executableNotFound:
            return switch language {
            case .english: "Codex could not be found. Install the Codex desktop app or CLI."
            case .korean: "Codex를 찾지 못했습니다. Codex 데스크톱 앱 또는 CLI를 설치해 주세요."
            case .japanese: "Codex が見つかりません。Codex デスクトップアプリまたは CLI をインストールしてください。"
            case .simplifiedChinese: "找不到 Codex。请安装 Codex 桌面应用或 CLI。"
            }
        case .processFailed(let detail):
            return errorPrefix(
                english: "Codex usage could not be read",
                korean: "Codex 사용량을 읽지 못했습니다",
                japanese: "Codex の使用量を取得できませんでした",
                chinese: "无法读取 Codex 用量",
                detail: detail
            )
        case .serverError(let detail):
            return errorPrefix(
                english: "Codex returned an error",
                korean: "Codex가 오류를 반환했습니다",
                japanese: "Codex がエラーを返しました",
                chinese: "Codex 返回了错误",
                detail: detail
            )
        case .missingRateLimits:
            return switch language {
            case .english: "The response did not include 5-hour or weekly limits. Check your Codex sign-in."
            case .korean: "응답에 5시간 또는 주간 한도가 없습니다. Codex 로그인 상태를 확인해 주세요."
            case .japanese: "応答に5時間または週間利用枠がありません。Codex のログイン状態を確認してください。"
            case .simplifiedChinese: "响应中没有五小时或每周限额。请检查 Codex 登录状态。"
            }
        case .timedOut:
            return switch language {
            case .english: "Codex did not respond within 15 seconds."
            case .korean: "Codex가 15초 안에 응답하지 않았습니다."
            case .japanese: "Codex が15秒以内に応答しませんでした。"
            case .simplifiedChinese: "Codex 未在15秒内响应。"
            }
        case .desktopAppNotFound:
            return switch language {
            case .english: "The Codex or ChatGPT desktop app could not be found."
            case .korean: "Codex 또는 ChatGPT 데스크톱 앱을 찾지 못했습니다."
            case .japanese: "Codex または ChatGPT デスクトップアプリが見つかりません。"
            case .simplifiedChinese: "找不到 Codex 或 ChatGPT 桌面应用。"
            }
        case .unexpected(let detail):
            return errorPrefix(
                english: "An unexpected error occurred",
                korean: "예상하지 못한 오류가 발생했습니다",
                japanese: "予期しないエラーが発生しました",
                chinese: "发生了意外错误",
                detail: detail
            )
        }
    }

    private func errorPrefix(
        english: String,
        korean: String,
        japanese: String,
        chinese: String,
        detail: String
    ) -> String {
        let prefix = switch language {
        case .english: english
        case .korean: korean
        case .japanese: japanese
        case .simplifiedChinese: chinese
        }
        return detail.isEmpty ? prefix : "\(prefix): \(detail)"
    }
}
