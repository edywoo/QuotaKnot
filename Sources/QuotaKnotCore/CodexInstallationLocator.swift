import Foundation

public enum CodexInstallationLocator {
    public static func codexHomeURL() -> URL {
        if let configured = ProcessInfo.processInfo.environment["CODEX_HOME"],
           !configured.isEmpty {
            return URL(fileURLWithPath: configured.expandingTildeInPath)
                .standardizedFileURL
        }

        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
    }

    public static func executableURL() -> URL? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path
        let environment = ProcessInfo.processInfo.environment
        let configured = environment["CODEX_CLI_PATH"]?.expandingTildeInPath

        let appExecutables = desktopAppCandidates(home: home).map {
            "\($0)/Contents/Resources/codex"
        }
        let pathExecutables = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { "\($0)/codex" }
        let commonExecutables = [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "\(home)/.local/bin/codex",
            "\(home)/.cargo/bin/codex",
            "\(home)/.npm-global/bin/codex"
        ]

        return uniquePaths([configured].compactMap { $0 } + appExecutables + pathExecutables + commonExecutables)
            .first(where: { fileManager.isExecutableFile(atPath: $0) })
            .map { URL(fileURLWithPath: $0).standardizedFileURL }
    }

    public static func desktopAppURL() -> URL? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path
        return desktopAppCandidates(home: home)
            .first(where: { fileManager.fileExists(atPath: $0) })
            .map { URL(fileURLWithPath: $0).standardizedFileURL }
    }

    private static func desktopAppCandidates(home: String) -> [String] {
        [
            "/Applications/Codex.app",
            "/Applications/ChatGPT.app",
            "\(home)/Applications/Codex.app",
            "\(home)/Applications/ChatGPT.app"
        ]
    }

    private static func uniquePaths(_ paths: [String]) -> [String] {
        var seen = Set<String>()
        return paths.filter { seen.insert($0).inserted }
    }
}

private extension String {
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}
