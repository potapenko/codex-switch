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
    static let minimumListViewportHeight: CGFloat = 80
    static let profileRowVerticalPadding: CGFloat = 6
    // NSPopover adds roughly 26 points of arrow/chrome outside its SwiftUI content.
    // Reserve another 14 points so the outer popover does not touch the screen edge.
    static let screenEdgeMargin: CGFloat = 40

    static func maximumHeight(forVisibleScreenHeight visibleScreenHeight: CGFloat) -> CGFloat {
        max(minimumHeight, visibleScreenHeight - screenEdgeMargin)
    }

    static func measuredListContentHeight(
        profileIDs: [UUID],
        rowHeights: [UUID: CGFloat]
    ) -> CGFloat? {
        guard !profileIDs.isEmpty else { return 0 }
        var total: CGFloat = 0
        for profileID in profileIDs {
            guard let height = rowHeights[profileID], height > 0 else { return nil }
            total += height
        }
        return total
    }
}

private struct ProfileRowHeightPreferenceKey: PreferenceKey {
    static let defaultValue: [UUID: CGFloat] = [:]

    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

struct MenuBarView: View {
    @Bindable var appState: AppState
    @Bindable var popoverLayout: PopoverLayoutState
    @State private var areEmailsMasked = false
    @State private var isCLISettingsVisible = false
    @State private var measuredProfileRowHeights: [UUID: CGFloat] = [:]

    init(appState: AppState, popoverLayout: PopoverLayoutState) {
        self.appState = appState
        self.popoverLayout = popoverLayout
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
                        .padding(.vertical, PopoverLayout.profileRowVerticalPadding)
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ProfileRowHeightPreferenceKey.self,
                                    value: [profile.id: geometry.size.height]
                                )
                            }
                        }
                        .listRowInsets(EdgeInsets())
                    }
                    .onMove { sourceOffsets, destination in
                        appState.moveAccounts(from: sourceOffsets, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(
                    minHeight: min(
                        profileListViewportHeight,
                        PopoverLayout.minimumListViewportHeight
                    ),
                    idealHeight: profileListViewportHeight,
                    maxHeight: profileListViewportHeight
                )
                .layoutPriority(-1)
                .onPreferenceChange(ProfileRowHeightPreferenceKey.self) { rowHeights in
                    let profileIDs = Set(appState.profiles.map(\.id))
                    let currentRowHeights = rowHeights.filter {
                        profileIDs.contains($0.key) && $0.value > 0
                    }
                    guard measuredProfileRowHeights != currentRowHeights else { return }
                    measuredProfileRowHeights = currentRowHeights
                }
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
    }

    private var profileListViewportHeight: CGFloat {
        PopoverLayout.measuredListContentHeight(
            profileIDs: appState.profiles.map(\.id),
            rowHeights: measuredProfileRowHeights
        ) ?? popoverLayout.maximumHeight
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
