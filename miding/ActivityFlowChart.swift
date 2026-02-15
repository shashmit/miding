
import SwiftUI
import Charts

struct ActivityFlowChart: View {
    // Data for each series
    let tasks: [(date: Date, count: Int)]
    let tickets: [(date: Date, count: Int)]
    let journal: [(date: Date, count: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Flow")
                .font(.headline)
            
            if tasks.isEmpty && tickets.isEmpty && journal.isEmpty {
                 ContentUnavailableView("No activity data", systemImage: "chart.xyaxis.line")
                    .frame(height: 180)
            } else {
                Chart {
                    tasksSeries
                    ticketsSeries
                    journalSeries
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { value in
                        if let date = value.as(Date.self) {
                             AxisValueLabel {
                                Text(date, format: .dateTime.day().month())
                             }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                
                // Custom Legend
                HStack(spacing: 16) {
                    legendItem(name: "Tasks", color: Color(red: 0.0, green: 0.8, blue: 1.0))
                    legendItem(name: "Tickets", color: Color(red: 1.0, green: 0.6, blue: 0.0))
                    legendItem(name: "Journal", color: Color(red: 1.0, green: 0.0, blue: 0.6))
                }
                .font(.caption)
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
    
    private func legendItem(name: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(name)
                .foregroundStyle(.secondary)
        }
    }
    
    @ChartContentBuilder
    private var tasksSeries: some ChartContent {
        ForEach(tasks, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count),
                series: .value("Type", "Tasks")
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color(red: 0.0, green: 0.8, blue: 1.0)) // Cyan
            .symbol {
                Circle()
                    .fill(Color(red: 0.0, green: 0.8, blue: 1.0))
                    .frame(width: 6, height: 6)
            }
            
            AreaMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.3),
                        Color(red: 0.0, green: 0.8, blue: 1.0).opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    @ChartContentBuilder
    private var ticketsSeries: some ChartContent {
        ForEach(tickets, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count),
                series: .value("Type", "Tickets")
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color(red: 1.0, green: 0.6, blue: 0.0)) // Orange
            .symbol {
                Circle()
                    .fill(Color(red: 1.0, green: 0.6, blue: 0.0))
                    .frame(width: 6, height: 6)
            }
            
            AreaMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.3),
                        Color(red: 1.0, green: 0.6, blue: 0.0).opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    @ChartContentBuilder
    private var journalSeries: some ChartContent {
        ForEach(journal, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count),
                series: .value("Type", "Journal")
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color(red: 1.0, green: 0.0, blue: 0.6)) // Pink
            .symbol {
                Circle()
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.6))
                    .frame(width: 6, height: 6)
            }
            
            AreaMark(
                x: .value("Date", item.date),
                y: .value("Activity", item.count)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.0, blue: 0.6).opacity(0.3),
                        Color(red: 1.0, green: 0.0, blue: 0.6).opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
}
