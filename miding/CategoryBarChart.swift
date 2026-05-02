
import SwiftUI
import Charts

struct CategoryBarChart: View {
    let data: [(category: String, count: Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Top Categories", accent: Theme.Palette.sky)

            Chart(data, id: \.category) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(Theme.Palette.sky.ink.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .extended, position: .leading)
            }
            .frame(height: 200)
        }
        .pastelCard(.elevated, padding: 22)
    }
}
