import SwiftUI

struct LibraryReadinessChecklistView: View {
    let plan: LibraryReadinessPlan
    let onAction: (LibraryReadinessAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(.title3.weight(.semibold))
                    Text(plan.message)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(plan.statusTitle)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .foregroundStyle(.white)
                    .background(plan.isReady ? Color.green : Color.red, in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(plan.steps) { step in
                    readinessStepRow(step)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func readinessStepRow(_ step: LibraryReadinessStep) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: iconName(for: step.status))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor(for: step.status))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                Text(step.message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            if let actionTitle = step.actionTitle, let action = step.action {
                Button(actionTitle) {
                    onAction(action)
                }
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func iconName(for status: LibraryReadinessStep.Status) -> String {
        switch status {
        case .complete:
            return "checkmark.circle.fill"
        case .needsAction:
            return "arrow.right.circle.fill"
        case .blocked:
            return "exclamationmark.triangle.fill"
        }
    }

    private func iconColor(for status: LibraryReadinessStep.Status) -> Color {
        switch status {
        case .complete:
            return .green
        case .needsAction:
            return .blue
        case .blocked:
            return .orange
        }
    }
}
