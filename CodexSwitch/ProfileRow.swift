import SwiftUI

struct ProfileRow: View {
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
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .layoutPriority(1)
                    .help(displayName)
                Spacer()
                if let plan = profile.snapshot?.plan { Text(plan).foregroundStyle(.secondary) }
                retryActionSlot
                Button("Remove", role: .destructive, action: remove)
                    .buttonStyle(.borderless)
                    .fixedSize()
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
            } else if recoveryMode == nil {
                Text(statusText).font(.footnote).foregroundStyle(.secondary)
            }
            if let recoveryMode {
                ProfileRecoveryCallout(
                    mode: recoveryMode,
                    isActionEnabled: canSignIn,
                    signIn: signIn
                )
            } else if let error = profile.lastError {
                Text(error).font(.footnote).foregroundStyle(.red)
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

    private var showsRetry: Bool {
        profile.supportsRetry
    }

    private var canSignIn: Bool {
        !isRefreshing && profile.supportsSignIn
    }

    private var recoveryMode: ProfileRecoveryMode? {
        switch profile.snapshotState {
        case .signingIn:
            .signingIn
        case .signInRequired:
            .signInRequired(hasCachedSnapshot: profile.snapshot != nil)
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
        case .refreshing: "Quota status is unavailable."
        case .signingIn: "Finish signing in in your browser…"
        case .signInRequired: "Sign in to load quota status."
        case .failed: "Quota status is unavailable."
        }
    }

    private var retryActionSlot: some View {
        Button("Retry", action: retry)
            .buttonStyle(.borderless)
            .disabled(!canRetry)
            .opacity(showsRetry ? 1 : 0)
            .allowsHitTesting(showsRetry)
            .accessibilityHidden(!showsRetry)
            .frame(width: 36, alignment: .trailing)
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
