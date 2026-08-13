import SwiftUI

struct AccountPlanBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.1), in: Capsule())
    }
}

struct AccountStatusBadge: View {
    let title: String
    var systemImage: String? = nil
    var progress: Double? = nil
    let tint: Color

    var body: some View {
        HStack(spacing: 5) {
            if let progress {
                AccountAvailabilityRing(progress: progress, tint: tint)
                    .accessibilityHidden(true)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(title)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.17), in: Capsule())
        .overlay {
            Capsule()
                .stroke(tint.opacity(0.38), lineWidth: 1)
        }
    }
}

private struct AccountAvailabilityRing: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.24), lineWidth: 2)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 12, height: 12)
    }
}

extension QuotaPresentation.AvailabilityTone {
    var cardTint: Color {
        switch self {
        case .abundant: .green
        case .limited: .yellow
        case .low: .orange
        }
    }
}

extension ResetCredits.BadgeTone {
    var cardTint: Color {
        switch self {
        case .neutral: .gray
        case .available: .accentColor
        }
    }
}
