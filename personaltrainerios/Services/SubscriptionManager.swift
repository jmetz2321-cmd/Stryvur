import Foundation
import StoreKit
import Observation

/// Manages subscription state via StoreKit 2.
///
/// SETUP REQUIRED BEFORE LAUNCH:
/// 1. Create your subscription products in App Store Connect:
///    - Monthly: app.stryvur.monthly — $7.99 / month (cancel anytime)
///    - Annual: app.stryvur.annual — $49.99 / year (effective $4.16 / month)
/// 2. Configure 7-day free trial introductory offer on BOTH products.
/// 3. Add a StoreKit Configuration file to the Xcode project for local testing.
/// 4. Enable In-App Purchase capability in Signing & Capabilities.
///
/// ACCESS TIERS:
/// - Trial (7 days): full access incl. AI Coach's Notes
/// - Free (post-trial): Apple Health sync, manual logging, workouts — NO AI insights
/// - Paid (monthly/annual): full access incl. AI Coach's Notes
@Observable
@MainActor
class SubscriptionManager {
    static let monthlyProductID = "app.stryvur.monthly"
    static let annualProductID = "app.stryvur.annual"
    static let monthlyDisplayPrice = "$7.99"
    static let annualDisplayPrice = "$49.99"
    static let annualEffectiveMonthly = "$4.16"
    static let trialDurationDays = 7
    static let existingUserBonusTrialDays = 30

    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading = false
    var purchaseError: String?

    /// True when the user has any active paid subscription.
    var isSubscribed: Bool {
        !purchasedProductIDs.isEmpty
    }

    // MARK: - Trial Tracking

    /// When the user first opened the app (used to detect existing users).
    var firstOpenDate: Date? {
        get {
            let ts = UserDefaults.standard.double(forKey: "firstOpenDate")
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "firstOpenDate")
            }
        }
    }

    /// When the user started their free trial.
    var trialStartDate: Date? {
        get {
            let ts = UserDefaults.standard.double(forKey: "trialStartDate")
            return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        }
        set {
            if let date = newValue {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "trialStartDate")
            } else {
                UserDefaults.standard.removeObject(forKey: "trialStartDate")
            }
        }
    }

    /// Trial length in days (7 for new users, 30 for grandfathered existing users).
    private var effectiveTrialDays: Int {
        UserDefaults.standard.integer(forKey: "trialDurationDays").nonZero ?? Self.trialDurationDays
    }

    var daysRemainingInTrial: Int {
        guard let start = trialStartDate else { return 0 }
        let elapsed = Int(Date().timeIntervalSince(start) / 86400)
        return max(0, effectiveTrialDays - elapsed)
    }

    var isInTrial: Bool {
        daysRemainingInTrial > 0
    }

    var hasExpiredTrial: Bool {
        trialStartDate != nil && daysRemainingInTrial == 0 && !isSubscribed
    }

    /// True if the user can access premium features (paid OR in trial).
    var hasFullAccess: Bool {
        isSubscribed || isInTrial
    }

    /// Call once when the user enters the app to set up trial tracking.
    func bootstrapTrial(isExistingUser: Bool) {
        if firstOpenDate == nil {
            firstOpenDate = Date()
        }
        // Auto-start a trial if they don't have one yet
        if trialStartDate == nil {
            trialStartDate = Date()
            let days = isExistingUser ? Self.existingUserBonusTrialDays : Self.trialDurationDays
            UserDefaults.standard.set(days, forKey: "trialDurationDays")
        }
    }

    /// Detects if this user installed before subscriptions launched.
    /// Uses a UserDefaults marker — set on first ever launch.
    static func isExistingUserOnFirstSubLaunch() -> Bool {
        let hasExistingMarker = UserDefaults.standard.object(forKey: "preSubscriptionUser") != nil
        if !hasExistingMarker {
            // Check if they have any prior data — indicates existing user
            let hasGoals = UserDefaults.standard.data(forKey: "savedGoals") != nil
            let hasStreak = UserDefaults.standard.data(forKey: "streakData") != nil
            let isExisting = hasGoals || hasStreak
            UserDefaults.standard.set(isExisting, forKey: "preSubscriptionUser")
            return isExisting
        }
        return UserDefaults.standard.bool(forKey: "preSubscriptionUser")
    }

    // MARK: - Lifecycle

    init() {
        Task {
            await loadProducts()
            await refreshPurchasedProducts()
        }
        _ = listenForTransactions()
    }

    // MARK: - Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: [Self.monthlyProductID, Self.annualProductID])
            products.sort { $0.price < $1.price }
        } catch {
            purchaseError = "Couldn't load subscription options."
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        purchaseError = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await refreshPurchasedProducts()
                await transaction.finish()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase is pending approval."
            @unknown default:
                break
            }
        } catch StoreError.failedVerification {
            purchaseError = "Couldn't verify your purchase."
        } catch {
            purchaseError = "Purchase failed. Try again."
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            purchaseError = "Couldn't restore purchases."
        }
    }

    // MARK: - Entitlements

    func refreshPurchasedProducts() async {
        var owned: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    owned.insert(transaction.productID)
                }
            }
        }
        purchasedProductIDs = owned
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self?.refreshPurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}
