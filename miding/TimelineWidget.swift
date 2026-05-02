
import SwiftUI

struct TimelineWidget: View {
    @ObservedObject var vm: NotesViewModel
    let onNavigateToNote: (UUID) -> Void

    private let daysBefore = 2
    private let daysAfter = 7
    private let columnWidth: CGFloat = 84
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
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Sprint Timeline", accent: Theme.Palette.sky)

            if datedTasks.isEmpty {
                EmptyStateView(symbol: "calendar", title: "No scheduled tasks", accent: Theme.Palette.sky)
                    .frame(height: 140)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        dateHeaderRow
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
        .pastelCard(.elevated, padding: 22)
    }

    private var dateHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(timelineDates, id: \.self) { date in
                let isToday = calendar.isDate(date, inSameDayAs: today)
                VStack(spacing: 4) {
                    Text(dayLabel(date))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(isToday ? .white : Theme.Palette.inkMuted)
                        .textCase(.uppercase)
                    Text(dateLabel(date))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isToday ? .white : Theme.Palette.ink)
                }
                .frame(width: columnWidth)
                .padding(.vertical, 8)
                .background(
                    isToday ? Capsule().fill(Theme.Palette.sky.ink) : nil
                )
            }
        }
    }

    private var gridLines: some View {
        HStack(spacing: 0) {
            ForEach(timelineDates, id: \.self) { _ in
                Rectangle()
                    .fill(Theme.Palette.hairline)
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
                .fill(Theme.Palette.sky.ink.opacity(0.7))
                .frame(width: 2)
                .frame(maxHeight: .infinity)
                .offset(x: xOffset)
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
        let accent = item.task.priority?.accent ?? Theme.Palette.sky

        return HStack(spacing: 0) {
            Spacer().frame(width: max(xOffset, 0))

            Button { onNavigateToNote(item.sourceNoteID) } label: {
                HStack(spacing: 6) {
                    if item.task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(accent.ink)
                    }
                    Text(item.task.text)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(accent.ink)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(width: barWidth, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(accent.tint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(accent.ink.opacity(0.25), lineWidth: 1)
                )
                .opacity(item.task.isCompleted ? 0.7 : 1.0)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .frame(height: rowHeight - 4)
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
