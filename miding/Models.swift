
import Foundation
import EventKit

enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

enum TicketStatus: String, Codable, CaseIterable {
    case open, inProgress = "in-progress", blocked, closed
}



struct Ticket: Identifiable, Codable {
    var id = UUID()
    var identifier: String // e.g., T-101
    var title: String?
    var status: TicketStatus
    var priority: Priority?
    var dueDate: Date?
    var owner: String?
    var project: String?
    var createdDate: Date?
    var closedDate: Date?
    var body: String? // The content below the ticket block
    
    // Line tracking for modifications
    var blockStartLine: Int?
    var blockEndLine: Int?
}

struct CalendarEntry: Identifiable, Codable {
    var id = UUID()
    var title: String
    var date: Date
    var time: Date? // Optional time
    var duration: TimeInterval?
}

struct Project: Identifiable, Codable {
    var id = UUID()
    var name: String
    var status: String
    var owner: String?
    var deadline: Date?
}

struct JournalMetadata: Codable {
    var date: Date?
    var mood: String?
    var energy: Int?
    var sleep: String? // Duration string
    var tags: [String]?
}

struct JournalEntry: Codable {
    var id = UUID()
    var date: Date
    var rawMarkdown: String
    var metadata: JournalMetadata?
}

struct TaskItem: Identifiable, Hashable {
    let id: UUID
    let text: String
    let isCompleted: Bool
    let lineIndex: Int // line number in the markdown for toggling
    let dueDate: Date?      // Parsed from @due(yyyy-MM-dd)
    let dueTime: Date?      // Parsed from @time(HH:mm)
    let priority: Priority? // Parsed from @priority(low|medium|high|critical)
    let category: String?   // Parsed from @cat(...)
    let completedDate: Date? // Parsed from @done(yyyy-MM-dd)
}

struct ParseResult {
    var tickets: [Ticket]
    var calendarEntries: [CalendarEntry]
    var projects: [Project]
    var tasks: [TaskItem]
    var metadata: JournalMetadata?
}

struct NoteHistoryEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var timestamp: Date
    var title: String
    var contentSnapshot: String
    var summary: String // e.g. "Edited", "Created", "Saved & Committed"
}

struct Note: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    var journalDate: Date? // Optional: if associated with a specific date (Journal entry)
    var tags: [String] = []
    var history: [NoteHistoryEntry] = []
    
    // Legacy support logic can map old JournalEntry to Note
}
