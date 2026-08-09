import SwiftUI

enum ProfileRecoveryMode: Equatable {
    case signInRequired(hasCachedSnapshot: Bool)
    case signingIn
}

struct ProfileRecoveryCallout: View {
    let mode: ProfileRecoveryMode
    let signIn: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            switch mode {
            case let .signInRequired(hasCachedSnapshot):
                signInRequiredContent(hasCachedSnapshot: hasCachedSnapshot)
            case .signingIn:
                signingInContent
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.16 : 0.09))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.orange.opacity(colorScheme == .dark ? 0.55 : 0.38), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func signInRequiredContent(hasCachedSnapshot: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sign-in required")
                    .font(.subheadline.weight(.semibold))
                Text(explanation(hasCachedSnapshot: hasCachedSnapshot))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)

            Spacer(minLength: 6)

            Button("Sign in again", action: signIn)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(.orange)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityHint("Opens the browser sign-in for this account")
        }
    }

    private var signingInContent: some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .tint(.orange)
                .accessibilityHidden(true)
            Text("Finish signing in in your browser…")
                .font(.subheadline.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Finish signing in in your browser")
    }

    private func explanation(hasCachedSnapshot: Bool) -> String {
        if hasCachedSnapshot {
            return "Reconnect this account to refresh its quota. Cached data stays visible."
        }
        return "Connect this account to load its Codex quota."
    }
}
