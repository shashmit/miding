
import SwiftUI

struct TagCloudView: View {
    let tags: [(tag: String, count: Int)]

    var topTags: [(tag: String, count: Int)] {
        Array(tags.prefix(8))
    }

    private let palette: [AccentPair] = [
        Theme.Palette.lilac, Theme.Palette.sky, Theme.Palette.mint,
        Theme.Palette.peach, Theme.Palette.butter, Theme.Palette.blush,
        Theme.Palette.sage
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Top Tags", accent: Theme.Palette.peach)

            FlowLayout(spacing: 8) {
                ForEach(Array(topTags.enumerated()), id: \.element.tag) { index, item in
                    let accent = palette[index % palette.count]
                    HStack(spacing: 4) {
                        Text("#\(item.tag)")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(item.count)")
                            .font(.system(size: 10, weight: .bold))
                            .opacity(0.7)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(accent.tint))
                    .foregroundStyle(accent.ink)
                }
            }
        }
        .pastelCard(.elevated, padding: 22)
    }
}

/// Lightweight flow layout for wrapping pills.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
