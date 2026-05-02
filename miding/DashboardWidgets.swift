
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
        VStack(alignment: .leading, spacing: 18) {
            SectionHeader("Proximity Tasks", accent: Theme.Palette.tasks)

            VStack(alignment: .leading, spacing: 14) {
                DayRow(
                    title: "Yesterday",
                    date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                    tasks: yesterdayTasks,
                    accent: Theme.Palette.neutral
                )
                Divider().background(Theme.Palette.hairline)
                DayRow(
                    title: "Today",
                    date: Date(),
                    tasks: todayTasks,
                    accent: Theme.Palette.tasks
                )
                Divider().background(Theme.Palette.hairline)
                DayRow(
                    title: "Tomorrow",
                    date: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                    tasks: tomorrowTasks,
                    accent: Theme.Palette.peach
                )
            }
            Spacer(minLength: 0)
        }
        .frame(height: 340)
        .pastelCard(.elevated, padding: 22)
    }

    @ViewBuilder
    private func DayRow(title: String, date: Date, tasks: [TaskItem], accent: AccentPair) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Pill(text: title, accent: accent, style: .tinted, size: 11)
                Spacer()
                Text(date, format: .dateTime.day().month())
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.inkMuted)
            }

            if tasks.isEmpty {
                Text("No tasks")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Palette.inkMuted)
                    .padding(.vertical, 2)
            } else {
                ForEach(tasks.prefix(5), id: \.id) { task in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(task.isCompleted ? Theme.Palette.mint.ink : Theme.Palette.inkFaint)

                        Text(task.text)
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(task.isCompleted ? Theme.Palette.inkMuted : Theme.Palette.ink)
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
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(accent.ink)
                }
            }
        }
    }
}

struct TicketListView: View {
    let tickets: [(ticket: Ticket, sourceNoteID: UUID)]
    var onNavigateToNote: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Recent Tickets", accent: Theme.Palette.tickets) {
                Text("\(tickets.count) total")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.Palette.inkMuted)
            }

            if tickets.isEmpty {
                Spacer(minLength: 0)
                EmptyStateView(symbol: "ticket", title: "No tickets yet", accent: Theme.Palette.tickets)
                Spacer(minLength: 0)
            } else {
                VStack(spacing: 10) {
                    ForEach(tickets.prefix(5), id: \.ticket.id) { item in
                        TicketRow(ticket: item.ticket)
                            .contentShape(Rectangle())
                            .onTapGesture { onNavigateToNote(item.sourceNoteID) }
                    }
                }

                if tickets.count > 5 {
                    Text("See all in the Tickets tab")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Palette.tickets.ink)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 340)
        .pastelCard(.elevated, padding: 22)
    }
}

struct TicketRow: View {
    let ticket: Ticket

    var body: some View {
        let accent = ticket.status.accent
        HStack(alignment: .center, spacing: 12) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent.ink)
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(ticket.title ?? "Untitled Ticket")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Pill(text: ticket.identifier, accent: Theme.Palette.neutral, style: .outline, size: 10)
                    Pill(text: ticket.status.displayLabel, accent: accent, style: .tinted, size: 10)
                }
            }

            Spacer()

            if let priority = ticket.priority {
                Pill(text: priority.rawValue.capitalized, accent: priority.accent, style: .tinted, size: 10)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}
