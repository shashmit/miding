
import SwiftUI

struct RecentActivityWidget: View {
    let history: [NoteHistoryEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Recent Activity", accent: Theme.Palette.butter)

            if history.isEmpty {
                Text("No recent activity")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.inkMuted)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(history) { entry in
                        HStack(spacing: 12) {
                            IconBadge(symbol: iconFor(entry.summary), accent: accentFor(entry.summary), size: 26, symbolSize: 11)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.summary)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Theme.Palette.ink)
                                Text(entry.timestamp, format: .relative(presentation: .named))
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.Palette.inkMuted)
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
        .pastelCard(.elevated, padding: 22)
    }

    func iconFor(_ summary: String) -> String {
        if summary.contains("Created") { return "plus" }
        if summary.contains("Saved") { return "checkmark" }
        return "pencil"
    }

    func accentFor(_ summary: String) -> AccentPair {
        if summary.contains("Created") { return Theme.Palette.mint }
        if summary.contains("Saved") { return Theme.Palette.sky }
        return Theme.Palette.peach
    }
}
