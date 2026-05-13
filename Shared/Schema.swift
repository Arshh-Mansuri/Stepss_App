import Foundation
import SwiftData

enum AppSchemaV1 {
    static let version = 1

    static let models: [any PersistentModel.Type] = [
        Wallet.self,
        EarnTransaction.self,
        SpendTransaction.self,
        GatedAppRule.self,
        UnlockWindow.self,
        AppSettings.self,
    ]
}
