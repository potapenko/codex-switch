import AppKit
import SwiftUI

struct CodexCLISettingsDialog: View {
    @Bindable var appState: AppState
    let close: () -> Void
    @State private var path: String
    @State private var validationError: String?
    @State private var isSaving = false

    init(appState: AppState, close: @escaping () -> Void) {
        self.appState = appState
        self.close = close
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
                HStack {
                    Text("which -a codex")
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    Button(action: copyCommand) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .focusable(false)
                    .help("Copy command")
                    .accessibilityLabel("Copy command")
                }
                Text("Paste one of the paths it lists here, or choose the executable.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField("Path to codex", text: $path)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Codex CLI path")
                .overlay(alignment: .trailing) {
                    Button(action: pastePath) {
                        Image(systemName: "clipboard")
                    }
                    .buttonStyle(.borderless)
                    .focusable(false)
                    .padding(.trailing, 6)
                    .help("Paste path")
                    .accessibilityLabel("Paste path")
                }

            HStack {
                Button("Choose…", action: chooseExecutable)
                    .focusable(false)
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
                    close()
                }
                .focusable(false)
                Spacer()
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .focusable(false)
                    .disabled(path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
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
                close()
                await appState.completeCLIConfiguration()
            } catch {
                validationError = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func copyCommand() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("which -a codex", forType: .string)
    }

    private func pastePath() {
        guard let pastedPath = NSPasteboard.general.string(forType: .string) else { return }
        path = pastedPath.trimmingCharacters(in: .whitespacesAndNewlines)
        validationError = nil
    }
}
