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
        // We use sqrt to make smaller values more visible if distribution is skewed
        // But linear is more accurate. Let's stick to linear for now.
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
            // Wide Layout (Horizontal)
            HStack(spacing: 0) {
                leftContent
                    .frame(minWidth: 200)
                
                // Divider
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 1)
                    .padding(.vertical, 20)
                
                // Right Side: Radar Chart
                chartView
            }
            
            // Narrow Layout (Vertical)
            VStack(spacing: 0) {
                leftContent
                
                // Divider
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                
                chartView
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var leftContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity overview")
                .font(.headline)
            
            if total > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Most active in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(mostActiveCategory)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    activityRow(label: "Journal", count: journalCount, color: .purple)
                    activityRow(label: "Tasks", count: taskCount, color: .blue)
                    activityRow(label: "Tickets", count: ticketCount, color: .orange)
                    activityRow(label: "Notes", count: noteCount, color: .green)
                }
                .padding(.top, 8)
            } else {
                Text("No activity recorded yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(20)
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
    
    private func activityRow(label: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Int(percentage(for: count) * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
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
            let radius = min(cx, cy) - 25 // padding for labels
            
            ZStack {
                // Axes
                Path { path in
                    // Vertical
                    path.move(to: CGPoint(x: cx, y: cy - radius))
                    path.addLine(to: CGPoint(x: cx, y: cy + radius))
                    // Horizontal
                    path.move(to: CGPoint(x: cx - radius, y: cy))
                    path.addLine(to: CGPoint(x: cx + radius, y: cy))
                }
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                
                // Labels
                Text("Journal")
                    .font(.caption2)
                    .position(x: cx, y: cy - radius - 15)
                
                Text("Tasks")
                    .font(.caption2)
                    .position(x: cx + radius + 20, y: cy)
                
                Text("Tickets")
                    .font(.caption2)
                    .position(x: cx, y: cy + radius + 15)
                
                Text("Notes")
                    .font(.caption2)
                    .position(x: cx - radius - 20, y: cy)
                
                // Data Polygon
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
                .fill(Color.green.opacity(0.3))
                
                Path { path in
                    path.move(to: pJournal)
                    path.addLine(to: pTask)
                    path.addLine(to: pTicket)
                    path.addLine(to: pNote)
                    path.closeSubpath()
                }
                .stroke(Color.green, lineWidth: 2)
                
                // Dots
                ForEach([pJournal, pTask, pTicket, pNote], id: \.x) { point in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .shadow(radius: 1)
                        .position(point)
                }
            }
        }
    }
}
