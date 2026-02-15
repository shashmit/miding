
import SwiftUI

struct TimelineWidget: View {
    @ObservedObject var vm: NotesViewModel
    let onNavigateToNote: (UUID) -> Void
    
    // Timeline configuration
    private let daysBefore = 2
    private let daysAfter = 7
    private let columnWidth: CGFloat = 80
    private let rowHeight: CGFloat = 40
    
    private var calendar: Calendar { Calendar.current }
    private var today: Date { calendar.startOfDay(for: Date()) }
    
    private var timelineDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-daysBefore...daysAfter).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    private var datedTasks: [(task: TaskItem, sourceNoteID: UUID)] {
        vm.allTasks
            .filter { $0.task.dueDate != nil }
            .sorted { ($0.task.dueDate ?? .distantPast) < ($1.task.dueDate ?? .distantPast) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sprint Timeline")
                .font(.headline)
            
            if datedTasks.isEmpty {
                ContentUnavailableView("No scheduled tasks", systemImage: "calendar")
                    .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Date headers
                        dateHeaderRow
                        
                        // Tasks Grid
                        ZStack(alignment: .topLeading) {
                            gridLines
                            todayIndicator
                            taskBarsView
                        }
                        .frame(height: max(CGFloat(datedTasks.count) * rowHeight + 10, 100))
                    }
                    .frame(minWidth: CGFloat(timelineDates.count) * columnWidth)
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
    
    // MARK: - Components
    
    private var dateHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(timelineDates, id: \.self) { date in
                let isToday = calendar.isDate(date, inSameDayAs: today)
                VStack(spacing: 4) {
                    Text(dayLabel(date))
                        .font(.system(size: 10, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? .white : .secondary)
                        .textCase(.uppercase)
                    
                    Text(dateLabel(date))
                        .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                        .foregroundStyle(isToday ? .white : .primary)
                }
                .frame(width: columnWidth)
                .padding(.vertical, 8)
                .background(
                    isToday ? Capsule().fill(Color.blue.gradient) : nil
                )
            }
        }
    }
    
    private var gridLines: some View {
        HStack(spacing: 0) {
            ForEach(timelineDates, id: \.self) { _ in
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .offset(x: columnWidth / 2)
                    .frame(width: columnWidth, alignment: .leading)
            }
        }
    }
    
    private var todayIndicator: some View {
        GeometryReader { _ in
            let todayIndex = timelineDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) ?? daysBefore
            let xOffset = CGFloat(todayIndex) * columnWidth + columnWidth / 2
            
            Rectangle()
                .fill(Color.blue.gradient)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .offset(x: xOffset)
                .shadow(color: .blue.opacity(0.5), radius: 4)
        }
    }
    
    private var taskBarsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(datedTasks.enumerated()), id: \.element.task.id) { index, item in
                taskBar(item: item, rowIndex: index)
            }
        }
        .padding(.top, 12)
    }
    
    private func taskBar(item: (task: TaskItem, sourceNoteID: UUID), rowIndex: Int) -> some View {
        let dueDate = item.task.dueDate ?? today
        let dueDayStart = calendar.startOfDay(for: dueDate)
        let dateIndex = timelineDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: dueDayStart) })
        let xOffset = CGFloat(dateIndex ?? 0) * columnWidth + 4
        let barWidth = columnWidth - 8
        let barColor = taskPriorityColor(item.task.priority)
        
        return HStack(spacing: 0) {
            Spacer().frame(width: max(xOffset, 0))
            
            Button {
                onNavigateToNote(item.sourceNoteID)
            } label: {
                HStack(spacing: 6) {
                    if item.task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(contrastColor(for: item.task.priority).opacity(0.9))
                    }
                    
                    Text(item.task.text)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(contrastColor(for: item.task.priority))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(width: barWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.task.isCompleted ? barColor.opacity(0.4).gradient : barColor.gradient)
                        .shadow(color: barColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(contrastColor(for: item.task.priority).opacity(0.2), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 0)
        }
        .frame(height: rowHeight - 4)
    }
    
    // MARK: - Helpers
    
    private func taskPriorityColor(_ priority: Priority?) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case nil: return .blue
        }
    }
    
    private func contrastColor(for priority: Priority?) -> Color {
        return priority == .medium ? .black.opacity(0.7) : .white
    }
    
    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
    
    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}
