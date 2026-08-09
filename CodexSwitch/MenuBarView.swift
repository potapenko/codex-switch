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
            height + estimatedHeight(for: profile)
        }
        return min(contentHeight, 620)
    }

    private func estimatedHeight(for profile: AccountProfile) -> CGFloat {
        switch profile.snapshotState {
        case .signInRequired:
            profile.snapshot == nil ? 138 : 174
        case .signingIn:
            profile.snapshot == nil ? 92 : 140
        case .fresh, .cached, .refreshing, .failed:
            104
        }
    }
}
