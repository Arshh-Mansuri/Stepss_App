import Foundation
import SwiftData

@Model
final class GatedAppRule {
    @Attribute(.unique) var id: UUID
    var displayName: String?
    // ApplicationToken (FamilyControls) archived to Data via NSKeyedArchiver / Codable.
    // Serialization helper lives in JJ's gating code; this layer only stores bytes.
    var applicationTokenData: Data
    var addedAt: Date
    var isActive: Bool

    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        applicationTokenData: Data,
        addedAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.displayName = displayName
        self.applicationTokenData = applicationTokenData
        self.addedAt = addedAt
        self.isActive = isActive
    }
}
