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
                        Text("Try Stryvur Free")
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

                    // Product picker (with hardcoded fallback display)
                    if subscriptionManager.isLoading {
                        ProgressView()
                            .padding()
                    } else if subscriptionManager.products.isEmpty {
                        VStack(spacing: 10) {
                            fallbackProductOption(isAnnual: true)
                            fallbackProductOption(isAnnual: false)
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(subscriptionManager.products, id: \.id) { product in
                                productOption(product)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // After-trial explainer
                    postTrialExplainer
                        .padding(.horizontal)

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

                    Text("No charge for 7 days. Cancel anytime in Settings before then. After the trial, you'll be billed at the price you selected unless cancelled.")
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
        return optionCard(
            isSelected: isSelected,
            isAnnual: isAnnual,
            price: product.displayPrice,
            cadence: isAnnual ? "/ year" : "/ month",
            secondaryPrice: isAnnual ? "\(SubscriptionManager.annualEffectiveMonthly) / month, billed annually" : "Cancel anytime",
            action: {
                FeedbackManager.light()
                selectedProduct = product
            }
        )
    }

    private func fallbackProductOption(isAnnual: Bool) -> some View {
        optionCard(
            isSelected: isAnnual ? (selectedProduct == nil) : false,
            isAnnual: isAnnual,
            price: isAnnual ? SubscriptionManager.annualDisplayPrice : SubscriptionManager.monthlyDisplayPrice,
            cadence: isAnnual ? "/ year" : "/ month",
            secondaryPrice: isAnnual ? "\(SubscriptionManager.annualEffectiveMonthly) / month, billed annually" : "Cancel anytime",
            action: {}
        )
        .opacity(0.6)
        .accessibilityLabel("Subscription unavailable, check connection")
    }

    private func optionCard(isSelected: Bool, isAnnual: Bool, price: String, cadence: String, secondaryPrice: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
                            Text("Save 48%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.green, in: Capsule())
                        }
                    }
                    Text(secondaryPrice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                    Text(cadence)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var postTrialExplainer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("After your 7-day trial")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Paid", systemImage: "sparkles")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.purple)
                    Text("AI Coach's Notes")
                        .font(.caption)
                    Text("Adaptive workouts")
                        .font(.caption)
                    Text("Personalized nutrition")
                        .font(.caption)
                    Text("All Apple Health insights")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label("Free", systemImage: "person")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("Apple Health sync")
                        .font(.caption)
                    Text("Manual logging")
                        .font(.caption)
                    Text("Workout history")
                        .font(.caption)
                    Text("No AI Coach insights")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
