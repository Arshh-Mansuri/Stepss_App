import ManagedSettings
import ManagedSettingsUI
@preconcurrency import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private nonisolated static let unlockCost15 = 500
    private nonisolated static let unlockCost30 = 900
    private nonisolated static let unlockCost60 = 1_600

    private nonisolated static let balanceKey = "wallet.balance"
    private nonisolated static let todayStepsKey = "TodaySteps"

    nonisolated override init() {
        super.init()
    }

    nonisolated override func configuration(shielding application: Application) -> ShieldConfiguration {
        createShieldConfig(title: "This app is gated")
    }

    nonisolated override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfig(title: "Category is gated")
    }

    private nonisolated func createShieldConfig(title: String) -> ShieldConfiguration {
        let defaults = AppGroup.sharedDefaults
        let balance = defaults.integer(forKey: Self.balanceKey)
        let steps = defaults.integer(forKey: Self.todayStepsKey)
        let hasEnoughPoints = balance >= Self.unlockCost15

        let subtitleText: String
        if hasEnoughPoints {
            subtitleText = """
            You have enough points to unlock. Open StepLock to spend them.

            BALANCE
            \(balance.formatted()) pts

            TODAY'S STEPS
            \(steps.formatted())

            CAN UNLOCK
            15 min  \(Self.unlockCost15) pts
            30 min  \(Self.unlockCost30) pts
            60 min  \(Self.unlockCost60) pts

            Transaction happens in StepLock, not here.
            """
        } else {
            let remaining = max(0, Self.unlockCost15 - balance)
            let progressText = progressLine(balance: balance, cost: Self.unlockCost15)

            subtitleText = """
            Walk more to earn points, then spend them for screen time.

            BALANCE
            \(balance.formatted()) pts

            TODAY'S STEPS
            \(steps.formatted())

            To 15 min unlock
            \(balance.formatted()) / \(Self.unlockCost15.formatted()) pts
            \(progressText)

            \(remaining.formatted()) more pts needed for 15 min
            """
        }

        return ShieldConfiguration(
            backgroundBlurStyle: .dark,
            backgroundColor: UIColor(hex: "#0F0E1A"),
            title: ShieldConfiguration.Label(
                text: title,
                color: UIColor(hex: "#F0EFFE")
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitleText,
                color: UIColor(hex: "#9B95D4")
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: hasEnoughPoints ? "Open StepLock to spend ->" : "Open StepLock ->",
                color: UIColor(hex: "#26215C")
            ),
            primaryButtonBackgroundColor: UIColor(hex: "#CECBF6"),
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Go back",
                color: UIColor(hex: "#9B95D4")
            )
        )
    }

    private nonisolated func progressLine(balance: Int, cost: Int) -> String {
        let segmentCount = 12
        let clampedBalance = max(0, min(balance, cost))
        let filledCount = Int((Double(clampedBalance) / Double(cost) * Double(segmentCount)).rounded(.down))
        let filled = String(repeating: "=", count: filledCount)
        let empty = String(repeating: "-", count: segmentCount - filledCount)
        return "[\(filled)\(empty)]"
    }
}

extension UIColor {
    convenience init(hex: String) {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}
