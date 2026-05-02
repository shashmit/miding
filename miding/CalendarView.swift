
import SwiftUI

struct CalendarView: View {
    @Binding var selectedDate: Date? // nil means no specific date selected (maybe show all?)
    
    @State private var currentMonth: Date = Date()
    
    // Grid configuration
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let calendar = Calendar.current
    
    // MARK: - Legacy Initializer Support
    init(month: Date, highlightedDates: Set<DateComponents>) {
        self._selectedDate = Binding.constant(month)
        self._currentMonth = State(initialValue: month)
    }
    
    // MARK: - New Initializer
    init(selectedDate: Binding<Date?>) {
        self._selectedDate = selectedDate
        // Initialize currentMonth to selectedDate or Today
        let start = selectedDate.wrappedValue ?? Date()
        self._currentMonth = State(initialValue: start)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month Header & Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Text(currentMonth, format: .dateTime.month(.wide).year())
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.Palette.ink)
                    .onTapGesture {
                        currentMonth = Date()
                    }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            
            // Days of Week
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Days Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(calendar.daysInMonth(for: currentMonth), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: isSelected(date),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
        )
    }
    
    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(date, inSameDayAs: selected)
    }
    
    // Removed hasTasks logic
    
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.Palette.lilac.ink)
                            .frame(width: 30, height: 30)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Theme.Palette.tasks.ink, lineWidth: 1.5)
                            .frame(width: 30, height: 30)
                    }

                    Text(date, format: .dateTime.day())
                        .font(.system(size: 13, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .white : (isToday ? Theme.Palette.tasks.ink : Theme.Palette.ink))
                }

                Circle().fill(Color.clear).frame(width: 4, height: 4)
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
    }
}

extension Calendar {
    func daysInMonth(for date: Date) -> [Date?] {
        guard let monthInterval = self.dateInterval(of: .month, for: date) else { return [] }
        
        let firstDay = monthInterval.start
        let startComponents = self.dateComponents([.year, .month, .weekday], from: firstDay)
        let firstWeekday = startComponents.weekday! // 1 = Sunday, 2 = Monday, ...
        
        var days: [Date?] = []
        
        // Pad before first day
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days
        let range = self.range(of: .day, in: .month, for: date)!
        for day in range {
            if let date = self.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        
        return days
    }
}

#Preview {
    CalendarView(selectedDate: .constant(Date()))
}
