import SwiftUI

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Accent pair

struct AccentPair: Hashable {
    let tint: Color   // soft pastel background
    let ink: Color    // saturated foreground / icon / line color
}

// MARK: - Theme

enum Theme {
    enum Palette {
        // Surfaces — warm off-whites
        static let canvas       = Color(hex: 0xFBF9F4)
        static let surface      = Color(hex: 0xFFFFFF)
        static let surfaceMuted = Color(hex: 0xF3F0E8)
        static let surfaceSunk  = Color(hex: 0xEEEAE0)
        static let hairline     = Color.black.opacity(0.06)
        static let hairlineSoft = Color.black.opacity(0.04)

        // Ink (text)
        static let ink       = Color(hex: 0x1A1A1A)
        static let inkSoft   = Color.black.opacity(0.62)
        static let inkMuted  = Color.black.opacity(0.38)
        static let inkFaint  = Color.black.opacity(0.22)

        // Pastel accents
        static let peach   = AccentPair(tint: Color(hex: 0xFFE3D1), ink: Color(hex: 0xB8541A))
        static let mint    = AccentPair(tint: Color(hex: 0xD4F0DA), ink: Color(hex: 0x2A6B3A))
        static let lilac   = AccentPair(tint: Color(hex: 0xE6DEF7), ink: Color(hex: 0x5A3FA8))
        static let sky     = AccentPair(tint: Color(hex: 0xD6E8F7), ink: Color(hex: 0x1F5A8A))
        static let butter  = AccentPair(tint: Color(hex: 0xFAEFC8), ink: Color(hex: 0x8A6A1F))
        static let blush   = AccentPair(tint: Color(hex: 0xFAD9DD), ink: Color(hex: 0xA83A4A))
        static let sage    = AccentPair(tint: Color(hex: 0xDCE8DC), ink: Color(hex: 0x4A6B4A))
        static let neutral = AccentPair(tint: Color(hex: 0xEAE6DC), ink: Color(hex: 0x5C5648))

        static let allAccents: [AccentPair] = [peach, mint, lilac, sky, butter, blush, sage]

        // Semantic — section accents
        static let dashboard  = lilac
        static let workstream = sky
        static let allNotes   = sage
        static let journal    = peach
        static let tasks      = mint
        static let tickets    = blush
        static let history    = butter
        static let topic      = neutral

        // Series colors used by charts (rotation order)
        static let chartSeries: [Color] = [
            lilac.ink, sky.ink, peach.ink, mint.ink, butter.ink, blush.ink, sage.ink
        ]
    }

    enum Radius {
        static let pill: CGFloat = 999
        static let chip: CGFloat = 8
        static let card: CGFloat = 20
        static let cardLarge: CGFloat = 28
        static let cardSmall: CGFloat = 12
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Typo {
        static let display     = Font.system(size: 44, weight: .bold,     design: .rounded)
        static let title       = Font.system(size: 28, weight: .semibold, design: .default)
        static let cardTitle   = Font.system(size: 17, weight: .semibold)
        static let sectionHead = Font.system(size: 11, weight: .semibold, design: .default)
        static let body        = Font.system(size: 14, weight: .regular)
        static let bodyMedium  = Font.system(size: 14, weight: .medium)
        static let label       = Font.system(size: 12, weight: .medium)
        static let caption     = Font.system(size: 11, weight: .medium)
        static let mono        = Font.system(size: 11, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Status / Priority → AccentPair

extension TicketStatus {
    var accent: AccentPair {
        switch self {
        case .open:       return Theme.Palette.sky
        case .inProgress: return Theme.Palette.butter
        case .blocked:    return Theme.Palette.blush
        case .closed:     return Theme.Palette.sage
        }
    }

    var displayLabel: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .blocked: return "Blocked"
        case .closed: return "Closed"
        }
    }
}

extension Priority {
    var accent: AccentPair {
        switch self {
        case .low:      return Theme.Palette.sage
        case .medium:   return Theme.Palette.sky
        case .high:     return Theme.Palette.peach
        case .critical: return Theme.Palette.blush
        }
    }
}
