
import SwiftUI
import Charts

struct ActivityFlowChart: View {
    let tasks: [(date: Date, count: Int)]
    let tickets: [(date: Date, count: Int)]
    let journal: [(date: Date, count: Int)]

    private let taskAccent = Theme.Palette.mint
    private let ticketAccent = Theme.Palette.peach
    private let journalAccent = Theme.Palette.lilac

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader("Activity Flow", accent: Theme.Palette.sky)

            if tasks.isEmpty && tickets.isEmpty && journal.isEmpty {
                EmptyStateView(symbol: "chart.xyaxis.line", title: "No activity yet", accent: Theme.Palette.sky)
                    .frame(height: 200)
            } else {
                Chart {
                    series(tasks, name: "Tasks", accent: taskAccent)
                    series(tickets, name: "Tickets", accent: ticketAccent)
                    series(journal, name: "Journal", accent: journalAccent)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel { Text(date, format: .dateTime.day().month()) }
                        }
                    }
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 220)

                HStack(spacing: 16) {
                    legendItem(name: "Tasks", accent: taskAccent)
                    legendItem(name: "Tickets", accent: ticketAccent)
                    legendItem(name: "Journal", accent: journalAccent)
                }
                .padding(.top, 4)
            }
        }
        .pastelCard(.elevated, padding: 24)
    }

    private func legendItem(name: String, accent: AccentPair) -> some View {
        HStack(spacing: 6) {
            Circle().fill(accent.ink).frame(width: 8, height: 8)
            Text(name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Palette.inkSoft)
        }
    }

    @ChartContentBuilder
    private func series(_ data: [(date: Date, count: Int)], name: String, accent: AccentPair) -> some ChartContent {
        ForEach(data, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count),
                series: .value("Type", name)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(accent.ink)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .symbol {
                Circle().fill(accent.ink).frame(width: 6, height: 6)
            }

            AreaMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [accent.tint.opacity(0.7), accent.tint.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}
