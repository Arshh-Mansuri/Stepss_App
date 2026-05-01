import Foundation
import SwiftData

@Model
final class Wallet {
    var balance: Int
    var updatedAt: Date

    init(balance: Int = 0, updatedAt: Date = .now) {
        self.balance = balance
        self.updatedAt = updatedAt
    }
}
