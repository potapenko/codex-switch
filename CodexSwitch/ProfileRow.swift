import SwiftUI

struct ProfileRow: View {
    let profile: AccountProfile
    let displayName: String
    let areEmailsMasked: Bool
    let isRefreshing: Bool
    let isRefreshingThisProfile: Bool
    let remove: () -> Void
    let refresh: () -> Void
    let signIn: () -> Void
    let saveNickname: (String) -> Void
    @State private var isEditingNickname = false
    @State private var isRemovalConfirmationPresented = false
    @State private var nicknameDraft = ""
    @FocusState private var isAccountNameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading
            if let snapshot = profile.snapshot {
                cardDivider
                snapshotContent(snapshot)
            } else if recoveryMode == nil {
                cardDivider
                Text(statusText).font(.footnote).foregroundStyle(.secondary)
            }
            if let recoveryMode {
                cardDivider
                ProfileRecoveryCallout(
                    mode: recoveryMode,
                    isActionEnabled: canSignIn,
                    signIn: signIn
                )
            } else if let error = profile.lastError {
                cardDivider
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .alert("Remove account?", isPresented: $isRemovalConfirmationPresented) {
            Button("Cancel", role: .cancel) {}
                .keyboardShortcut(.defaultAction)
            Button("Remove account", role: .destructive, action: remove)
        } message: {
            Text("Remove \(displayName) from CodexSwitch? The local dashboard entry and cached quota data will be removed. Codex sign-in data and isolated profile files will stay on this Mac.")
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
            } else if canRefresh {
                Button("Refresh account", action: refresh)
            }
        }
    }

    private var heading: some View {
        HStack(spacing: 8) {
            profileName
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(displayName)
            if let plan = profile.snapshot?.plan {
                AccountPlanBadge(title: plan)
                    .layoutPriority(1)
            }
            refreshActionSlot
            Button {
                isRemovalConfirmationPresented = true
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .frame(width: 24, height: 24)
            .help("Remove account")
            .accessibilityLabel("Remove account: \(displayName)")
            .accessibilityHint("Asks for confirmation before removing this account from CodexSwitch")
        }
    }

    @ViewBuilder
    private func snapshotContent(_ snapshot: AccountSnapshot) -> some View {
        if let primary = codexPrimaryWindow(in: snapshot), let usedPercent = primary.usedPercent {
            quotaLine(primary: primary, usedPercent: usedPercent)
        } else {
            Text("Quota unavailable")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }

        cardDivider

        HStack(spacing: 8) {
            if let resetCredits = snapshot.resetCredits {
                AccountStatusBadge(
                    title: "\(resetCredits.availableCount) resets",
                    systemImage: "arrow.counterclockwise",
                    tint: resetCredits.badgeTone.cardTint
                )
                .accessibilityLabel(resetCredits.hasAvailableCredits ? "\(resetCredits.availableCount) reset credits available" : "No reset credits available")
            }
            Spacer(minLength: 8)
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(QuotaPresentation.updatedText(for: snapshot.refreshedAt, now: context.date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var cardDivider: some View {
        Divider()
            .padding(.vertical, 8)
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

    private var canRefresh: Bool {
        !isRefreshing && profile.supportsRefresh
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

    private var refreshActionSlot: some View {
        ZStack {
            if isRefreshingThisProfile {
                ProgressView()
                    .controlSize(.small)
                    .help("Refreshing \(displayName)")
                    .accessibilityLabel("Refreshing account: \(displayName)")
            } else {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .disabled(!canRefresh)
                .frame(width: 24, height: 24)
                .help("Refresh account")
                .accessibilityLabel("Refresh account: \(displayName)")
                .accessibilityHint("Refreshes quota data for this account only")
            }
        }
        .frame(width: 24, height: 24)
    }

    private func quotaLine(primary: QuotaWindow, usedPercent: Double) -> some View {
        let remaining = QuotaPresentation.remainingPercent(from: usedPercent)
        return HStack {
            AccountStatusBadge(
                title: "\(remaining)% remaining",
                progress: Double(remaining) / 100,
                tint: QuotaPresentation.availabilityTone(forRemainingPercent: remaining).cardTint
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
