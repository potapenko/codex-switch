import AppKit
import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState
    @State private var areEmailsMasked = false
    @State private var isCLISettingsVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Codex accounts")
                    .font(.headline)
                Spacer()
                Button {
                    areEmailsMasked.toggle()
                } label: {
                    Image(systemName: areEmailsMasked ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .help(areEmailsMasked ? "Show email addresses" : "Mask email addresses")
                .accessibilityLabel(areEmailsMasked ? "Show email addresses" : "Mask email addresses")
                Button {
                    isCLISettingsVisible.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Codex CLI settings")
                .accessibilityLabel("Codex CLI settings")
                Button("Refresh all") {
                    Task { await appState.refreshAll() }
                }
                .disabled(appState.isRefreshing || appState.profiles.isEmpty)
            }

            if isCLISettingsVisible {
                CodexCLISettingsDialog(appState: appState) {
                    isCLISettingsVisible = false
                }
                Divider()
            }

            if appState.profiles.isEmpty {
                ContentUnavailableView("No accounts", systemImage: "person.crop.circle.badge.plus", description: Text("Add a ChatGPT account to view its Codex quotas."))
                    .frame(width: 320, height: 150)
            } else {
                List {
                    ForEach(appState.profiles) { profile in
                        let profileIndex = appState.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0
                        ProfileRow(
                            profile: profile,
                            displayName: areEmailsMasked
                                ? profile.maskedDisplayName(fallback: "Account \(profileIndex + 1)")
                                : profile.label,
                            areEmailsMasked: areEmailsMasked,
                            isRefreshing: appState.isRefreshing,
                            remove: {
                                appState.removeAccount(profileID: profile.id)
                            },
                            retry: {
                                Task { await appState.retry(profileID: profile.id) }
                            },
                            signIn: {
                                Task { await appState.signInAgain(profileID: profile.id) }
                            },
                            saveNickname: { nickname in
                                appState.updateNickname(nickname, for: profile.id)
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    }
                    .onMove { sourceOffsets, destination in
                        appState.moveAccounts(from: sourceOffsets, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(height: profileListHeight)
            }

            Divider()
            HStack {
                Button("Add account") {
                    Task { await appState.addAccount() }
                }
                Spacer()
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(14)
        .frame(width: 360)
        .onChange(of: appState.isCLISettingsRequested) { _, isRequested in
            if isRequested {
                isCLISettingsVisible = true
            }
        }
    }

    private var profileListHeight: CGFloat {
        let contentHeight = appState.profiles.reduce(CGFloat.zero) { height, profile in
            let needsRecoveryLine = profile.snapshotState == .signInRequired || profile.snapshotState == .signingIn
            return height + (needsRecoveryLine ? 132 : 104)
        }
        return min(contentHeight, 620)
    }
}

private struct ProfileRow: View {
    let profile: AccountProfile
    let displayName: String
    let areEmailsMasked: Bool
    let isRefreshing: Bool
    let remove: () -> Void
    let retry: () -> Void
    let signIn: () -> Void
    let saveNickname: (String) -> Void
    @State private var isEditingNickname = false
    @State private var nicknameDraft = ""
    @FocusState private var isAccountNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                profileName
                Spacer()
                if let plan = profile.snapshot?.plan { Text(plan).foregroundStyle(.secondary) }
                Button("Remove", role: .destructive, action: remove)
            }
            if let snapshot = profile.snapshot {
                if let primary = codexPrimaryWindow(in: snapshot), let usedPercent = primary.usedPercent {
                    quotaLine(primary: primary, usedPercent: usedPercent)
                } else {
                    Text("Quota unavailable")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if let resetCredits = snapshot.resetCredits {
                    StatusBadge(
                        title: "\(resetCredits.availableCount) resets",
                        systemImage: "arrow.counterclockwise",
                        tint: resetCredits.badgeTone.tint
                    )
                    .accessibilityLabel(resetCredits.hasAvailableCredits ? "\(resetCredits.availableCount) reset credits available" : "No reset credits available")
                }
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(QuotaPresentation.updatedText(for: snapshot.refreshedAt, now: context.date))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else if recoveryText == nil {
                Text(statusText).font(.footnote).foregroundStyle(.secondary)
            }
            if let recoveryText {
                Text(recoveryText).font(.footnote).foregroundStyle(.secondary)
            } else if let error = profile.lastError {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
            if canSignIn {
                HStack {
                    Spacer()
                    Button("Sign in again", action: signIn)
                        .buttonStyle(.borderless)
                }
            } else if canRetry {
                HStack {
                    Spacer()
                    Button("Retry", action: retry)
                        .buttonStyle(.borderless)
                }
            }
        }
        .onChange(of: areEmailsMasked) { _, isMasked in
            if !isMasked {
                saveAccountName()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityActions {
            if canSignIn {
                Button("Sign in again", action: signIn)
            } else if canRetry {
                Button("Retry", action: retry)
            }
        }
    }

    @ViewBuilder
    private var profileName: some View {
        if areEmailsMasked {
            if isEditingNickname {
                TextField("Account Name", text: $nicknameDraft)
                    .textFieldStyle(.roundedBorder)
                    .focused($isAccountNameFocused)
                    .accessibilityLabel("Account Name")
                    .onSubmit(saveAccountName)
                    .onChange(of: isAccountNameFocused) { _, isFocused in
                        if !isFocused {
                            saveAccountName()
                        }
                    }
                    .onKeyPress(.escape) {
                        cancelAccountNameEditing()
                        return .handled
                    }
                    .onExitCommand(perform: cancelAccountNameEditing)
                    .onAppear {
                        DispatchQueue.main.async {
                            isAccountNameFocused = true
                        }
                    }
            } else {
                Button {
                    beginAccountNameEditing()
                } label: {
                    Text(displayName).fontWeight(.medium)
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
                .help("Edit account name")
                .accessibilityLabel("Edit account name: \(displayName)")
            }
        } else {
            Text(displayName).fontWeight(.medium)
        }
    }

    private var canRetry: Bool {
        !isRefreshing && profile.supportsRetry
    }

    private var canSignIn: Bool {
        !isRefreshing && profile.supportsSignIn
    }

    private var recoveryText: String? {
        switch profile.snapshotState {
        case .signingIn:
            "Finish signing in in your browser…"
        case .signInRequired:
            profile.snapshot == nil
                ? "Sign in to load quota status."
                : "Session expired. Sign in again to update this account."
        case .fresh, .cached, .refreshing, .failed:
            nil
        }
    }

    private func beginAccountNameEditing() {
        nicknameDraft = profile.nickname ?? ""
        isEditingNickname = true
    }

    private func saveAccountName() {
        guard isEditingNickname else { return }
        saveNickname(nicknameDraft)
        isEditingNickname = false
        isAccountNameFocused = false
    }

    private func cancelAccountNameEditing() {
        isEditingNickname = false
        isAccountNameFocused = false
    }

    private var statusText: String {
        switch profile.snapshotState {
        case .fresh: "Fresh snapshot"
        case .cached: "Cached snapshot"
        case .refreshing: "Refreshing…"
        case .signingIn: "Finish signing in in your browser…"
        case .signInRequired: "Sign in to load quota status."
        case .failed: "Quota status is unavailable."
        }
    }

    private func quotaLine(primary: QuotaWindow, usedPercent: Double) -> some View {
        let remaining = QuotaPresentation.remainingPercent(from: usedPercent)
        return HStack {
            StatusBadge(
                title: "\(remaining)% remaining",
                tint: QuotaPresentation.availabilityTone(forRemainingPercent: remaining).tint
            )
            Spacer()
            if let resetAt = primary.resetAt {
                Text(resetAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
        .accessibilityLabel(accessibilityLabel(for: primary, usedPercent: usedPercent, remaining: remaining))
    }

    private func codexPrimaryWindow(in snapshot: AccountSnapshot) -> QuotaWindow? {
        snapshot.buckets.first(where: { $0.id == "codex" })?.windows.first(where: { $0.kind == .primary })
    }

    private func accessibilityLabel(for primary: QuotaWindow, usedPercent: Double, remaining: Int) -> String {
        let reset = primary.resetAt.map { ", resets \($0.formatted(date: .abbreviated, time: .shortened))" } ?? ""
        return "Codex, \(remaining) percent remaining, \(Int(usedPercent.rounded())) percent used\(reset)"
    }
}

private struct StatusBadge: View {
    let title: String
    var systemImage: String? = nil
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(tint.opacity(0.2), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.42), lineWidth: 1)
        }
    }
}

private extension QuotaPresentation.AvailabilityTone {
    var tint: Color {
        switch self {
        case .abundant: .green
        case .limited: .yellow
        case .low: .orange
        }
    }
}

private extension ResetCredits.BadgeTone {
    var tint: Color {
        switch self {
        case .neutral: .gray
        case .available: .accentColor
        }
    }
}
