import Foundation
import SwiftUI
import Observation

enum AppearancePreference: String, CaseIterable, Codable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    /// nil means "follow system" — SwiftUI inherits the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@MainActor
@Observable
final class AppearanceStore {
    static let shared = AppearanceStore()

    var preference: AppearancePreference {
        didSet {
            defaults.set(preference.rawValue, forKey: storageKey)
        }
    }

    private let defaults: UserDefaults
    private let storageKey = "appearance.preference"

    init(defaults: UserDefaults = AppGroup.sharedDefaults) {
        self.defaults = defaults
        if let raw = defaults.string(forKey: storageKey),
           let pref = AppearancePreference(rawValue: raw) {
            self.preference = pref
        } else {
            self.preference = .system
        }
    }
}
