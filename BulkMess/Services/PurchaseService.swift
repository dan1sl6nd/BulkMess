import Foundation
import StoreKit

@MainActor
class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    @Published var isPurchased: Bool = false
    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle

    private let weeklyProductID = "com.bulkmess.weekly"
    private let yearlyProductID = "com.bulkmess.yearly"
    private var updatesTask: Task<Void, Never>? = nil

    enum PurchaseState: Equatable {
        case idle
        case loading
        case purchased
        case failed(Error)

        static func == (lhs: PurchaseState, rhs: PurchaseState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.purchased, .purchased):
                return true
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }

    init() {
        // Check if already purchased
        Task {
            await checkPurchaseStatus()
            await loadProducts()
        }
        // Listen for transaction updates to avoid missing purchases
        updatesTask = startTransactionListener()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [weeklyProductID, yearlyProductID])
            products = storeProducts.sorted { first, second in
                // Sort weekly first, then yearly
                if first.id == weeklyProductID { return true }
                if second.id == weeklyProductID { return false }
                return first.id < second.id
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase Management

    func purchase(_ product: Product) async {

        purchaseState = .loading

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    isPurchased = true
                    purchaseState = .purchased
                    await transaction.finish()
                case .unverified:
                    purchaseState = .failed(PurchaseError.verificationFailed)
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .failed(PurchaseError.unknown)
            }
        } catch {
            purchaseState = .failed(error)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        purchaseState = .loading

        try? await AppStore.sync()
        await checkPurchaseStatus()

        if isPurchased {
            purchaseState = .purchased
        } else {
            purchaseState = .idle
        }
    }

    // MARK: - Purchase Status Check

    private func checkPurchaseStatus() async {
        var hasPurchase = false

        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == weeklyProductID || transaction.productID == yearlyProductID {
                    hasPurchase = true
                }
            case .unverified:
                break
            }
        }

        isPurchased = hasPurchase
    }

    // MARK: - Transaction Updates Listener
    private func startTransactionListener() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    await handleVerifiedTransaction(transaction)
                case .unverified:
                    continue
                }
            }
        }
    }

    @MainActor
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.productID == weeklyProductID || transaction.productID == yearlyProductID {
            isPurchased = true
            purchaseState = .purchased
        }
        await transaction.finish()
    }
}

// MARK: - Errors

enum PurchaseError: Error, LocalizedError {
    case productNotFound
    case verificationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .verificationFailed:
            return "Purchase verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
