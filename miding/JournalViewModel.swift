
import SwiftUI
import Combine

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNote: Note? {
        didSet {
            // Only parse when switching to a different note (not on content edits)
            if selectedNote?.id != oldValue?.id {
                if let note = selectedNote {
                    parseCurrentNote(note.content)
                } else {
                    currentNoteTickets = []
                }
            }
        }
    }
    
    // Tickets from the currently selected note
    @Published var currentNoteTickets: [Ticket] = []
    @Published var currentNoteTasks: [TaskItem] = []
    
    // Incremented when content is changed programmatically (not by typing)
    @Published var contentVersion: Int = 0
    
    @Published var errorMessage: String?
    
    // Cache for parsed items to improve performance
    private var ticketsCache: [UUID: [Ticket]] = [:]
    private var tasksCache: [UUID: [TaskItem]] = [:]
    
    // Aggregated tickets across ALL notes, with source note ID
    var allTickets: [(ticket: Ticket, sourceNoteID: UUID)] {
        notes.flatMap { note in
            (ticketsCache[note.id] ?? []).map { ($0, note.id) }
        }
    }
    
    // Aggregated tasks across ALL notes, with source note ID
    var allTasks: [(task: TaskItem, sourceNoteID: UUID)] {
        notes.flatMap { note in
            (tasksCache[note.id] ?? []).map { ($0, note.id) }
        }
    }
    
    // Convenience counts
    var totalTicketCount: Int { allTickets.count }
    var totalTaskCount: Int { allTasks.count }
    var pendingTaskCount: Int { allTasks.filter { !$0.task.isCompleted }.count }
    
    // Aggregated history across ALL notes, sorted newest first
    var allHistory: [(entry: NoteHistoryEntry, noteTitle: String, noteID: UUID)] {
        var result: [(NoteHistoryEntry, String, UUID)] = []
        for note in notes {
            for entry in note.history {
                result.append((entry, note.title, note.id))
            }
        }
        return result.sorted { $0.0.timestamp > $1.0.timestamp }
    }
    
    // Filter helper for Journal View
    var journalNotes: [Note] {
        notes.filter { $0.journalDate != nil }.sorted { ($0.journalDate ?? Date()) > ($1.journalDate ?? Date()) }
    }
    
    private let parser = MarkdownParser()
    private let fileManager = FileManager.default
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var saveDebouncer: AnyCancellable?
    private let contentSubject = PassthroughSubject<String, Never>()
    
    init() {
        // Debounce content changes: parse + save after 0.5s of no typing
        saveDebouncer = contentSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] content in
                self?.debouncedContentUpdate(content)
            }
        Task { await loadNotes() }
    }
    
    func loadNotes() async {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            var loadedNotes: [Note] = []
            
            let noteFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("note_") && $0.lastPathComponent.hasSuffix(".json") }
            let journalFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("journal_") && $0.lastPathComponent.hasSuffix(".json") }
            
            // 1. Load existing notes first
            for url in noteFiles {
                if let data = try? Data(contentsOf: url),
                   let note = try? JSONDecoder().decode(Note.self, from: data) {
                    loadedNotes.append(note)
                    // Populate cache
                    let result = parser.parse(markdown: note.content)
                    ticketsCache[note.id] = result.tickets
                    tasksCache[note.id] = result.tasks
                }
            }
            
            // 2. Load legacy journals only if not already present
            for url in journalFiles {
                // Migration / Legacy Support
                if let data = try? Data(contentsOf: url),
                   let entry = try? JSONDecoder().decode(JournalEntry.self, from: data) {
                    
                    // Check if we already loaded this note (by ID)
                    if !loadedNotes.contains(where: { $0.id == entry.id }) {
                        let note = Note(
                            id: entry.id,
                            title: "Journal \(formatDate(entry.date))",
                            content: entry.rawMarkdown,
                            createdAt: entry.date, // Approx
                            modifiedAt: Date(),
                            journalDate: entry.date,
                            tags: entry.metadata?.tags ?? []
                        )
                        loadedNotes.append(note)
                        // Populate cache
                        let result = parser.parse(markdown: note.content)
                        ticketsCache[note.id] = result.tickets
                        tasksCache[note.id] = result.tasks
                        
                        // Save the migrated note as a standard note immediately
                        saveNote(note)
                    }
                }
            }
            
            self.notes = loadedNotes.sorted { $0.modifiedAt > $1.modifiedAt }
            
            // Select first note if none selected
             if selectedNote == nil, let first = notes.first {
                selectedNote = first
                // Parse current note to update observable properties
                parseCurrentNote(first.content)
            }
        } catch {
            errorMessage = "Failed to load notes: \(error.localizedDescription)"
        }
    }
    
    func createNote(isJournal: Bool = false) {
        let title = isJournal ? "Journal \(formatDate(Date()))" : "New Note"
        var newNote = Note(
            title: title,
            content: "",
            createdAt: Date(),
            modifiedAt: Date(),
            journalDate: isJournal ? Date() : nil
        )
        let entry = NoteHistoryEntry(timestamp: Date(), title: newNote.title, contentSnapshot: "", summary: "Created")
        newNote.history.append(entry)
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        ticketsCache[newNote.id] = []
        tasksCache[newNote.id] = []
        saveNote(newNote)
    }
    
    func updateSelectedNote(content: String) {
        // Only fire debounce — do NOT touch @Published properties here
        // The @State in ContentView holds the live text, so no sync needed during typing
        contentSubject.send(content)
    }
    
    private func debouncedContentUpdate(_ content: String) {
        guard var note = selectedNote else { return }
        note.content = content
        note.modifiedAt = Date()
        
        // Update cache immediately
        let result = parser.parse(markdown: content)
        ticketsCache[note.id] = result.tickets
        tasksCache[note.id] = result.tasks
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        
        parseCurrentNote(content)
        saveNote(note)
    }
    
    func updateSelectedNoteTitle(_ title: String) {
        guard var note = selectedNote else { return }
        note.title = title
        note.modifiedAt = Date()
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        saveNote(note)
    }
    
    func addTag(_ tag: String) {
        guard var note = selectedNote else { return }
        let cleaned = tag.trimmingCharacters(in: .whitespaces).lowercased()
            .replacingOccurrences(of: "#", with: "")
        guard !cleaned.isEmpty, !note.tags.contains(cleaned) else { return }
        note.tags.append(cleaned)
        note.modifiedAt = Date()
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        saveNote(note)
    }
    
    func removeTag(_ tag: String) {
        guard var note = selectedNote else { return }
        note.tags.removeAll { $0 == tag }
        note.modifiedAt = Date()
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        saveNote(note)
    }

    func saveNote(_ note: Note) {
        let url = documentsURL.appendingPathComponent("note_\(note.id.uuidString).json")
        do {
            let data = try JSONEncoder().encode(note)
            try data.write(to: url)
        } catch {
            errorMessage = "Failed to save note: \(error.localizedDescription)"
        }
    }
    
    func saveAndCommit() async {
        guard var note = selectedNote else { return }
        // Record a history entry
        let entry = NoteHistoryEntry(
            timestamp: Date(),
            title: note.title,
            contentSnapshot: note.content,
            summary: "Saved"
        )
        note.history.append(entry)
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        saveNote(note)
        contentVersion += 1
    }
    
    func saveSnapshot(summary: String = "Snapshot") {
        guard var note = selectedNote else { return }
        let entry = NoteHistoryEntry(
            timestamp: Date(),
            title: note.title,
            contentSnapshot: note.content,
            summary: summary
        )
        note.history.append(entry)
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        saveNote(note)
        contentVersion += 1
    }
    
    func deleteNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes.remove(at: index)
        }
        
        if selectedNote?.id == note.id {
            selectedNote = notes.first
        }
        
        let url = documentsURL.appendingPathComponent("note_\(note.id.uuidString).json")
        try? fileManager.removeItem(at: url)
        
        // Also try legacy path if it exists
        let legacyUrl = documentsURL.appendingPathComponent("journal_\(note.id.uuidString).json")
        try? fileManager.removeItem(at: legacyUrl)
        
        if let date = note.journalDate {
            let dateStr = formatDate(date)
            let dateUrl = documentsURL.appendingPathComponent("journal_\(dateStr).json")
            try? fileManager.removeItem(at: dateUrl)
        }
    }

    // Navigate to the note that contains a specific ticket
    func navigateToNote(id: UUID) {
        if let note = notes.first(where: { $0.id == id }) {
            selectedNote = note
        }
    }
    
    // Insert a new ticket markdown template into the current note
    func insertTicketMarkdown() {
        guard var note = selectedNote else { return }
        let template = "\n:::ticket\nID: \nTitle: \nStatus: \n:::\n"
        note.content += template
        note.modifiedAt = Date()
        
        // Update Cache
        let result = parser.parse(markdown: note.content)
        ticketsCache[note.id] = result.tickets
        tasksCache[note.id] = result.tasks
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        parseCurrentNote(note.content)
        saveNote(note)
        contentVersion += 1
    }
    
    // Toggle a task checkbox and persist the change
    func toggleTask(_ task: TaskItem, inNoteID noteID: UUID) {
        guard var note = notes.first(where: { $0.id == noteID }) else { return }
        note.content = MarkdownParser.toggleTask(in: note.content, atLineIndex: task.lineIndex)
        note.modifiedAt = Date()
        
        // Update cache
        let result = parser.parse(markdown: note.content)
        ticketsCache[note.id] = result.tickets
        tasksCache[note.id] = result.tasks
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        if selectedNote?.id == note.id {
            selectedNote = note
            parseCurrentNote(note.content)
            contentVersion += 1
        }
        saveNote(note)
    }
    
    func updateTicketStatus(_ ticket: Ticket, to status: TicketStatus, inNoteID noteID: UUID) {
        // 1. Find the note
        guard var note = notes.first(where: { $0.id == noteID }) else { return }
        
        // 2. Validate line numbers
        guard let start = ticket.blockStartLine, let end = ticket.blockEndLine else {
            errorMessage = "Cannot update ticket: missing line information."
            return
        }
        
        // 3. Update the content
        var lines = note.content.components(separatedBy: .newlines)
        guard start < lines.count, end < lines.count, start <= end else {
            errorMessage = "Cannot update ticket: content has changed."
            return
        }
        
        var statusIndex: Int?
        var closedIndex: Int?
        
        // Find indices
        for i in start...end {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            if trimmed.hasPrefix("status:") {
                statusIndex = i
            } else if trimmed.hasPrefix("closed:") {
                closedIndex = i
            }
        }
        
        // Update Status line
        if let idx = statusIndex {
            let line = lines[idx]
            let prefix = line.prefix(while: { $0.isWhitespace })
            lines[idx] = "\(prefix)Status: \(status.rawValue)"
        } else {
            errorMessage = "Could not find Status field in ticket block."
            return
        }
        
        // Handle Closed Date line
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        if status == .closed {
            let dateStr = dateFormatter.string(from: Date())
            if let idx = closedIndex {
                // Update existing Closed line
                let line = lines[idx]
                let prefix = line.prefix(while: { $0.isWhitespace })
                lines[idx] = "\(prefix)Closed: \(dateStr)"
            } else {
                // Insert new Closed line after Status
                if let idx = statusIndex {
                    let line = lines[idx]
                    let prefix = line.prefix(while: { $0.isWhitespace })
                    lines.insert("\(prefix)Closed: \(dateStr)", at: idx + 1)
                }
            }
        } else {
            // Remove Closed line if present (since it's no longer closed)
            if let idx = closedIndex {
                lines.remove(at: idx)
            }
        }
        
        note.content = lines.joined(separator: "\n")
        note.modifiedAt = Date()
        
        // 4. Update Cache & State
        let result = parser.parse(markdown: note.content)
        ticketsCache[note.id] = result.tickets
        tasksCache[note.id] = result.tasks
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        
        if selectedNote?.id == note.id {
            selectedNote = note
            parseCurrentNote(note.content)
            contentVersion += 1
        }
        
        saveNote(note)
    }

    private func parseCurrentNote(_ text: String) {
        let result = parser.parse(markdown: text)
        self.currentNoteTickets = result.tickets
        self.currentNoteTasks = result.tasks
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

