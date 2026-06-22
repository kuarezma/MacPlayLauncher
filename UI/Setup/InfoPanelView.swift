import SwiftUI

struct InfoPanelView: View {
    let step: SetupStep
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if isExpanded {
                content
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.blue)
                Text("\(step.title) hakkında")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        Text(step.explanation)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .lineSpacing(3)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
    }
}
