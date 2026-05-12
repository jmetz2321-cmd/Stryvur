import SwiftUI

struct CelebrationOverlay: View {
    let message: String
    let onDismiss: () -> Void

    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var confettiVisible = false
    @State private var trophyBounce = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 24) {
                ZStack {
                    ForEach(0..<12) { i in
                        ConfettiPiece(index: i, isVisible: confettiVisible)
                    }
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 20)
                        .scaleEffect(trophyBounce ? 1.15 : 1.0)
                }
                .frame(width: 150, height: 150)

                Text("Let's Go!")
                    .font(.title)
                    .fontWeight(.bold)

                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button {
                    FeedbackManager.light()
                    onDismiss()
                } label: {
                    Text("Keep Going")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(40)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            FeedbackManager.success()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                confettiVisible = true
            }
            // Trophy bounce
            withAnimation(.spring(response: 0.3, dampingFraction: 0.4).delay(0.3)) {
                trophyBounce = true
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.6)) {
                trophyBounce = false
            }
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let isVisible: Bool

    private var angle: Double { Double(index) * 30 }
    private var color: Color {
        [Color.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan, .mint, .indigo, .teal, .brown][index % 12]
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .offset(
                x: isVisible ? cos(angle * .pi / 180) * 70 : 0,
                y: isVisible ? sin(angle * .pi / 180) * 70 : 0
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0)
    }
}
