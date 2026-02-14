
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
                    currentNoteTasks = []
                    currentNoteTickets = []
                }
            }
        }
    }
    
    // Tasks/tickets from the currently selected note
    @Published var currentNoteTasks: [TaskItem] = []
    @Published var currentNoteTickets: [Ticket] = []
    
    // Incremented when content is changed programmatically (not by typing)
    @Published var contentVersion: Int = 0
    
    @Published var errorMessage: String?
    
    // Cache for parsed items to improve performance
    private var tasksCache: [UUID: [TaskItem]] = [:]
    private var ticketsCache: [UUID: [Ticket]] = [:]
    
    // Aggregated tasks/tickets across ALL notes, with source note ID
    var allTasks: [(task: TaskItem, sourceNoteID: UUID)] {
        notes.flatMap { note in
            (tasksCache[note.id] ?? []).map { ($0, note.id) }
        }
    }
    
    var allTickets: [(ticket: Ticket, sourceNoteID: UUID)] {
        notes.flatMap { note in
            (ticketsCache[note.id] ?? []).map { ($0, note.id) }
        }
    }
    
    // Convenience counts
    var totalTaskCount: Int { allTasks.count }
    var totalTicketCount: Int { allTickets.count }
    
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
            
            for url in fileURLs {
                let filename = url.lastPathComponent
                
                if filename.hasPrefix("note_") && filename.hasSuffix(".json") {
                    if let data = try? Data(contentsOf: url),
                       let note = try? JSONDecoder().decode(Note.self, from: data) {
                        loadedNotes.append(note)
                        // Populate cache
                        let result = parser.parse(markdown: note.content)
                        tasksCache[note.id] = result.tasks
                        ticketsCache[note.id] = result.tickets
                    }
                } else if filename.hasPrefix("journal_") && filename.hasSuffix(".json") {
                    // Migration / Legacy Support
                    if let data = try? Data(contentsOf: url),
                       let entry = try? JSONDecoder().decode(JournalEntry.self, from: data) {
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
                        tasksCache[note.id] = result.tasks
                        ticketsCache[note.id] = result.tickets
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
    
    func createNote() {
        var newNote = Note(
            title: "New Note",
            content: "",
            createdAt: Date(),
            modifiedAt: Date(),
            journalDate: nil
        )
        let entry = NoteHistoryEntry(timestamp: Date(), title: newNote.title, contentSnapshot: "", summary: "Created")
        newNote.history.append(entry)
        notes.insert(newNote, at: 0)
        selectedNote = newNote
        tasksCache[newNote.id] = []
        ticketsCache[newNote.id] = []
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
        tasksCache[note.id] = result.tasks
        ticketsCache[note.id] = result.tickets
        
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
        // (Implementation omitted for brevity, but would be good to clean up)
    }

    func toggleTask(_ task: TaskItem, sourceNoteID: UUID) {
        guard var note = notes.first(where: { $0.id == sourceNoteID }) else { return }
        
        var lines = note.content.components(separatedBy: "\n")
        
        // Safety check: index must be within bounds
        guard task.index < lines.count else {
            print("Error: Task index \(task.index) out of bounds")
            return
        }
        
        let targetLine = lines[task.index]
        let trimmedTarget = targetLine.trimmingCharacters(in: .whitespaces)
        
        // Verify identity: The line at index must match the original text we parsed
        // We use trimmed comparison to ignore indentation differences if any (though parser stores trimmed)
        if trimmedTarget != task.originalText {
             // Fallback: The file might have changed. Try to find the line?
             // For now, fail safely to avoid checking the wrong box.
             print("Error: Task line mismatch at index \(task.index). Expected '\(task.originalText)', found '\(trimmedTarget)'")
             return
        }
        
        // Toggle the checkbox
        // We need to preserve original indentation
        if task.isCompleted {
            lines[task.index] = targetLine.replacingOccurrences(of: "- [x] ", with: "- [ ] ")
        } else {
            lines[task.index] = targetLine.replacingOccurrences(of: "- [ ] ", with: "- [x] ")
        }
        
        // Reconstruct content
        let newContent = lines.joined(separator: "\n")
        note.content = newContent
        note.modifiedAt = Date()
        
        // Update Cache
        let result = parser.parse(markdown: newContent)
        tasksCache[note.id] = result.tasks
        ticketsCache[note.id] = result.tickets
        
        if let noteIndex = notes.firstIndex(where: { $0.id == note.id }) {
            notes[noteIndex] = note
        }
        
        // If this is the selected note, update it too
        if selectedNote?.id == note.id {
            selectedNote = note
            parseCurrentNote(newContent)
        }
        
        saveNote(note)
        contentVersion += 1
    }
    

    
    // Navigate to the note that contains a specific task/ticket
    func navigateToNote(id: UUID) {
        if let note = notes.first(where: { $0.id == id }) {
            selectedNote = note
        }
    }
    
    // Insert a new task markdown template into the current note
    func insertTaskMarkdown() {
        guard var note = selectedNote else { return }
        let template = "\n- [ ] \n"
        note.content += template
        note.modifiedAt = Date()
        
        // Update Cache
        let result = parser.parse(markdown: note.content)
        tasksCache[note.id] = result.tasks
        ticketsCache[note.id] = result.tickets
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        parseCurrentNote(note.content)
        saveNote(note)
        contentVersion += 1
    }
    
    // Insert a new ticket markdown template into the current note
    func insertTicketMarkdown() {
        guard var note = selectedNote else { return }
        let template = "\n:::ticket\nID: \nTitle: \nStatus: \n:::\n"
        note.content += template
        note.modifiedAt = Date()
        
        // Update Cache
        let result = parser.parse(markdown: note.content)
        tasksCache[note.id] = result.tasks
        ticketsCache[note.id] = result.tickets
        
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        selectedNote = note
        parseCurrentNote(note.content)
        saveNote(note)
        contentVersion += 1
    }
    
    private func parseCurrentNote(_ text: String) {
        let result = parser.parse(markdown: text)
        self.currentNoteTasks = result.tasks
        self.currentNoteTickets = result.tickets
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
