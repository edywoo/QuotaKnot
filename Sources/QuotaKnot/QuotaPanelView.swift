import AppKit
import QuotaKnotCore
import SwiftUI

struct QuotaPanelView: View {
    @ObservedObject var model: UsageViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.quotaBackgroundTop, .quotaBackgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.quotaCyan.opacity(0.08))
                .frame(width: 260, height: 260)
                .offset(x: -210, y: 190)

            Circle()
                .fill(Color.quotaPurple.opacity(0.10))
                .frame(width: 250, height: 250)
                .offset(x: 210, y: -190)

            VStack(spacing: 16) {
                header
                limitsCard

                if let errorMessage = model.errorMessage {
                    errorBanner(errorMessage)
                }

                languageSelector
                footer
            }
            .padding(20)
        }
        .frame(width: 440)
        .fixedSize(horizontal: true, vertical: true)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 46, height: 46)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 2) {
                Text("QuotaKnot")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(model.copy.usageTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.quotaSecondaryText)
            }

            Spacer(minLength: 8)

            if model.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.quotaCyan)
            }
        }
    }

    private var languageSelector: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    model.language = language
                } label: {
                    if model.language == language {
                        Label(language.nativeName, systemImage: "checkmark")
                    } else {
                        Text(language.nativeName)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundColor(.quotaCyan)

                Text(model.copy.languageLabel)
                    .foregroundColor(.white)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.65))

                Spacer(minLength: 12)

                Text(model.language.nativeName)
                    .foregroundColor(.white.opacity(0.78))
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
        .foregroundColor(.white)
        .tint(.white)
        .frame(maxWidth: .infinity)
        .help(model.copy.languageLabel)
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var limitsCard: some View {
        VStack(spacing: 18) {
            QuotaProgressRow(
                title: model.copy.fiveHourLimit,
                status: model.fiveHourStatusText,
                progress: model.progress(for: model.fiveHourPercent),
                colors: [.quotaCyan, .quotaBlue]
            )

            QuotaProgressRow(
                title: model.copy.weeklyLimit,
                status: model.weeklyStatusText,
                progress: model.progress(for: model.weeklyPercent),
                colors: [.quotaBlue, .quotaPurple]
            )

            Divider()
                .overlay(Color.white.opacity(0.09))

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.quotaGreen)
                    .frame(width: 8, height: 8)
                    .shadow(color: .quotaGreen.opacity(0.35), radius: 4)
                Text("\(model.copy.autoRefresh): \(model.copy.autoRefreshTriggers)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.quotaSecondaryText)
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(Color.quotaSecondaryText)
                Text(model.lastUpdatedText)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.quotaSecondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
        }
        .padding(17)
        .background(Color.quotaCard.opacity(0.95), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 18, y: 10)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.quotaOrange)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.copy.refreshFailed)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.quotaPrimaryText)
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.quotaSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.quotaOrange.opacity(0.10), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.quotaOrange.opacity(0.25), lineWidth: 1)
        }
    }

    private var footer: some View {
        HStack(spacing: 9) {
            Button {
                Task { await model.refresh() }
            } label: {
                Label(
                    model.isRefreshing ? model.copy.refreshing : model.copy.refreshNow,
                    systemImage: "arrow.clockwise"
                )
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.quotaBlue)
            .disabled(model.isRefreshing)

            Button {
                model.openCodex()
            } label: {
                Label(model.copy.openCodex, systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button {
                model.quit()
            } label: {
                Label(model.copy.quit, systemImage: "power")
                    .lineLimit(1)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(Color.quotaSecondaryText)
            .keyboardShortcut("q")
        }
        .font(.system(size: 12, weight: .semibold))
    }
}

private struct QuotaProgressRow: View {
    let title: String
    let status: String
    let progress: Double
    let colors: [Color]

    var body: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.quotaSecondaryText)
                Spacer(minLength: 8)
                Text(status)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.quotaPrimaryText)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.quotaTrack)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 9)
            .animation(.easeInOut(duration: 0.35), value: progress)
        }
    }
}

private extension Color {
    static let quotaBackgroundTop = Color(red: 7 / 255, green: 20 / 255, blue: 38 / 255)
    static let quotaBackgroundBottom = Color(red: 29 / 255, green: 18 / 255, blue: 66 / 255)
    static let quotaCard = Color(red: 17 / 255, green: 24 / 255, blue: 39 / 255)
    static let quotaTrack = Color(red: 40 / 255, green: 50 / 255, blue: 71 / 255)
    static let quotaPrimaryText = Color(red: 248 / 255, green: 250 / 255, blue: 252 / 255)
    static let quotaSecondaryText = Color(red: 180 / 255, green: 194 / 255, blue: 214 / 255)
    static let quotaCyan = Color(red: 20 / 255, green: 217 / 255, blue: 230 / 255)
    static let quotaBlue = Color(red: 57 / 255, green: 120 / 255, blue: 255 / 255)
    static let quotaPurple = Color(red: 168 / 255, green: 85 / 255, blue: 247 / 255)
    static let quotaGreen = Color(red: 54 / 255, green: 211 / 255, blue: 153 / 255)
    static let quotaOrange = Color(red: 255 / 255, green: 181 / 255, blue: 62 / 255)
}
