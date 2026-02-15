
import SwiftUI

// MARK: - Task Timeline View (Workstream)

struct TaskTimelineView: View {
    @ObservedObject var vm: NotesViewModel
    let onNavigateToNote: (UUID) -> Void
    
    // Timeline shows 14 days: 3 days before today + today + 10 days ahead
    private let daysBefore = 3
    private let daysAfter = 10
    private let columnWidth: CGFloat = 110
    private let rowHeight: CGFloat = 44
    
    private var calendar: Calendar { Calendar.current }
    
    private var timelineDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-daysBefore...daysAfter).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }
    }
    
    private var today: Date { calendar.startOfDay(for: Date()) }
    
    /// Tasks that have a due date, sorted by date
    private var datedTasks: [(task: TaskItem, sourceNoteID: UUID)] {
        vm.allTasks
            .filter { $0.task.dueDate != nil }
            .sorted { ($0.task.dueDate ?? .distantPast) < ($1.task.dueDate ?? .distantPast) }
    }
    
    /// Tasks without a due date
    private var undatedTasks: [(task: TaskItem, sourceNoteID: UUID)] {
        vm.allTasks.filter { $0.task.dueDate == nil }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar
            
            Divider()
            
            if vm.allTasks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Timeline section
                        timelineSection
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // All Tasks grid below the timeline
                        allTasksGrid
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(uiColor: .systemBackground))
        #endif
    }
    
    // MARK: - Header
    
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 12) {
                    let pending = datedTasks.filter { !$0.task.isCompleted }.count
                    let overdue = datedTasks.filter {
                        !$0.task.isCompleted &&
                        ($0.task.dueDate.map { calendar.startOfDay(for: $0) < today } ?? false)
                    }.count
                    
                    Label("\(pending) pending", systemImage: "clock")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    if overdue > 0 {
                        Label("\(overdue) overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }
            }
            
            Spacer()
            
            // Legend
            HStack(spacing: 12) {
                legendItem(color: .green, label: "Low")
                legendItem(color: .yellow, label: "Medium")
                legendItem(color: .orange, label: "High")
                legendItem(color: .red, label: "Critical")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Timeline Section
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sprint Timeline")
                .font(.system(size: 18, weight: .bold))
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Date headers
                    dateHeaderRow
                    
                    // Today indicator + task bars
                    ZStack(alignment: .topLeading) {
                        // Grid lines
                        gridLines
                        
                        // Today vertical line
                        todayIndicator
                        
                        // Task bars
                        taskBarsView
                    }
                    .frame(height: max(CGFloat(datedTasks.count) * rowHeight + 20, 120))
                }
                .frame(minWidth: CGFloat(timelineDates.count) * columnWidth)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Date Header Row
    
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
    
    // MARK: - Grid Lines
    
    private var gridLines: some View {
        HStack(spacing: 0) {
            ForEach(timelineDates, id: \.self) { date in
                Rectangle()
                    .fill(Color.primary.opacity(0.05))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .offset(x: columnWidth / 2)
                    .frame(width: columnWidth, alignment: .leading)
            }
        }
    }
    
    // MARK: - Today Indicator
    
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
                .overlay(alignment: .top) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 10, height: 10)
                        .offset(x: xOffset, y: -5)
                        .shadow(color: .blue.opacity(0.5), radius: 4)
                }
        }
    }
    
    // MARK: - Task Bars
    
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
        
        // Find x position for the task's due date
        let dateIndex = timelineDates.firstIndex(where: { calendar.isDate($0, inSameDayAs: dueDayStart) })
        let xOffset = CGFloat(dateIndex ?? 0) * columnWidth + 8
        let barWidth = columnWidth - 16
        let barColor = taskPriorityColor(item.task.priority)
        let isOverdue = !item.task.isCompleted && dueDayStart < today
        
        return HStack(spacing: 0) {
            Spacer().frame(width: max(xOffset, 0))
            
            Button {
                onNavigateToNote(item.sourceNoteID)
            } label: {
                HStack(spacing: 8) {
                    if item.task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(contrastColor(for: item.task.priority).opacity(0.9))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.task.text)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(contrastColor(for: item.task.priority))
                            .lineLimit(1)
                        
                        Text(dateLabel(dueDate))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(contrastColor(for: item.task.priority).opacity(0.8))
                    }
                    
                    if let cat = item.task.category {
                        Spacer()
                        Text(cat)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(contrastColor(for: item.task.priority).opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(contrastColor(for: item.task.priority).opacity(0.2))
                            )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: barWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.task.isCompleted ? barColor.opacity(0.4).gradient : barColor.gradient)
                        .shadow(color: barColor.opacity(0.3), radius: 5, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isOverdue ? Color.red.opacity(0.8) : contrastColor(for: item.task.priority).opacity(0.2), lineWidth: isOverdue ? 2 : 1)
                )
                .opacity(item.task.isCompleted ? 0.7 : 1.0)
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 0)
        }
        .frame(height: rowHeight - 4)
    }
    
    // MARK: - All Tasks Grid
    
    private var allTasksGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Tasks")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                // View switcher pills
                HStack(spacing: 2) {
                    gridPill(icon: "list.bullet", label: "List")
                }
            }
            .padding(.horizontal, 24)
            
            // Status columns
            HStack(alignment: .top, spacing: 12) {
                taskStatusColumn(
                    title: "To-do",
                    icon: "circle",
                    color: .orange,
                    tasks: vm.allTasks.filter { !$0.task.isCompleted }
                )
                
                taskStatusColumn(
                    title: "Completed",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    tasks: vm.allTasks.filter { $0.task.isCompleted }
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func taskStatusColumn(title: String, icon: String, color: Color, tasks: [(task: TaskItem, sourceNoteID: UUID)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Column header
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                
                Text("\(tasks.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(.secondary.opacity(0.12)))
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            // Task cards
            if tasks.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .thin))
                        .foregroundStyle(.quaternary)
                    Text("No \(title.lowercased()) tasks")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(tasks, id: \.task.id) { item in
                        taskCard(item: item)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.separator.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Task Card
    
    private func taskCard(item: (task: TaskItem, sourceNoteID: UUID)) -> some View {
        Button {
            onNavigateToNote(item.sourceNoteID)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Title row
                HStack(spacing: 6) {
                    // Priority indicator
                    if let p = item.task.priority {
                        Circle()
                            .fill(taskPriorityColor(p))
                            .frame(width: 8, height: 8)
                    }
                    
                    Text(item.task.text)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(2)
                        .strikethrough(item.task.isCompleted)
                        .foregroundStyle(item.task.isCompleted ? .secondary : .primary)
                    
                    Spacer()
                }
                
                // Metadata row
                HStack(spacing: 8) {
                    if let dueDate = item.task.dueDate {
                        let isOverdue = !item.task.isCompleted && calendar.startOfDay(for: dueDate) < today
                        
                        Label {
                            Text(dueDate, format: .dateTime.month(.abbreviated).day())
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(isOverdue ? .red : .secondary)
                    }
                    
                    if let dueTime = item.task.dueTime {
                        Label {
                            Text(dueTime, format: .dateTime.hour().minute())
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                    
                    if let cat = item.task.category {
                        Text(cat)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(taskPriorityColor(item.task.priority).opacity(0.9))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(taskPriorityColor(item.task.priority).opacity(0.1))
                            )
                    }
                    
                    Spacer()
                    
                    // Source note
                    if let note = vm.notes.first(where: { $0.id == item.sourceNoteID }) {
                        Text(note.title)
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                            .lineLimit(1)
                    }
                }
                
                // Progress bar for priority visualization
                if let p = item.task.priority {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(taskPriorityColor(p).opacity(0.15))
                                .frame(height: 3)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(taskPriorityColor(p))
                                .frame(width: geo.size.width * priorityProgress(p), height: 3)
                        }
                    }
                    .frame(height: 3)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.separator.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.quaternary)
            
            Text("No tasks yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text("Add tasks with dates in your notes to see them on the timeline")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Example:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text("- [ ] Design review @due(2026-02-20) @priority(high) @cat(Design)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.secondary.opacity(0.06))
                    )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    // MARK: - Helpers
    
    private func gridPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(.secondary.opacity(0.1))
        )
    }
    
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
    
    private func priorityProgress(_ p: Priority) -> CGFloat {
        switch p {
        case .low: return 0.25
        case .medium: return 0.5
        case .high: return 0.75
        case .critical: return 1.0
        }
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
