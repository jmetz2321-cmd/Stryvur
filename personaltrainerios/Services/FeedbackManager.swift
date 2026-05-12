import UIKit

enum FeedbackManager {
    /// Light tap — toggles, expand/collapse, navigation
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Medium tap — workout complete, water added, meal checked
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Soft tap — subtle interactions, button presses
    static func soft() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Success — milestone hit, target met, level up
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Warning — streak at risk, over calorie target
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    /// Error — action failed
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
