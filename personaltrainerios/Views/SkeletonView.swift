import SwiftUI

/// A shimmering placeholder for content that's still loading.
/// Used in DashboardView while health data syncs.
struct SkeletonView: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    @State private var shimmer = false

    init(height: CGFloat = 80, cornerRadius: CGFloat = 12) {
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5),
                    ],
                    startPoint: shimmer ? .trailing : .leading,
                    endPoint: shimmer ? .leading : .trailing
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                    shimmer.toggle()
                }
            }
            .accessibilityHidden(true)
    }
}

/// Skeleton placeholder for the health metrics horizontal row.
struct HealthSkeletonRow: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    SkeletonView(height: 80, cornerRadius: 12)
                        .frame(width: 80)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// Skeleton placeholder for a generic card.
struct CardSkeleton: View {
    let height: CGFloat

    init(height: CGFloat = 120) {
        self.height = height
    }

    var body: some View {
        SkeletonView(height: height, cornerRadius: 16)
    }
}
