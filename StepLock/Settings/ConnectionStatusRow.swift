import SwiftUI

enum ConnectionState: Equatable {
    case checking
    case connected(detail: String)
    case warning(detail: String)
    case failed(detail: String)

    var color: Color {
        switch self {
        case .checking: return DS.Color.gray400
        case .connected: return DS.Color.teal400
        case .warning: return Color.orange
        case .failed: return DS.Color.red600
        }
    }

    var icon: String {
        switch self {
        case .checking: return "ellipsis.circle"
        case .connected: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .checking: return "Checking…"
        case .connected(let detail): return detail
        case .warning(let detail): return detail
        case .failed(let detail): return detail
        }
    }
}

struct ConnectionStatusRow: View {
    let title: String
    let subtitle: String
    let symbol: String
    let symbolBg: Color
    let state: ConnectionState

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(symbolBg)
                    .frame(width: 36, height: 36)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.gray900)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Color.gray400)
            }

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: state.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(state.label)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(state.color)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}
