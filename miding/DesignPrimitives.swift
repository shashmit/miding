import SwiftUI

// MARK: - PastelCard

enum CardStyle {
    case elevated      // raised white surface with soft shadow
    case recessed      // muted surface, no shadow
    case accent(AccentPair) // tinted pastel background
    case plain         // surface only, hairline border

    var radius: CGFloat { Theme.Radius.card }
}

struct PastelCard<Content: View>: View {
    var style: CardStyle = .elevated
    var radius: CGFloat? = nil
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        let r = radius ?? style.radius
        content
            .padding(padding)
            .background(background(radius: r))
            .overlay(
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
            )
            .modifier(CardShadowModifier(style: style))
    }

    @ViewBuilder
    private func background(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        switch style {
        case .elevated, .plain:
            shape.fill(Theme.Palette.surface)
        case .recessed:
            shape.fill(Theme.Palette.surfaceMuted)
        case .accent(let pair):
            shape.fill(pair.tint)
        }
    }
}

private struct CardShadowModifier: ViewModifier {
    let style: CardStyle
    func body(content: Content) -> some View {
        switch style {
        case .elevated:
            content
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
        case .accent:
            content.shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
        case .recessed, .plain:
            content
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var accent: AccentPair? = nil
    var trailing: AnyView? = nil

    init(_ title: String, accent: AccentPair? = nil, @ViewBuilder trailing: () -> some View = { EmptyView() }) {
        self.title = title
        self.accent = accent
        self.trailing = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: 8) {
            if let accent {
                Circle().fill(accent.ink).frame(width: 6, height: 6)
            }
            Text(title.uppercased())
                .font(Theme.Typo.sectionHead)
                .tracking(1.2)
                .foregroundStyle(Theme.Palette.inkSoft)
            Spacer()
            trailing
        }
    }
}

// MARK: - IconBadge

struct IconBadge: View {
    let symbol: String
    let accent: AccentPair
    var size: CGFloat = 28
    var symbolSize: CGFloat = 13

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(accent.tint)
            Image(systemName: symbol)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(accent.ink)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Pill

enum PillStyle {
    case filled    // accent.ink fill, white text
    case tinted    // accent.tint fill, accent.ink text (default)
    case outline   // surface fill, hairline border, ink text
    case ghost     // transparent, ink text
}

struct Pill: View {
    let text: String
    var icon: String? = nil
    var accent: AccentPair = Theme.Palette.neutral
    var style: PillStyle = .tinted
    var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: size - 2, weight: .semibold))
            }
            Text(text)
                .font(.system(size: size, weight: .semibold))
        }
        .foregroundStyle(textColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(background)
    }

    private var textColor: Color {
        switch style {
        case .filled: return .white
        case .tinted, .outline, .ghost: return accent.ink
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = Capsule()
        switch style {
        case .filled: shape.fill(accent.ink)
        case .tinted: shape.fill(accent.tint)
        case .outline:
            shape.fill(Theme.Palette.surface)
                .overlay(shape.strokeBorder(Theme.Palette.hairline, lineWidth: 1))
        case .ghost: shape.fill(Color.clear)
        }
    }
}

// MARK: - StatHero

struct StatHero: View {
    let label: String
    let value: String
    let subtitle: String?
    let symbol: String
    let accent: AccentPair

    init(label: String, value: String, subtitle: String? = nil, symbol: String, accent: AccentPair) {
        self.label = label
        self.value = value
        self.subtitle = subtitle
        self.symbol = symbol
        self.accent = accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(label.uppercased())
                    .font(Theme.Typo.sectionHead)
                    .tracking(1.2)
                    .foregroundStyle(Theme.Palette.inkSoft)
                Spacer()
                IconBadge(symbol: symbol, accent: accent, size: 32, symbolSize: 14)
            }

            Text(value)
                .font(Theme.Typo.display)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if let subtitle {
                Text(subtitle)
                    .font(Theme.Typo.caption)
                    .foregroundStyle(Theme.Palette.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Buttons

struct PrimaryPillButtonStyle: ButtonStyle {
    var accent: AccentPair = Theme.Palette.lilac
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(accent.ink))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SecondaryPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Theme.Palette.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.Palette.surface)
                    .overlay(Capsule().strokeBorder(Theme.Palette.hairline, lineWidth: 1))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct GhostIconButtonStyle: ButtonStyle {
    @State private var hover = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hover ? Theme.Palette.surfaceMuted : Color.clear)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .onHover { hover = $0 }
    }
}

// MARK: - FilterTab

struct FilterTab: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let accent: AccentPair
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? accent.ink : Theme.Palette.inkSoft)
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isSelected ? .white : Theme.Palette.inkSoft)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(isSelected ? accent.ink : Theme.Palette.surfaceMuted)
                            )
                    }
                }
                Capsule()
                    .fill(isSelected ? accent.ink : Color.clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyStateView

struct EmptyStateView: View {
    let symbol: String
    let title: String
    var hint: String? = nil
    var accent: AccentPair = Theme.Palette.neutral

    var body: some View {
        VStack(spacing: 12) {
            IconBadge(symbol: symbol, accent: accent, size: 48, symbolSize: 22)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.Palette.inkSoft)
            if let hint {
                Text(hint)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}

// MARK: - Convenience modifiers

extension View {
    /// Wraps the view in a PastelCard with the given style.
    func pastelCard(_ style: CardStyle = .elevated, padding: CGFloat = 20, radius: CGFloat? = nil) -> some View {
        PastelCard(style: style, radius: radius, padding: padding) { self }
    }
}
