import SwiftUI

struct SetupStepCardView: View {
    let step: SetupStep
    var isActive: Bool = false
    var onAction: (() -> Void)?
    var onCopy: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon
                .frame(width: 22, height: 22)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(titleColor)

                statusMessage

                if isActive, let cmd = step.copyCommand {
                    Text(cmd)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .textSelection(.enabled)
                }
            }

            Spacer()

            if isActive {
                actionButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.accentColor.opacity(0.07) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.accentColor.opacity(0.3) : Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .opacity(isBlocked ? 0.5 : 1)
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var statusIcon: some View {
        switch step.status {
        case .checking:
            ProgressView()
                .scaleEffect(0.6)
        case .ok:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 18))
        case .needsAction:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.system(size: 16))
        case .blocked:
            Image(systemName: "lock.fill")
                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                .font(.system(size: 14))
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch step.status {
        case .checking:
            Text("Kontrol ediliyor…")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        case .ok(let detail):
            Text(detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        case .needsAction(let message):
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        case .blocked(let reason):
            Text(reason)
                .font(.system(size: 12))
                .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if step.canAutoFix, let label = step.actionLabel {
            Button(label) { onAction?() }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        } else if let url = step.externalURL, let label = step.actionLabel {
            Link(label, destination: url)
                .buttonStyle(.bordered)
                .controlSize(.small)
        } else if step.copyCommand != nil, let label = step.actionLabel {
            Button(label) { onCopy?() }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }

    private var isBlocked: Bool {
        if case .blocked = step.status { return true }
        return false
    }

    private var titleColor: Color {
        switch step.status {
        case .ok: return .primary
        case .needsAction: return .primary
        case .checking: return .primary
        case .blocked: return Color(nsColor: .tertiaryLabelColor)
        }
    }
}
