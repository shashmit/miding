
import Foundation
import RegexBuilder

class MarkdownParser {
    
    // MARK: - Regex Patterns
    
    // Task: - [ ] Title @due(2023-10-27) #tag
    // Capture groups: 1: state (space or x), 2: title, 3: attributes
    private let taskPattern = #"^- \[( |x)\] (.*?)((?: @\S+| #\S+| \!\S+| \^\S+| ~\S+)*)$"#
    
    // Ticket Block: :::ticket ... :::
    // This is multi-line, so we'll handle it by identifying start/end markers
    private let ticketStartPattern = #"^:::ticket\s*$"#
    private let ticketEndPattern = #"^:::\s*$"#
    
    // Project Block: :::project ... :::
    private let projectStartPattern = #"^:::project\s*$"#
    private let projectEndPattern = #"^:::\s*$"#
    
    // Attributes
    private let projectAttributePattern = #"@project\(([^)]+)\)"#
    private let estimateAttributePattern = #"@estimate\((\d+[hm])\)"#
    private let priorityAttributePattern = #"!(low|medium|high|critical)"#
    private let tagAttributePattern = #"#(\w+)"#
    private let idAttributePattern = #"\^([A-Z]+-\d+)"#

    // MARK: - Parsing    
    // MARK: - Parsing
    
    func parse(markdown: String) -> ParseResult {
        var tasks: [TaskItem] = []
        var tickets: [Ticket] = []
        var projects: [Project] = []
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
            
            // Task
            if let match = try? Regex(taskPattern).firstMatch(in: trimmed) {
                if let task = parseTask(match: match, index: i, originalText: trimmed) {
                    tasks.append(task)
                }
                i += 1
                continue
            }
            
            i += 1
        }
        
        return ParseResult(tasks: tasks, tickets: tickets, calendarEntries: [], projects: projects, metadata: metadata)
    }
    
    // MARK: - Private Helpers
    
    private func parseTask(match: Regex<AnyRegexOutput>.Match, index: Int, originalText: String) -> TaskItem? {
        // Group 1: State, Group 2: Title, Group 3: Attributes string
        
        let state = String(match[1].substring ?? "")
        let title = String(match[2].substring ?? "")
        let attributesStr = String(match[3].substring ?? "")
        
        var task = TaskItem(
            title: title.trimmingCharacters(in: .whitespaces),
            index: index,
            isCompleted: state == "x",
            originalText: originalText
        )
        
        parseAttributes(attributesStr, into: &task)
        
        return task
    }
    
    private func parseAttributes(_ attributes: String, into task: inout TaskItem) {
        if let match = try? Regex(projectAttributePattern).firstMatch(in: attributes),
           let substr = match[1].substring {
            task.project = String(substr)
        }

        if let match = try? Regex(estimateAttributePattern).firstMatch(in: attributes) {
             // TODO: parsing duration string
        }
        
        if let match = try? Regex(priorityAttributePattern).firstMatch(in: attributes),
           let substr = match[1].substring,
           let priority = Priority(rawValue: String(substr)) {
            task.priority = priority
        }
        
        // Tags - find all
        let tagMatches = attributes.matches(of: try! Regex(tagAttributePattern))
        for match in tagMatches {
            if let substr = match[1].substring {
                task.tags.append(String(substr))
            }
        }
        
        if let match = try? Regex(idAttributePattern).firstMatch(in: attributes),
           let substr = match[1].substring {
            task.linkedTicketID = String(substr)
        }
    }
    
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
                   (try? Regex(projectStartPattern).firstMatch(in: trimmed)) != nil ||
                   (try? Regex(taskPattern).firstMatch(in: trimmed)) != nil {
                     break
                }
                body.append(line)
            }
            i += 1
        }
        
        var ticket = Ticket(identifier: "UNKNOWN", status: .open)
        
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
}
