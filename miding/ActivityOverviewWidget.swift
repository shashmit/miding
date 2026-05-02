import SwiftUI

struct ActivityOverviewWidget: View {
    let journalCount: Int
    let taskCount: Int
    let ticketCount: Int
    let noteCount: Int

    private var total: Int {
        journalCount + taskCount + ticketCount + noteCount
    }

    private func percentage(for count: Int) -> Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }

    private var mostActiveCategory: String {
        let maxVal = max(journalCount, max(taskCount, max(ticketCount, noteCount)))
        if maxVal == 0 { return "None" }
        if maxVal == journalCount { return "Journaling" }
        if maxVal == taskCount { return "Tasks" }
        if maxVal == ticketCount { return "Tickets" }
        return "Notes"
    }

    var body: some View {
        ViewThatFits {
            HStack(spacing: 0) {
                leftContent.frame(minWidth: 200)
                Rectangle().fill(Theme.Palette.hairline).frame(width: 1).padding(.vertical, 20)
                chartView
            }

            VStack(spacing: 0) {
                leftContent
                Rectangle().fill(Theme.Palette.hairline).frame(height: 1).padding(.horizontal, 20)
                chartView
            }
        }
        .pastelCard(.elevated, padding: 0)
    }

    private var leftContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Activity overview", accent: Theme.Palette.sage)

            if total > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Most active in")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Palette.inkMuted)

                    Text(mostActiveCategory)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.Palette.ink)
                }

                VStack(alignment: .leading, spacing: 8) {
                    activityRow(label: "Journal", count: journalCount, accent: Theme.Palette.lilac)
                    activityRow(label: "Tasks",   count: taskCount,    accent: Theme.Palette.mint)
                    activityRow(label: "Tickets", count: ticketCount,  accent: Theme.Palette.peach)
                    activityRow(label: "Notes",   count: noteCount,    accent: Theme.Palette.sage)
                }
                .padding(.top, 6)
            } else {
                Text("No activity recorded yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.inkSoft)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chartView: some View {
        RadarChart(
            journalPct: percentage(for: journalCount),
            taskPct: percentage(for: taskCount),
            ticketPct: percentage(for: ticketCount),
            notePct: percentage(for: noteCount)
        )
        .frame(width: 220, height: 220)
        .padding(20)
    }

    private func activityRow(label: String, count: Int, accent: AccentPair) -> some View {
        HStack {
            Circle().fill(accent.ink).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Palette.inkSoft)
            Spacer()
            Text("\(Int(percentage(for: count) * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.Palette.ink)
        }
    }
}

struct RadarChart: View {
    let journalPct: Double
    let taskPct: Double
    let ticketPct: Double
    let notePct: Double

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let cx = w / 2
            let cy = h / 2
            let radius = min(cx, cy) - 25

            ZStack {
                // Concentric guide rings
                ForEach([0.33, 0.66, 1.0], id: \.self) { ratio in
                    Circle()
                        .stroke(Theme.Palette.hairline, lineWidth: 1)
                        .frame(width: radius * 2 * ratio, height: radius * 2 * ratio)
                        .position(x: cx, y: cy)
                }

                Path { path in
                    path.move(to: CGPoint(x: cx, y: cy - radius))
                    path.addLine(to: CGPoint(x: cx, y: cy + radius))
                    path.move(to: CGPoint(x: cx - radius, y: cy))
                    path.addLine(to: CGPoint(x: cx + radius, y: cy))
                }
                .stroke(Theme.Palette.hairline, lineWidth: 1)

                Text("Journal").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .position(x: cx, y: cy - radius - 15)

                Text("Tasks").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .position(x: cx + radius + 22, y: cy)

                Text("Tickets").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .position(x: cx, y: cy + radius + 15)

                Text("Notes").font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .position(x: cx - radius - 22, y: cy)

                let pJournal = CGPoint(x: cx, y: cy - (journalPct * radius))
                let pTask = CGPoint(x: cx + (taskPct * radius), y: cy)
                let pTicket = CGPoint(x: cx, y: cy + (ticketPct * radius))
                let pNote = CGPoint(x: cx - (notePct * radius), y: cy)

                Path { path in
                    path.move(to: pJournal)
                    path.addLine(to: pTask)
                    path.addLine(to: pTicket)
                    path.addLine(to: pNote)
                    path.closeSubpath()
                }
                .fill(Theme.Palette.sage.tint)

                Path { path in
                    path.move(to: pJournal)
                    path.addLine(to: pTask)
                    path.addLine(to: pTicket)
                    path.addLine(to: pNote)
                    path.closeSubpath()
                }
                .stroke(Theme.Palette.sage.ink, lineWidth: 2)

                ForEach([pJournal, pTask, pTicket, pNote], id: \.x) { point in
                    Circle()
                        .fill(Theme.Palette.surface)
                        .overlay(Circle().stroke(Theme.Palette.sage.ink, lineWidth: 2))
                        .frame(width: 8, height: 8)
                        .position(point)
                }
            }
        }
    }
}
