
import SwiftUI

struct ContributionHeatmap: View {
    let activity: [DailyActivity]

    private let rows = 7
    private let cols = 20
    private let cellSize: CGFloat = 16
    private let spacing: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                SectionHeader("Contribution Activity", accent: Theme.Palette.mint)

                HStack(spacing: 14) {
                    legendItem(label: "Task",    accent: Theme.Palette.mint)
                    legendItem(label: "Ticket",  accent: Theme.Palette.peach)
                    legendItem(label: "Journal", accent: Theme.Palette.lilac)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: cols), spacing: spacing) {
                ForEach(activity.prefix(rows * cols)) { day in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(colorFor(activity: day))
                        .frame(width: cellSize, height: cellSize)
                        .help(tooltipFor(day))
                }
            }
        }
        .pastelCard(.elevated, padding: 24)
    }

    private func legendItem(label: String, accent: AccentPair) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(accent.ink).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Palette.inkSoft)
        }
    }

    /// Picks the dominant accent for the day, then steps it through 5 intensity levels.
    private func colorFor(activity: DailyActivity) -> Color {
        if activity.totalCount == 0 {
            return Theme.Palette.surfaceMuted
        }

        // Dominant accent
        let accent: AccentPair
        if activity.taskCount >= activity.ticketCount && activity.taskCount >= activity.journalCount {
            accent = Theme.Palette.mint
        } else if activity.ticketCount >= activity.journalCount {
            accent = Theme.Palette.peach
        } else {
            accent = Theme.Palette.lilac
        }

        // Map total count → 5-step ramp
        switch activity.totalCount {
        case 1: return accent.tint
        case 2: return accent.tint.mix(with: accent.ink, fraction: 0.25)
        case 3: return accent.tint.mix(with: accent.ink, fraction: 0.5)
        case 4: return accent.tint.mix(with: accent.ink, fraction: 0.75)
        default: return accent.ink
        }
    }

    private func tooltipFor(_ day: DailyActivity) -> String {
        var parts: [String] = []
        if day.taskCount > 0 { parts.append("\(day.taskCount) Tasks") }
        if day.ticketCount > 0 { parts.append("\(day.ticketCount) Tickets") }
        if day.journalCount > 0 { parts.append("\(day.journalCount) Journal") }

        let dateStr = day.date.formatted(date: .abbreviated, time: .omitted)
        if parts.isEmpty { return "\(dateStr): No activity" }
        return "\(dateStr): " + parts.joined(separator: ", ")
    }
}

private extension Color {
    /// Linear interpolation between two SwiftUI colors via their sRGB components.
    func mix(with other: Color, fraction: Double) -> Color {
        let f = max(0, min(1, fraction))
        #if canImport(AppKit)
        let a = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let b = NSColor(other).usingColorSpace(.sRGB) ?? NSColor(other)
        let r = a.redComponent * (1 - f) + b.redComponent * f
        let g = a.greenComponent * (1 - f) + b.greenComponent * f
        let bl = a.blueComponent * (1 - f) + b.blueComponent * f
        return Color(.sRGB, red: r, green: g, blue: bl, opacity: 1)
        #else
        return self
        #endif
    }
}
