
import SwiftUI
import Combine

struct DailyActivity: Identifiable {
    let id = UUID()
    let date: Date
    var taskCount: Int = 0
    var ticketCount: Int = 0
    var journalCount: Int = 0
    
    var totalCount: Int {
        taskCount + ticketCount + journalCount
    }
}

class StatisticsViewModel: ObservableObject {
    @Published var totalTasks: Int = 0
    @Published var dailyAvgTasks: Double = 0.0
    
    @Published var totalTickets: Int = 0
    @Published var ticketCompletionRate: Double = 0.0
    
    // Heatmap data: array of 119 days (17 weeks * 7 days)
    @Published var activityHeatmap: [DailyActivity] = []
    
    // Graph data
    @Published var totalActivityHistory: [(date: Date, count: Int)] = []
    
    // Activity Overview Counts
    @Published var activityCounts: (journal: Int, task: Int, ticket: Int, note: Int) = (0, 0, 0, 0)
    
    // Detailed History for Multi-line Chart
    @Published var taskHistory: [(date: Date, count: Int)] = []
    @Published var ticketHistory: [(date: Date, count: Int)] = []
    @Published var journalHistory: [(date: Date, count: Int)] = []
    
    // Widget Data
    @Published var priorityDistribution: [(priority: String, count: Int)] = []
    @Published var categoryDistribution: [(category: String, count: Int)] = []
    @Published var recentActivity: [NoteHistoryEntry] = []
    @Published var topTags: [(tag: String, count: Int)] = []
    
    // Gradient Bias (-1.0 to 1.0)
    @Published var gradientBias: Double = 0.0
    
    private let parser = MarkdownParser()
    private var cancellables = Set<AnyCancellable>()
    let notesViewModel: NotesViewModel
    
    init(notesViewModel: NotesViewModel) {
        self.notesViewModel = notesViewModel
        
        // React to changes in notes, tickets, or tasks
        notesViewModel.$notes
            .sink { [weak self] _ in self?.recalculate() }
            .store(in: &cancellables)
            
        // Initial calc
        recalculate()
    }
    
    func recalculate() {
        let tasks = notesViewModel.allTasks.map { $0.task }
        let tickets = notesViewModel.allTickets.map { $0.ticket }
        let history = notesViewModel.allHistory.map { $0.entry }
        
        // 1. Task Stats
        let completedTasks = tasks.filter { $0.completedDate != nil }
        totalTasks = completedTasks.count
        
        if let firstDate = completedTasks.map({ $0.completedDate! }).min() {
            let days = max(1, Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 1)
            dailyAvgTasks = Double(totalTasks) / Double(days)
        } else {
            dailyAvgTasks = 0
        }
        
        // 2. Ticket Stats
        totalTickets = tickets.count
        let closedCount = tickets.filter { $0.status == .closed }.count
        ticketCompletionRate = totalTickets > 0 ? Double(closedCount) / Double(totalTickets) : 0
        
        // 3. Activity Flow (Last 14 days)
        var activityData: [(date: Date, count: Int)] = []
        var tData: [(date: Date, count: Int)] = []
        var kData: [(date: Date, count: Int)] = []
        var jData: [(date: Date, count: Int)] = []
        
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                // Tasks
                let tCount = completedTasks.filter {
                    guard let d = $0.completedDate else { return false }
                    return calendar.isDate(d, inSameDayAs: date)
                }.count
                // Tickets (Created + Closed)
                let tickCount = tickets.filter {
                    if let d = $0.createdDate, calendar.isDate(d, inSameDayAs: date) { return true }
                    if let d = $0.closedDate, calendar.isDate(d, inSameDayAs: date) { return true }
                    return false
                }.count
                // History
                let hCount = history.filter {
                    calendar.isDate($0.timestamp, inSameDayAs: date)
                }.count
                
                let total = tCount + tickCount + hCount
                activityData.append((date: date, count: total))
                
                tData.append((date: date, count: tCount))
                kData.append((date: date, count: tickCount))
                jData.append((date: date, count: hCount))
            }
        }
        totalActivityHistory = activityData.reversed()
        taskHistory = tData.reversed()
        ticketHistory = kData.reversed()
        journalHistory = jData.reversed()
        
        // 4. Heatmap (Last 119 days)
        var tempMap: [Date: DailyActivity] = [:]
        
        // Tasks
        for task in completedTasks {
            if let d = task.completedDate {
                let key = calendar.startOfDay(for: d)
                var activity = tempMap[key] ?? DailyActivity(date: key)
                activity.taskCount += 1
                tempMap[key] = activity
            }
        }
        
        // Tickets (Created & Closed)
        for ticket in tickets {
            // Created = engagement
            if let d = ticket.createdDate {
                let key = calendar.startOfDay(for: d)
                var activity = tempMap[key] ?? DailyActivity(date: key)
                activity.ticketCount += 1
                tempMap[key] = activity
            }
            // Closed = engagement
            if let d = ticket.closedDate {
                let key = calendar.startOfDay(for: d)
                var activity = tempMap[key] ?? DailyActivity(date: key)
                activity.ticketCount += 1
                tempMap[key] = activity
            }
        }
        
        // Journal/History (Edits)
        for entry in history {
            let key = calendar.startOfDay(for: entry.timestamp)
            var activity = tempMap[key] ?? DailyActivity(date: key)
            activity.journalCount += 1
            tempMap[key] = activity
        }
        
        var heatmap: [DailyActivity] = []
        for i in 0..<119 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let key = calendar.startOfDay(for: date)
                let activity = tempMap[key] ?? DailyActivity(date: date)
                heatmap.append(activity)
            }
        }
        activityHeatmap = heatmap.reversed()
        
        // 5. Gradient Bias
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let recentTasksCount = completedTasks.filter { $0.completedDate ?? Date.distantPast > sevenDaysAgo }.count
        let recentTicketsCount = tickets.filter { ($0.createdDate ?? Date.distantPast > sevenDaysAgo) || ($0.closedDate ?? Date.distantPast > sevenDaysAgo) }.count
        
        let totalRecent = Double(recentTasksCount + recentTicketsCount)
        if totalRecent == 0 {
            gradientBias = 0
        } else {
            let ticketProp = Double(recentTicketsCount) / totalRecent
            gradientBias = (ticketProp * 2) - 1
        }
        
        // 6. Widget Aggregations
        
        // Priority
        var prioCounts: [String: Int] = [:]
        for t in tickets {
            let p = t.priority?.rawValue ?? "no-priority"
            prioCounts[p, default: 0] += 1
        }
        for t in tasks {
            if let p = t.priority {
                prioCounts[p.rawValue, default: 0] += 1
            }
        }
        priorityDistribution = prioCounts.map { (priority: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            
        // Category
        var catCounts: [String: Int] = [:]
        for t in tasks {
            if let c = t.category {
                catCounts[c, default: 0] += 1
            }
        }
        categoryDistribution = catCounts.map { (category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
            
        // Recent Activity
        recentActivity = Array(history.prefix(5))
        
        // Tags
        var tagCounts: [String: Int] = [:]
        for note in notesViewModel.notes {
            for tag in note.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        topTags = tagCounts.map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }

        // 7. Activity Overview Counts
        let journalCount = notesViewModel.journalNotes.count
        let noteCount = notesViewModel.notes.filter { $0.journalDate == nil }.count
        // use total count for tasks/tickets, not just completed/closed
        let allTasksCount = tasks.count
        let allTicketsCount = tickets.count
        activityCounts = (journal: journalCount, task: allTasksCount, ticket: allTicketsCount, note: noteCount)
    }
}



