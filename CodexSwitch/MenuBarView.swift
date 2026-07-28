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
                ForEach(snapshot.buckets) { bucket in
                    HStack {
                        Text(bucket.name ?? bucket.id)
                        Spacer()
                        Text("\(bucket.usedPercent, format: .number.precision(.fractionLength(0)))% used")
                        if let resetAt = bucket.resetAt {
                            Text(resetAt, style: .relative).foregroundStyle(.secondary)
                        }
                    }
                    .font(.footnote)
                }
                if let count = snapshot.resetCreditCount {
                    Text("Reset credits: \(count)").font(.footnote).foregroundStyle(.secondary)
                }
                Text("Updated \(snapshot.refreshedAt, style: .relative)").font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("Sign in to load quota status.").font(.footnote).foregroundStyle(.secondary)
            }
            if let error = profile.lastError {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
    }
}
