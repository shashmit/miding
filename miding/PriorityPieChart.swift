
import SwiftUI
import Charts

struct PriorityPieChart: View {
    let data: [(priority: String, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Priority Distribution")
                .font(.headline)
            
            Chart(data, id: \.priority) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Priority", item.priority.capitalized))
            }
            .frame(height: 200)
            .chartLegend(position: .trailing, alignment: .center)
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
