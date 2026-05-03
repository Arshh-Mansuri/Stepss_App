import SwiftUI

// Tokens mirror steplock_mockups_v3.html. Update both together.
enum DS {
    enum Color {
        // Earn — Teal
        static let teal50  = SwiftUI.Color(red: 0.882, green: 0.961, blue: 0.933)
        static let teal400 = SwiftUI.Color(red: 0.114, green: 0.620, blue: 0.459)
        static let teal600 = SwiftUI.Color(red: 0.059, green: 0.431, blue: 0.337)
        static let teal900 = SwiftUI.Color(red: 0.016, green: 0.204, blue: 0.173)

        // Spend — Purple
        static let purple50  = SwiftUI.Color(red: 0.933, green: 0.929, blue: 0.996)
        static let purple100 = SwiftUI.Color(red: 0.808, green: 0.796, blue: 0.965)
        static let purple200 = SwiftUI.Color(red: 0.686, green: 0.663, blue: 0.925)
        static let purple400 = SwiftUI.Color(red: 0.498, green: 0.467, blue: 0.867)
        static let purple600 = SwiftUI.Color(red: 0.325, green: 0.290, blue: 0.718)
        static let purple800 = SwiftUI.Color(red: 0.235, green: 0.204, blue: 0.537)
        static let purple900 = SwiftUI.Color(red: 0.149, green: 0.129, blue: 0.361)

        // Neutrals
        static let gray0   = SwiftUI.Color.white
        static let gray50  = SwiftUI.Color(red: 0.961, green: 0.957, blue: 0.945)
        static let gray100 = SwiftUI.Color(red: 0.933, green: 0.925, blue: 0.918)
        static let gray200 = SwiftUI.Color(red: 0.839, green: 0.831, blue: 0.808)
        static let gray400 = SwiftUI.Color(red: 0.604, green: 0.596, blue: 0.573)
        static let gray600 = SwiftUI.Color(red: 0.361, green: 0.357, blue: 0.341)
        static let gray800 = SwiftUI.Color(red: 0.165, green: 0.165, blue: 0.157)
        static let gray900 = SwiftUI.Color(red: 0.094, green: 0.094, blue: 0.086)

        static let red50  = SwiftUI.Color(red: 0.988, green: 0.922, blue: 0.922)
        static let red600 = SwiftUI.Color(red: 0.639, green: 0.176, blue: 0.176)

        // Shield — always dark (extension uses these directly)
        static let shieldBg      = SwiftUI.Color(red: 0.059, green: 0.055, blue: 0.102)
        static let shieldSurface = SwiftUI.Color(red: 0.102, green: 0.094, blue: 0.157)
        static let shieldText    = SwiftUI.Color(red: 0.941, green: 0.937, blue: 0.996)
        static let shieldMuted   = SwiftUI.Color(red: 0.608, green: 0.584, blue: 0.831)
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
