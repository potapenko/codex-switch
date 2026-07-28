import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Codex accounts")
                    .font(.headline)
                Spacer()
                Button("Refresh all") {
                    Task { await appState.refreshAll() }
                }
                .disabled(appState.isRefreshing || appState.profiles.isEmpty)
            }

            if appState.profiles.isEmpty {
                ContentUnavailableView("No accounts", systemImage: "person.crop.circle.badge.plus", description: Text("Add a ChatGPT account to view its Codex quotas."))
                    .frame(width: 320, height: 150)
            } else {
                ForEach(appState.profiles) { profile in
                    ProfileRow(profile: profile)
                    if profile.id != appState.profiles.last?.id { Divider() }
                }
            }

            Divider()
            Button("Add account") {
                Task { await appState.addAccount() }
            }
            .disabled(appState.profiles.count >= 5 || appState.isRefreshing)

            if appState.profiles.count >= 5 {
                Text("Five profiles is the first-release limit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(width: 360)
    }
}

private struct ProfileRow: View {
    let profile: AccountProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(profile.label).fontWeight(.medium)
                Spacer()
                if let plan = profile.snapshot?.plan { Text(plan).foregroundStyle(.secondary) }
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
                    Text("Reset credits: \(resetCredits.availableCount)").font(.footnote).foregroundStyle(.secondary)
                }
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(QuotaPresentation.updatedText(for: snapshot.refreshedAt, now: context.date))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(statusText).font(.footnote).foregroundStyle(.secondary)
            }
            if let error = profile.lastError {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
    }

    private var statusText: String {
        switch profile.snapshotState {
        case .fresh: "Fresh snapshot"
        case .cached: "Cached snapshot"
        case .refreshing: "Refreshing…"
        case .signInRequired: "Sign in to load quota status."
        case .failed: "Quota status is unavailable."
        }
    }

    private func quotaLine(primary: QuotaWindow, usedPercent: Double) -> some View {
        let remaining = QuotaPresentation.remainingPercent(from: usedPercent)
        return HStack {
            Text("\(remaining)% remaining")
                .fontWeight(.medium)
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
