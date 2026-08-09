import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class PopoverLayoutState {
    private(set) var maximumHeight: CGFloat

    init(visibleScreenHeight: CGFloat) {
        maximumHeight = PopoverLayout.maximumHeight(forVisibleScreenHeight: visibleScreenHeight)
    }

    func update(visibleScreenHeight: CGFloat) {
        maximumHeight = PopoverLayout.maximumHeight(forVisibleScreenHeight: visibleScreenHeight)
    }
}

enum PopoverLayout {
    static let minimumHeight: CGFloat = 260
    // NSPopover adds roughly 26 points of arrow/chrome outside its SwiftUI content.
    // Reserve another 14 points so the outer popover does not touch the screen edge.
    static let screenEdgeMargin: CGFloat = 40

    static func maximumHeight(forVisibleScreenHeight visibleScreenHeight: CGFloat) -> CGFloat {
        max(minimumHeight, visibleScreenHeight - screenEdgeMargin)
    }
}

struct MenuBarView: View {
    @Bindable var appState: AppState
    @Bindable var popoverLayout: PopoverLayoutState
    @State private var areEmailsMasked = false
    @State private var isCLISettingsVisible = false
    @State private var profileListViewportHeight: CGFloat

    init(appState: AppState, popoverLayout: PopoverLayoutState) {
        self.appState = appState
        self.popoverLayout = popoverLayout
        _profileListViewportHeight = State(
            initialValue: Self.desiredProfileListHeight(for: appState.profiles)
        )
    }

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
                refreshActivityIndicator
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
                .frame(
                    minHeight: min(profileListViewportHeight, 80),
                    idealHeight: profileListViewportHeight,
                    maxHeight: profileListViewportHeight
                )
                .layoutPriority(-1)
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
        .frame(maxHeight: popoverLayout.maximumHeight)
        .onChange(of: appState.isCLISettingsRequested) { _, isRequested in
            if isRequested {
                isCLISettingsVisible = true
            }
        }
        .onChange(of: appState.profiles.count) {
            profileListViewportHeight = desiredProfileListHeight
        }
        .onChange(of: desiredProfileListHeight) { _, newHeight in
            guard !appState.isPopoverPresented else { return }
            profileListViewportHeight = newHeight
        }
        .onChange(of: appState.isPopoverPresented) { _, isPresented in
            guard !isPresented else { return }
            profileListViewportHeight = desiredProfileListHeight
        }
    }

    private var desiredProfileListHeight: CGFloat {
        Self.desiredProfileListHeight(for: appState.profiles)
    }

    private static func desiredProfileListHeight(for profiles: [AccountProfile]) -> CGFloat {
        profiles.reduce(CGFloat.zero) { height, profile in
            height + estimatedHeight(for: profile) + 10
        }
    }

    private static func estimatedHeight(for profile: AccountProfile) -> CGFloat {
        switch profile.snapshotState {
        case .signInRequired:
            profile.snapshot == nil ? 104 : 164
        case .signingIn:
            profile.snapshot == nil ? 92 : 140
        case .fresh, .cached, .refreshing, .failed:
            104
        }
    }

    private var refreshActivityIndicator: some View {
        ZStack {
            if appState.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Refreshing account data")
            }
        }
        .frame(width: 16, height: 16)
    }
}
