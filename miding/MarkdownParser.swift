
import Foundation
import RegexBuilder

class MarkdownParser {
    
    // MARK: - Regex Patterns
    
    // Ticket Block: :::ticket ... :::
    // This is multi-line, so we'll handle it by identifying start/end markers
    private let ticketStartPattern = #"^:::ticket\s*$"#
    private let ticketEndPattern = #"^:::\s*$"#
    
    // Project Block: :::project ... :::
    private let projectStartPattern = #"^:::project\s*$"#
    private let projectEndPattern = #"^:::\s*$"#

    // MARK: - Parsing    
    // MARK: - Parsing
    
    // Task checkbox patterns
    private let uncheckedTaskPattern = #"^-\s+\[\s\]\s+(.+)$"#
    private let checkedTaskPattern = #"^-\s+\[x\]\s+(.+)$"#
    
    func parse(markdown: String) -> ParseResult {
        var tickets: [Ticket] = []
        var projects: [Project] = []
        var tasks: [TaskItem] = []
        var metadata: JournalMetadata?
        
        let lines = markdown.components(separatedBy: .newlines)
        var i = 0
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Frontmatter (only at start)
            if i == 0 && trimmed == "---" {
                let (meta, nextIndex) = parseMetadata(lines: lines, startIndex: i)
                metadata = meta
                i = nextIndex
                continue
            }
            
            // Ticket Block
            if let _ = try? Regex(ticketStartPattern).firstMatch(in: trimmed) {
                let (ticket, nextIndex) = parseTicketBlock(lines: lines, startIndex: i)
                if let ticket = ticket {
                    tickets.append(ticket)
                }
                i = nextIndex
                continue
            }
            
            // Project Block
            if let _ = try? Regex(projectStartPattern).firstMatch(in: trimmed) {
                let (project, nextIndex) = parseProjectBlock(lines: lines, startIndex: i)
                if let project = project {
                    projects.append(project)
                }
                i = nextIndex
                continue
            }
            
            // Task: unchecked - [ ] text
            if let match = try? Regex(uncheckedTaskPattern).firstMatch(in: trimmed) {
                let rawText = String(match.output[1].substring ?? "")
                let parsed = parseTaskAnnotations(rawText)
                let taskID = UUID(uuidString: UUID.generateDeterministicUUIDString(from: "\(i):\(rawText)")) ?? UUID()
                tasks.append(TaskItem(
                    id: taskID, text: parsed.cleanText, isCompleted: false, lineIndex: i,
                    dueDate: parsed.dueDate, dueTime: parsed.dueTime,
                    priority: parsed.priority, category: parsed.category,
                    completedDate: nil // Unchecked tasks don't have completedDate
                ))
                i += 1
                continue
            }
            
            // Task: checked - [x] text
            if let match = try? Regex(checkedTaskPattern).firstMatch(in: trimmed) {
                let rawText = String(match.output[1].substring ?? "")
                let parsed = parseTaskAnnotations(rawText)
                let taskID = UUID(uuidString: UUID.generateDeterministicUUIDString(from: "\(i):\(rawText)")) ?? UUID()
                tasks.append(TaskItem(
                    id: taskID, text: parsed.cleanText, isCompleted: true, lineIndex: i,
                    dueDate: parsed.dueDate, dueTime: parsed.dueTime,
                    priority: parsed.priority, category: parsed.category,
                    completedDate: parsed.completedDate // check for @done date
                ))
                i += 1
                continue
            }
            
            i += 1
        }
        
        return ParseResult(tickets: tickets, calendarEntries: [], projects: projects, tasks: tasks, metadata: metadata)
    }
    
    /// Toggle a task checkbox at the given line index in the markdown.
    /// Returns the updated markdown string.
    static func toggleTask(in markdown: String, atLineIndex lineIndex: Int) -> String {
        var lines = markdown.components(separatedBy: "\n")
        guard lineIndex >= 0, lineIndex < lines.count else { return markdown }
        
        let line = lines[lineIndex]
        if let range = line.range(of: "- [ ] ") {
            // Checking: Add @done(yyyy-MM-dd)
            let dateStr = staticDateFormatter.string(from: Date())
            let doneTag = " @done(\(dateStr))"
            lines[lineIndex] = line.replacingCharacters(in: range, with: "- [x] ") + doneTag
        } else if let range = line.range(of: "- [x] ") {
            // Unchecking: Remove @done(...)
            var text = line.replacingCharacters(in: range, with: "- [ ] ")
            // Remove the @done tag if present
            text = text.replacingOccurrences(of: #" @done\([^)]+\)"#, with: "", options: .regularExpression)
            // Cleanup any double spaces created
            text = text.replacingOccurrences(of: "  ", with: " ")
            lines[lineIndex] = text
        }
        
        return lines.joined(separator: "\n")
    }
    
    
    // MARK: - Private Helpers
    
    private func parseTicketBlock(lines: [String], startIndex: Int) -> (Ticket?, Int) {
        var i = startIndex + 1
        var content: [String] = []
        var body: [String] = []
        var inBody = false
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if !inBody {
                if let _ = try? Regex(ticketEndPattern).firstMatch(in: trimmed) {
                    inBody = true
                    i += 1
                    continue
                }
                content.append(line)
            } else {
                if (try? Regex(ticketStartPattern).firstMatch(in: trimmed)) != nil ||
                   (try? Regex(projectStartPattern).firstMatch(in: trimmed)) != nil {
                     break
                }
                body.append(line)
            }
            i += 1
        }
        
        // i is now at the start of the next block or end of file
        // The block roughly spans from startIndex to i - 1 (exclusive of next block start)
        
        var ticket = Ticket(identifier: "UNKNOWN", status: .open)
        ticket.blockStartLine = startIndex
        ticket.blockEndLine = i - 1
        
        for line in content {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let key = parts[0].lowercased()
            let value = parts[1]
            
            switch key {
            case "id": ticket.identifier = value
            case "title": ticket.title = value
            case "status": ticket.status = TicketStatus(rawValue: value) ?? .open
            case "priority": ticket.priority = Priority(rawValue: value)
            case "due": ticket.dueDate = dateFormatter.date(from: value)
            case "owner": ticket.owner = value
            case "project": ticket.project = value
            case "created": ticket.createdDate = dateFormatter.date(from: value)
            case "closed": ticket.closedDate = dateFormatter.date(from: value)
            default: break
            }
        }
        
        ticket.body = body.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (ticket, i)
    }

    private func parseProjectBlock(lines: [String], startIndex: Int) -> (Project?, Int) {
        var i = startIndex + 1
        var content: [String] = []
        
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
             if let _ = try? Regex(projectEndPattern).firstMatch(in: trimmed) {
                i += 1
                break
            }
            content.append(line)
            i += 1
        }
        
        var project = Project(name: "New Project", status: "active")
        
        for line in content {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let key = parts[0].lowercased()
            let value = parts[1]
            
            switch key {
            case "name": project.name = value
            case "status": project.status = value
            case "owner": project.owner = value
            case "deadline": project.deadline = dateFormatter.date(from: value)
            default: break
            }
        }
        
        return (project, i)
    }


    private func parseMetadata(lines: [String], startIndex: Int) -> (JournalMetadata?, Int) {
         // YAML frontmatter parsing
         var i = startIndex + 1
         var metaLines: [String] = []
         
         while i < lines.count {
             let line = lines[i]
             let trimmed = line.trimmingCharacters(in: .whitespaces)
             if trimmed == "---" {
                 i += 1
                 break
             }
             metaLines.append(line)
             i += 1
         }
         
         var metadata = JournalMetadata()
         
         for line in metaLines {
            let parts = line.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else { continue }
            let key = parts[0].lowercased()
            let value = parts[1]
             
             switch key {
             case "date": metadata.date = dateFormatter.date(from: value)
             case "mood": metadata.mood = value
             case "energy": metadata.energy = Int(value)
             case "sleep": metadata.sleep = value
             case "tags":
                 // simple CSV parsing for tags if array like [tag1, tag2]
                 let cleaned = value.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                 metadata.tags = cleaned.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
             default: break
             }
         }
         
         return (metadata, i)
    }

    // MARK: - Task Annotation Parsing
    
    private struct TaskAnnotations {
        let cleanText: String
        let dueDate: Date?
        let dueTime: Date?
        let priority: Priority?
        let category: String?
        let completedDate: Date?
    }
    
    /// Parse inline annotations from task text: @due(yyyy-MM-dd) @time(HH:mm) @priority(low|medium|high|critical) @cat(...)
    private func parseTaskAnnotations(_ rawText: String) -> TaskAnnotations {
        var dueDate: Date?
        var dueTime: Date?
        var priority: Priority?
        var category: String?
        
        // Extract @due(yyyy-MM-dd)
        if let match = rawText.range(of: #"@due\(([^)]+)\)"#, options: .regularExpression) {
            let inner = rawText[match]
            let value = inner.replacingOccurrences(of: "@due(", with: "").replacingOccurrences(of: ")", with: "")
            dueDate = dateFormatter.date(from: value)
        }
        
        // Extract @time(HH:mm)
        if let match = rawText.range(of: #"@time\(([^)]+)\)"#, options: .regularExpression) {
            let inner = rawText[match]
            let value = inner.replacingOccurrences(of: "@time(", with: "").replacingOccurrences(of: ")", with: "")
            dueTime = timeFormatter.date(from: value)
        }
        
        // Extract @priority(...)
        if let match = rawText.range(of: #"@priority\(([^)]+)\)"#, options: .regularExpression) {
            let inner = rawText[match]
            let value = inner.replacingOccurrences(of: "@priority(", with: "").replacingOccurrences(of: ")", with: "")
            priority = Priority(rawValue: value.lowercased())
        }
        
        // Extract @cat(...)
        if let match = rawText.range(of: #"@cat\(([^)]+)\)"#, options: .regularExpression) {
            let inner = rawText[match]
            let value = inner.replacingOccurrences(of: "@cat(", with: "").replacingOccurrences(of: ")", with: "")
            category = value.trimmingCharacters(in: .whitespaces)
        }
        
        // Strip all annotations from text for display
        let cleanText = rawText
            .replacingOccurrences(of: #"@due\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"@time\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"@priority\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"@cat\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"@done\([^)]*\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        // Extract @done(...)
        var completedDate: Date?
        if let match = rawText.range(of: #"@done\(([^)]+)\)"#, options: .regularExpression) {
            let inner = rawText[match]
            let value = inner.replacingOccurrences(of: "@done(", with: "").replacingOccurrences(of: ")", with: "")
            completedDate = dateFormatter.date(from: value)
        }
        
        return TaskAnnotations(cleanText: cleanText, dueDate: dueDate, dueTime: dueTime, priority: priority, category: category, completedDate: completedDate)
    }

    // MARK: - Formatters
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    private static let staticDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
