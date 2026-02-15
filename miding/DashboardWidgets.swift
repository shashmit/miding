
import SwiftUI

struct TaskThreeDayView: View {
    let tasks: [(task: TaskItem, sourceNoteID: UUID)]
    var onNavigateToNote: (UUID) -> Void
    
    private var yesterdayTasks: [TaskItem] {
        filterTasks(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
    }
    
    private var todayTasks: [TaskItem] {
        filterTasks(for: Date())
    }
    
    private var tomorrowTasks: [TaskItem] {
        filterTasks(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
    }
    
    private func filterTasks(for date: Date) -> [TaskItem] {
        tasks.map { $0.task }.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, inSameDayAs: date)
        }
    }
    
    private func getSourceNoteID(for task: TaskItem) -> UUID? {
        tasks.first(where: { $0.task.id == task.id })?.sourceNoteID
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Proximity Task")
                .font(.headline)
            
            VStack(spacing: 12) {
                // Yesterday
                DayRow(title: "Yesterday", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, tasks: yesterdayTasks, color: .secondary)
                
                Divider()
                
                // Today
                DayRow(title: "Today", date: Date(), tasks: todayTasks, color: .blue)
                
                Divider()
                
                // Tomorrow
                DayRow(title: "Tomorrow", date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!, tasks: tomorrowTasks, color: .orange)
            }
            Spacer()
        }
        .frame(height: 340)
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func DayRow(title: String, date: Date, tasks: [TaskItem], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(date, format: .dateTime.day().month())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if tasks.isEmpty {
                Text("No tasks")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(task.isCompleted ? .green : .secondary)
                        
                        Text(task.text)
                            .font(.caption)
                            .lineLimit(1)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    }
                    .padding(.vertical, 1)
                    .onTapGesture {
                        if let noteID = getSourceNoteID(for: task) {
                            onNavigateToNote(noteID)
                        }
                    }
                }
                
                if tasks.count > 5 {
                    Text("+ \(tasks.count - 5) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct TicketListView: View {
    let tickets: [(ticket: Ticket, sourceNoteID: UUID)]
    var onNavigateToNote: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Tickets")
                    .font(.headline)
                
                Spacer()
                
                Text("\(tickets.count) Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if tickets.isEmpty {
                Spacer()
                ContentUnavailableView("No tickets found", systemImage: "ticket")
                Spacer()
            } else {
                ForEach(tickets.prefix(5), id: \.ticket.id) { item in
                    TicketRow(ticket: item.ticket)
                        .onTapGesture {
                            onNavigateToNote(item.sourceNoteID)
                        }
                    
                    if item.ticket.id != tickets.prefix(5).last?.ticket.id {
                        Divider()
                    }
                }
                
                if tickets.count > 5 {
                    Text("See all tickets in Tickets tab")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                Spacer()
            }
        }
        .frame(height: 340)
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct TicketRow: View {
    let ticket: Ticket
    
    var statusColor: Color {
        switch ticket.status {
        case .open: return .blue
        case .inProgress: return .orange
        case .blocked: return .red
        case .closed: return .green
        }
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Status Icon
            Image(systemName: "ticket.fill")
                .foregroundStyle(statusColor)
                .font(.system(size: 14))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(ticket.title ?? "Untitled Ticket")
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(ticket.identifier)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    
                    Text(ticket.status.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                }
            }
            
            Spacer()
            
            if let priority = ticket.priority {
                Text(priority.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor(priority).opacity(0.1))
                    .foregroundStyle(priorityColor(priority))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Make full row tappable
    }
    
    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}
