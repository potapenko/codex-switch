import AppKit
import SwiftUI

struct CodexCLISettingsDialog: View {
    @Bindable var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var path: String
    @State private var validationError: String?
    @State private var isSaving = false

    init(appState: AppState) {
        self.appState = appState
        _path = State(initialValue: appState.codexCLIPath ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Codex CLI")
                .font(.headline)
            Text("Choose the `codex` executable installed on this Mac. CodexSwitch uses it for account sign-in and quota refreshes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Need to find it? In Terminal, run:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("command -v codex")
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                Text("Paste the path it prints here, or choose the executable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField("Path to codex", text: $path)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Codex CLI path")

            HStack {
                Button("Choose…", action: chooseExecutable)
                Spacer()
                if isSaving {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let validationError {
                Text(validationError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") {
                    appState.dismissCLISettingsRequest()
                    dismiss()
                }
                Spacer()
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func chooseExecutable() {
        let panel = NSOpenPanel()
        panel.title = "Choose Codex CLI"
        panel.message = "Select the `codex` executable installed on this Mac."
        panel.prompt = "Choose"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let expandedPath = (path as NSString).expandingTildeInPath
            panel.directoryURL = URL(fileURLWithPath: expandedPath).deletingLastPathComponent()
        }
        guard panel.runModal() == .OK, let url = panel.url else { return }
        path = url.path
        validationError = nil
    }

    private func save() {
        validationError = nil
        isSaving = true
        Task {
            do {
                try await appState.configureCodexCLI(path: path)
                dismiss()
                await appState.completeCLIConfiguration()
            } catch {
                validationError = error.localizedDescription
            }
            isSaving = false
        }
    }
}
