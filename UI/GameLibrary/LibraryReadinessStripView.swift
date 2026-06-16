import SwiftUI

struct LibraryReadinessStripView: View {
    let result: RunReadinessResult
    let openDiagnostics: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(localized: "library.readiness.title"))
                    .font(.headline)

                Spacer()

                Text(badgeText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(.white)
                    .background(badgeColor, in: Capsule())
            }

            Text(result.title)
                .font(.subheadline.weight(.semibold))

            Text(result.message)
                .foregroundStyle(.secondary)

            Button(String(localized: "library.readiness.openDiagnostics"), action: openDiagnostics)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: String(localized: "accessibility.libraryReadinessStrip"),
                result.title,
                result.message
            )
        )
    }

    private var badgeText: String {
        switch result.status {
        case .ready:
            return String(localized: "readiness.ready.title")
        case .blocked:
            return String(localized: "readiness.blocked.title")
        case .unknown:
            return String(localized: "readiness.unknown.title")
        case .unsupported:
            return String(localized: "readiness.unsupported.title")
        }
    }

    private var badgeColor: Color {
        switch result.status {
        case .ready:
            return .green
        case .blocked, .unsupported:
            return .red
        case .unknown:
            return .orange
        }
    }
}
