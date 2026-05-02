
import SwiftUI
import Charts

struct PriorityPieChart: View {
    let data: [(priority: String, count: Int)]

    private var palette: [Color] {
        Theme.Palette.chartSeries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Priority Distribution", accent: Theme.Palette.lilac)

            Chart(data, id: \.priority) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.62),
                    angularInset: 2
                )
                .cornerRadius(6)
                .foregroundStyle(by: .value("Priority", item.priority.capitalized))
            }
            .chartForegroundStyleScale(range: palette)
            .frame(height: 200)
            .chartLegend(position: .trailing, alignment: .center)
        }
        .pastelCard(.elevated, padding: 22)
    }
}
