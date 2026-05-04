import SwiftUI
import UIKit

// Tokens mirror steplock_mockups_v3.html (light values) plus a hand-tuned
// dark variant per token. Each color is a UIColor dynamicProvider wrapped
// in Color, so views automatically pick the right shade based on the
// current trait collection. No view-side colorScheme switching needed.
enum DS {
    enum Color {
        // Earn — Teal
        static let teal50  = dyn(0.882, 0.961, 0.933,  0.04, 0.16, 0.13)
        static let teal400 = dyn(0.114, 0.620, 0.459,  0.20, 0.74, 0.57)   // brighter in dark for accent contrast
        static let teal600 = dyn(0.059, 0.431, 0.337,  0.40, 0.84, 0.70)
        static let teal900 = dyn(0.016, 0.204, 0.173,  0.84, 0.96, 0.91)   // inverts for "headline on teal bg"

        // Spend — Purple
        static let purple50  = dyn(0.933, 0.929, 0.996,  0.13, 0.12, 0.22)
        static let purple100 = dyn(0.808, 0.796, 0.965,  0.20, 0.18, 0.32)
        static let purple200 = dyn(0.686, 0.663, 0.925,  0.36, 0.33, 0.55)
        static let purple400 = dyn(0.498, 0.467, 0.867,  0.62, 0.58, 0.92)   // brighter for dark contrast
        static let purple600 = dyn(0.325, 0.290, 0.718,  0.55, 0.50, 0.95)
        static let purple800 = dyn(0.235, 0.204, 0.537,  0.71, 0.66, 0.95)
        static let purple900 = dyn(0.149, 0.129, 0.361,  0.86, 0.83, 0.97)   // inverts for "headline on purple bg"

        // Neutrals
        static let gray0   = dyn(1.00, 1.00, 1.00,  0.07, 0.07, 0.08)        // app background
        static let gray50  = dyn(0.961, 0.957, 0.945,  0.11, 0.11, 0.12)     // card background
        static let gray100 = dyn(0.933, 0.925, 0.918,  0.16, 0.16, 0.17)
        static let gray200 = dyn(0.839, 0.831, 0.808,  0.27, 0.27, 0.29)     // borders / dividers
        static let gray400 = dyn(0.604, 0.596, 0.573,  0.55, 0.54, 0.55)     // muted text
        static let gray600 = dyn(0.361, 0.357, 0.341,  0.74, 0.73, 0.74)
        static let gray800 = dyn(0.165, 0.165, 0.157,  0.91, 0.91, 0.92)
        static let gray900 = dyn(0.094, 0.094, 0.086,  0.98, 0.98, 0.98)     // primary text

        static let red50  = dyn(0.988, 0.922, 0.922,  0.30, 0.10, 0.10)
        static let red600 = dyn(0.639, 0.176, 0.176,  0.96, 0.40, 0.40)

        // Shield (always dark — never adapts; matches spec for the extension UI)
        static let shieldBg      = SwiftUI.Color(red: 0.059, green: 0.055, blue: 0.102)
        static let shieldSurface = SwiftUI.Color(red: 0.102, green: 0.094, blue: 0.157)
        static let shieldText    = SwiftUI.Color(red: 0.941, green: 0.937, blue: 0.996)
        static let shieldMuted   = SwiftUI.Color(red: 0.608, green: 0.584, blue: 0.831)

        /// Dynamic color helper. Returns a SwiftUI Color whose underlying UIColor
        /// resolves to the light or dark RGB based on the current user interface style.
        private static func dyn(_ lr: Double, _ lg: Double, _ lb: Double,
                                _ dr: Double, _ dg: Double, _ db: Double) -> SwiftUI.Color {
            SwiftUI.Color(uiColor: UIColor { trait in
                trait.userInterfaceStyle == .dark
                    ? UIColor(red: dr, green: dg, blue: db, alpha: 1)
                    : UIColor(red: lr, green: lg, blue: lb, alpha: 1)
            })
        }
    }

    enum Radius {
        static let r6: CGFloat = 6
        static let r10: CGFloat = 10
        static let r12: CGFloat = 12
        static let r14: CGFloat = 14
        static let r20: CGFloat = 20
        static let r28: CGFloat = 28
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let edge: CGFloat = 20  // screen edge inset
    }

    enum Font {
        static let heroValue   = SwiftUI.Font.system(size: 26, weight: .heavy).leading(.tight)
        static let onboardH    = SwiftUI.Font.system(size: 28, weight: .heavy).leading(.tight)
        static let screenH     = SwiftUI.Font.system(size: 22, weight: .bold)
        static let navTitle    = SwiftUI.Font.system(size: 17, weight: .semibold)
        static let cardTitle   = SwiftUI.Font.system(size: 15, weight: .semibold)
        static let body        = SwiftUI.Font.system(size: 15, weight: .regular)
        static let bodyStrong  = SwiftUI.Font.system(size: 15, weight: .medium)
        static let caption     = SwiftUI.Font.system(size: 12, weight: .regular)
        static let captionMeta = SwiftUI.Font.system(size: 11, weight: .regular)
        static let sectionLabel = SwiftUI.Font.system(size: 11, weight: .bold)
    }
}

// MARK: - Button styles

struct DSPrimaryButtonStyle: ButtonStyle {
    var background: Color = DS.Color.purple600
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.r14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct DSGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(DS.Color.gray400)
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
