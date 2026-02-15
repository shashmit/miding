
import SwiftUI

struct ContributionHeatmap: View {
    let activity: [DailyActivity]
    
    // Grid configuration
    private let rows = 7
    private let cols = 20 // Increased to fill more space and show more history
    private let cellSize: CGFloat = 16
    private let spacing: CGFloat = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Contribution Activity")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Spacer()
                
                // Legend - moved to top right for better layout balance
                HStack(spacing: 12) {
                    legendItem(label: "Task", color: Color(red: 0.0, green: 0.7, blue: 1.0))
                    legendItem(label: "Ticket", color: Color(red: 1.0, green: 0.6, blue: 0.0))
                    legendItem(label: "Journal", color: Color(red: 1.0, green: 0.0, blue: 0.6))
                }
            }
                
            // Heatmap Grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: spacing), count: cols), spacing: spacing) {
                ForEach(activity.prefix(rows * cols)) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(colorFor(activity: day))
                        .frame(width: cellSize, height: cellSize)
                        .help(tooltipFor(day))
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }
    
    private func colorFor(activity: DailyActivity) -> Color {
        if activity.totalCount == 0 {
            return Color.secondary.opacity(0.1)
        }
        
        let total = Double(activity.totalCount)
        let t = Double(activity.taskCount)
        let k = Double(activity.ticketCount)
        let j = Double(activity.journalCount)
        
        // Colors (RGB)
        // Task: Cyan/Blue (0.0, 0.7, 1.0)
        // Ticket: Orange (1.0, 0.6, 0.0)
        // Journal: Pink/Magenta (1.0, 0.0, 0.6)
        
        // Weighted average for color blending
        let r = ((t * 0.0) + (k * 1.0) + (j * 1.0)) / total
        let g = ((t * 0.7) + (k * 0.6) + (j * 0.0)) / total
        let b = ((t * 1.0) + (k * 0.0) + (j * 0.6)) / total
        
        // Intensity scaling (darker/more opaque for more activity)
        // Use opacity: 0.3 for 1 item, up to 1.0 for 5+ items
        let opacity = min(1.0, 0.3 + (total * 0.14))
        
        return Color(red: r, green: g, blue: b).opacity(opacity)
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
