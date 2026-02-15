
import SwiftUI
import Charts

struct CategoryBarChart: View {
    let data: [(category: String, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Top Categories")
                .font(.headline)
            
            Chart(data, id: \.category) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(Color.blue.gradient)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .extended, position: .leading)
            }
            .frame(height: 200)
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
