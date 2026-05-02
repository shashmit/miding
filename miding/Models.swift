
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
    var branch: String = "main"
    var parentIds: [UUID] = [] // 0 = root, 1 = normal, 2 = merge

    var isMerge: Bool { parentIds.count > 1 }

    enum CodingKeys: String, CodingKey {
        case id, timestamp, title, contentSnapshot, summary, branch, parentIds
    }

    init(id: UUID = UUID(), timestamp: Date, title: String, contentSnapshot: String,
         summary: String, branch: String = "main", parentIds: [UUID] = []) {
        self.id = id
        self.timestamp = timestamp
        self.title = title
        self.contentSnapshot = contentSnapshot
        self.summary = summary
        self.branch = branch
        self.parentIds = parentIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        title = try c.decode(String.self, forKey: .title)
        contentSnapshot = try c.decode(String.self, forKey: .contentSnapshot)
        summary = try c.decode(String.self, forKey: .summary)
        branch = try c.decodeIfPresent(String.self, forKey: .branch) ?? "main"
        parentIds = try c.decodeIfPresent([UUID].self, forKey: .parentIds) ?? []
    }
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
    var currentBranch: String = "main"
    var branchHeads: [String: UUID] = [:] // branch name → HEAD entry id

    var allBranches: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for name in branchHeads.keys.sorted() where seen.insert(name).inserted {
            ordered.append(name)
        }
        for entry in history where seen.insert(entry.branch).inserted {
            ordered.append(entry.branch)
        }
        if ordered.isEmpty { ordered = ["main"] }
        return ordered
    }

    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, modifiedAt, journalDate, tags, history, currentBranch, branchHeads
    }

    init(id: UUID = UUID(), title: String, content: String, createdAt: Date, modifiedAt: Date,
         journalDate: Date? = nil, tags: [String] = [], history: [NoteHistoryEntry] = [],
         currentBranch: String = "main", branchHeads: [String: UUID] = [:]) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.journalDate = journalDate
        self.tags = tags
        self.history = history
        self.currentBranch = currentBranch
        self.branchHeads = branchHeads
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        content = try c.decode(String.self, forKey: .content)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        modifiedAt = try c.decode(Date.self, forKey: .modifiedAt)
        journalDate = try c.decodeIfPresent(Date.self, forKey: .journalDate)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        history = try c.decodeIfPresent([NoteHistoryEntry].self, forKey: .history) ?? []
        currentBranch = try c.decodeIfPresent(String.self, forKey: .currentBranch) ?? "main"
        branchHeads = try c.decodeIfPresent([String: UUID].self, forKey: .branchHeads) ?? [:]
    }
}
