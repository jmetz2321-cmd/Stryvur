import SwiftUI
import StoreKit

struct PaywallView: View {
    var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Image(systemName: "sparkles")
                                .font(.system(size: 36))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                        }
                        Text("Try Longivor Free")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("7 days free, then pick a plan. Cancel anytime.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 8)

                    // Features
                    VStack(alignment: .leading, spacing: 14) {
                        featureRow("brain.head.profile.fill", .purple,
                                   "AI Coach's Notes that adapt in real time")
                        featureRow("figure.run", .blue,
                                   "Personalized workouts that flex with your energy and recovery")
                        featureRow("fork.knife", .orange,
                                   "Nutrition plan that adjusts to your goals and activity")
                        featureRow("heart.fill", .red,
                                   "Apple Health sync with intelligent insights")
                        featureRow("flame.fill", .orange,
                                   "Streaks, rewards, and progress tracking")
                        featureRow("clock.arrow.circlepath", .indigo,
                                   "Full workout history, always saved")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Product picker
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if subscriptionManager.products.isEmpty {
                        Text("Subscriptions unavailable. Check your connection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                productOption(product)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // CTA
                    Button {
                        guard let product = selectedProduct ?? subscriptionManager.products.last else { return }
                        FeedbackManager.medium()
                        Task { await subscriptionManager.purchase(product) }
                    } label: {
                        Text("Start 7-Day Free Trial")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal)
                    .disabled(subscriptionManager.products.isEmpty)

                    Text("No charge for 7 days. Cancel anytime in Settings before then to avoid being charged.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Restore + legal
                    HStack(spacing: 24) {
                        Button("Restore") {
                            Task { await subscriptionManager.restorePurchases() }
                        }
                        .font(.caption)
                        Text("\u{2022}")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                        Text("Cancel anytime in iOS Settings")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let err = subscriptionManager.purchaseError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
            }
            .onAppear {
                selectedProduct = subscriptionManager.products.last  // default to annual (cheaper per month)
            }
            .onChange(of: subscriptionManager.isSubscribed) { _, subscribed in
                if subscribed { dismiss() }
            }
        }
    }

    private func featureRow(_ icon: String, _ color: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 28)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }

    private func productOption(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isAnnual = product.id.contains("annual")
        return Button {
            FeedbackManager.light()
            selectedProduct = product
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : Color(.systemGray3))
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(isAnnual ? "Annual" : "Monthly")
                            .font(.headline)
                        if isAnnual {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.green, in: Capsule())
                        }
                    }
                    Text(product.displayPrice + (isAnnual ? " / year" : " / month"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(isAnnual ? "Annual" : "Monthly") subscription, \(product.displayPrice)\(isAnnual ? " per year" : " per month")\(isSelected ? ", selected" : "")")
    }
}
