import SwiftUI

struct UndoToast: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    @State private var timeRemaining = 4

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(2)
            Spacer()
            Button {
                onUndo()
            } label: {
                Text("Undo")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            }
            .accessibilityLabel("Undo workout completion")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .onAppear {
            startCountdown()
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            timeRemaining -= 1
            if timeRemaining <= 0 {
                timer.invalidate()
                onDismiss()
            }
        }
    }
}
