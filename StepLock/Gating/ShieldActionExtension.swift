import ManagedSettings
import Foundation

class GatingShieldActionExtension: ShieldActionDelegate {
    nonisolated override init() {
        super.init()
    }

    nonisolated override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.close)
        case .firstSecondarySubmenuItemPressed,
             .secondSecondarySubmenuItemPressed,
             .thirdSecondarySubmenuItemPressed:
            completionHandler(.none)
        @unknown default:
            completionHandler(.none)
        }
    }
}
