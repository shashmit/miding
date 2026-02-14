
import Foundation
import EventKit

enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical
}

enum TicketStatus: String, Codable, CaseIterable {
    case open, inProgress = "in-progress", blocked, closed
}

struct TaskItem: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool
    var index: Int // Zero-based line number in the source note
    var originalText: String // The full line text for verification
    
    // Helper to initialize with a deterministic UUID from a string
    init(title: String, index: Int, isCompleted: Bool, originalText: String) {
        self.title = title
        self.index = index
        self.isCompleted = isCompleted
        self.originalText = originalText
        // Create a deterministic UUID from title + index to keep IDs stable across parses if content hasn't changed
        let combined = "\(title)|\(index)"
        self.id = UUID(uuidString: UUID.generateDeterministicUUIDString(from: combined)) ?? UUID()
    }

    // Default init for existing code that might need it (though we should prefer the deterministic one)
    init(title: String, isCompleted: Bool) {
        self.title = title
        self.index = 0
        self.isCompleted = isCompleted
        self.originalText = "- [ ] \(title)"
    }
    var priority: Priority?
    var estimatedDuration: TimeInterval? // In seconds
    var project: String?
    var tags: [String] = []
    var linkedTicketID: String?
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

struct ParseResult {
    var tasks: [TaskItem]
    var tickets: [Ticket]
    var calendarEntries: [CalendarEntry]
    var projects: [Project]
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
