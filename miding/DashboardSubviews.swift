
import SwiftUI


struct NoteRow: View {
    let note: Note

    private var previewText: String {
        let cleaned = note.content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(2)
            .joined(separator: " ")
        if cleaned.count > 60 {
            return String(cleaned.prefix(60)) + "…"
        }
        return cleaned.isEmpty ? "No additional text" : cleaned
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                if note.journalDate != nil {
                    Circle().fill(Theme.Palette.journal.ink).frame(width: 6, height: 6)
                }
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Text(note.modifiedAt, format: .dateTime.hour().minute())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Palette.inkSoft)

                Text(previewText)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Compatibility shim — kept so existing callers compile. Forwards to FilterTab.
struct StatusTab: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    /// Maps the legacy SwiftUI color to a pastel accent so old call sites still look on-theme.
    private var accent: AccentPair {
        if color == .blue || color == .primary { return Theme.Palette.sky }
        if color == .orange { return Theme.Palette.butter }
        if color == .red { return Theme.Palette.blush }
        if color == .green { return Theme.Palette.mint }
        return Theme.Palette.neutral
    }

    var body: some View {
        FilterTab(label: label, count: count, isSelected: isSelected, accent: accent, action: action)
    }
}

/// Hero stat — used at the top of the dashboard.
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    private var accent: AccentPair {
        if color == .blue { return Theme.Palette.sky }
        if color == .green { return Theme.Palette.mint }
        if color == .purple { return Theme.Palette.lilac }
        if color == .orange { return Theme.Palette.peach }
        if color == .red { return Theme.Palette.blush }
        return Theme.Palette.lilac
    }

    var body: some View {
        StatHero(label: title, value: value, subtitle: subtitle, symbol: icon, accent: accent)
            .pastelCard(.elevated, padding: 22)
    }
}
