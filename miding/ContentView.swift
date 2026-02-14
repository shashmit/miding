//
//  ContentView.swift
//  miding
//
//  Created by Shashmit on 14/02/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = NotesViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.doubleColumn
    @State private var selectedFolder: String? = "Dashboard"
    @State private var taskFilter = 0  // 0=All, 1=Active, 2=Completed
    @State private var ticketFilter = "all"  // all, open, in-progress, blocked, closed
    @State private var showDeleteConfirm = false
    @State private var topicsExpanded = true
    @State private var newTagText = ""
    @State private var editorText = ""
    @State private var editorTitle = ""
    @State private var showNoteHistory = false

    var body: some View {
        Group {
            if selectedFolder == "Dashboard" {
                NavigationSplitView {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
                } detail: {
                    dashboardView
                        #if os(macOS)
                        .toolbar(.hidden, for: .windowToolbar)
                        #endif
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
                } content: {
                    middleColumn
                        .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
                } detail: {
                    editorView
                }
                .navigationSplitViewStyle(.balanced)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .alert(item: Binding(get: {
            vm.errorMessage.map { ErrorWrapper(message: $0) }
        }, set: { _ in vm.errorMessage = nil })) { wrapper in
            Alert(title: Text("Error"), message: Text(wrapper.message))
        }
        .onChange(of: selectedFolder) { newValue in
            if newValue == "Dashboard" {
                vm.selectedNote = nil
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(selection: $selectedFolder) {
                librarySection
                topicsSection
                itemsSection
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // History pinned at the bottom
            Button {
                selectedFolder = "History"
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundStyle(selectedFolder == "History" ? .blue : .secondary)
                    Text("All History")
                        .font(.system(size: 12, weight: selectedFolder == "History" ? .semibold : .regular))
                        .foregroundStyle(selectedFolder == "History" ? .primary : .secondary)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedFolder == "History" ? Color.blue.opacity(0.1) : Color.clear)
                        .padding(.horizontal, 6)
                )
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("miding")
    }

    private var librarySection: some View {
        Section("Library") {
            NavigationLink(value: "Dashboard") {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }
            NavigationLink(value: "All Notes") {
                Label("All Notes", systemImage: "note.text")
            }
            NavigationLink(value: "Journal") {
                Label("Journal", systemImage: "book.closed")
            }
        }
    }

    private var itemsSection: some View {
        Section("Items") {
            NavigationLink(value: "Tasks") {
                HStack {
                    Label("Tasks", systemImage: "checklist")
                    Spacer()
                    if vm.totalTaskCount > 0 {
                        Text("\(vm.totalTaskCount)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.tertiary.opacity(0.3)))
                    }
                }
            }
            NavigationLink(value: "Tickets") {
                HStack {
                    Label("Tickets", systemImage: "ticket")
                    Spacer()
                    if vm.totalTicketCount > 0 {
                        Text("\(vm.totalTicketCount)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.tertiary.opacity(0.3)))
                    }
                }
            }
        }
    }

    private var versionControlSection: some View {
        Section("History") {
            NavigationLink(value: "History") {
                Label("All History", systemImage: "clock.arrow.circlepath")
            }
        }
    }
    
    private var topicsSection: some View {
        Section(isExpanded: $topicsExpanded) {
            ForEach(allTopics, id: \.self) { topic in
                HStack {
                    Label(topic, systemImage: "number")
                    Spacer()
                    let count = vm.notes.filter { $0.tags.contains(topic) && $0.journalDate == nil }.count
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.tertiary.opacity(0.3)))
                    }
                }
                .tag("topic:\(topic)")
            }
        } header: {
            Text("Topics")
        }
    }
    
    private var allTopics: [String] {
        let tags = vm.notes.flatMap { $0.tags }
        let unique = Array(Set(tags)).sorted()
        return unique
    }
    
    // MARK: - Middle Column
    
    @ViewBuilder
    private var middleColumn: some View {
        switch selectedFolder {
        case "Tasks":
            tasksListView
        case "Tickets":
            ticketsListView
        case "History":
            historyListView
        default:
            noteListView
        }
    }
    
    private var noteListView: some View {
        List(selection: $vm.selectedNote) {
            Text(middleColumnTitle)
                .font(.system(size: 28, weight: .bold))
                .padding(.vertical, 10)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            ForEach(displayedNotes) { note in
                NavigationLink(value: note) {
                    NoteRow(note: note)
                }
                .contextMenu {
                    Button(role: .destructive) {
                        vm.deleteNote(note)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Divider()
                    
                    Button {
                        vm.selectedNote = note
                    } label: {
                        Label("Open", systemImage: "doc.text")
                    }
                }
            }
            .onDelete(perform: deleteNotes)
        }
        .id(selectedFolder) // Force re-render when folder/topic changes
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: vm.createNote) {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Note")
            }
        }
    }
    
    @State private var showingSyntaxHelp = false

    private var tasksListView: some View {
        let allTasks = vm.allTasks
        
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Tasks")
                     .font(.headline)
                
                Spacer()
                
                Button(action: { showingSyntaxHelp.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Syntax Guide")
                .popover(isPresented: $showingSyntaxHelp) {
                    syntaxHelpView
                        .frame(width: 300, height: 400)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            tasksListContent(allTasks: allTasks)
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: vm.insertTaskMarkdown) {
                    Image(systemName: "plus")
                }
                .help("Add Task to Current Note")
                .disabled(vm.selectedNote == nil)
            }
        }
    }
    
    private func tasksListContent(allTasks: [(task: TaskItem, sourceNoteID: UUID)]) -> some View {
        let filtered: [(task: TaskItem, sourceNoteID: UUID)] = {
            switch taskFilter {
            case 1: return allTasks.filter { !$0.task.isCompleted }
            case 2: return allTasks.filter { $0.task.isCompleted }
            default: return allTasks
            }
        }()
        let activeCount = allTasks.filter { !$0.task.isCompleted }.count
        let completedCount = allTasks.filter { $0.task.isCompleted }.count
        
        return VStack(spacing: 0) {
            // Filter bar
            Picker("Filter", selection: $taskFilter) {
                Text("All (\(allTasks.count))").tag(0)
                Text("Active (\(activeCount))").tag(1)
                Text("Done (\(completedCount))").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider()
            
            if filtered.isEmpty {
                 emptyTasksView
            } else {
                List {
                    ForEach(filtered, id: \.task.id) { item in
                        taskRow(item: item)
                    }
                }
            }
        }
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: taskFilter == 2 ? "checkmark.circle" : "checklist")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(.quaternary)
            Text(taskFilter == 2 ? "No completed tasks" : taskFilter == 1 ? "All caught up!" : "No tasks yet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.tertiary)
            Text("Add tasks using - [ ] in your notes")
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func taskRow(item: (task: TaskItem, sourceNoteID: UUID)) -> some View {
        HStack(spacing: 10) {
            // Checkbox — toggles task directly
            Button {
                vm.toggleTask(item.task, sourceNoteID: item.sourceNoteID)
            } label: {
                Image(systemName: item.task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(item.task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Text area — navigates to note
            Button {
                vm.navigateToNote(id: item.sourceNoteID)
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.task.title)
                            .font(.system(size: 13, weight: .medium))
                            .strikethrough(item.task.isCompleted)
                            .foregroundStyle(item.task.isCompleted ? .secondary : .primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 6) {
                            // Source note
                            if let note = vm.notes.first(where: { $0.id == item.sourceNoteID }) {
                                Label(note.title, systemImage: "doc.text")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            
                            // Tags
                            ForEach(item.task.tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.blue.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // Priority pill
                        if let priority = item.task.priority {
                            Text(priority.rawValue.prefix(1).uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(priorityColor(priority)))
                        }
                        

                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                        .padding(.leading, 6)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
    
    private var syntaxHelpView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Task Syntax Guide")
                    .font(.headline)
                

                
                Group {
                    Text("Priority")
                        .font(.subheadline).bold()
                    Text("Use `!low`, `!medium`, `!high`, or `!critical`.")
                        .font(.caption)
                    Text("Example: `- [ ] Important task !high`")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Group {
                    Text("Tags")
                        .font(.subheadline).bold()
                    Text("Use `#tagname` for categorization.")
                        .font(.caption)
                    Text("Example: `- [ ] Email boss #work`")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding()
        }
    }
    
    private var ticketsListView: some View {
        let allTickets = vm.allTickets
        let filtered: [(ticket: Ticket, sourceNoteID: UUID)] = {
            if ticketFilter == "all" { return allTickets }
            return allTickets.filter { $0.ticket.status.rawValue == ticketFilter }
        }()
        
        let statusCounts: [String: Int] = {
            var counts: [String: Int] = [:]
            for item in allTickets {
                counts[item.ticket.status.rawValue, default: 0] += 1
            }
            return counts
        }()
        
        return VStack(spacing: 0) {
            // Jira-style status tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    StatusTab(label: "All", count: allTickets.count, isSelected: ticketFilter == "all", color: .primary) {
                        ticketFilter = "all"
                    }
                    StatusTab(label: "Open", count: statusCounts["open"] ?? 0, isSelected: ticketFilter == "open", color: .blue) {
                        ticketFilter = "open"
                    }
                    StatusTab(label: "In Progress", count: statusCounts["in-progress"] ?? 0, isSelected: ticketFilter == "in-progress", color: .orange) {
                        ticketFilter = "in-progress"
                    }
                    StatusTab(label: "Blocked", count: statusCounts["blocked"] ?? 0, isSelected: ticketFilter == "blocked", color: .red) {
                        ticketFilter = "blocked"
                    }
                    StatusTab(label: "Closed", count: statusCounts["closed"] ?? 0, isSelected: ticketFilter == "closed", color: .green) {
                        ticketFilter = "closed"
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "ticket")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(.quaternary)
                    Text(ticketFilter == "all" ? "No tickets" : "No \(ticketFilter) tickets")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(filtered, id: \.ticket.id) { item in
                        Button {
                            vm.navigateToNote(id: item.sourceNoteID)
                            selectedFolder = "All Notes"
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                // Top row: ID + Status + Priority
                                HStack(spacing: 6) {
                                    // Ticket ID badge
                                    Text(item.ticket.identifier)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundStyle(ticketStatusColor(item.ticket.status))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(ticketStatusColor(item.ticket.status).opacity(0.1))
                                        )
                                    
                                    Spacer()
                                    
                                    // Priority pill
                                    if let priority = item.ticket.priority {
                                        HStack(spacing: 3) {
                                            Image(systemName: priorityIcon(priority))
                                                .font(.system(size: 9))
                                            Text(priority.rawValue.capitalized)
                                                .font(.system(size: 10, weight: .medium))
                                        }
                                        .foregroundStyle(priorityColor(priority))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(priorityColor(priority).opacity(0.1))
                                        )
                                    }
                                    
                                    // Status pill
                                    Text(ticketStatusLabel(item.ticket.status))
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule().fill(ticketStatusColor(item.ticket.status))
                                        )
                                }
                                
                                // Title
                                if let title = item.ticket.title, !title.isEmpty {
                                    Text(title)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(2)
                                }
                                
                                // Bottom: owner + source note
                                HStack(spacing: 8) {
                                    if let owner = item.ticket.owner {
                                        Label(owner, systemImage: "person.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    if let due = item.ticket.dueDate {
                                        Label {
                                            Text(due, format: .dateTime.month(.abbreviated).day())
                                        } icon: {
                                            Image(systemName: "calendar")
                                        }
                                        .font(.system(size: 10))
                                        .foregroundStyle(due < Date() && item.ticket.status != .closed ? .red : .secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if let note = vm.notes.first(where: { $0.id == item.sourceNoteID }) {
                                        Label(note.title, systemImage: "doc.text")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Tickets")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: vm.insertTicketMarkdown) {
                    Image(systemName: "plus")
                }
                .help("Add Ticket to Current Note")
                .disabled(vm.selectedNote == nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    private func priorityIcon(_ p: Priority) -> String {
        switch p {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .critical: return "exclamationmark.2"
        }
    }
    
    private func ticketStatusColor(_ s: TicketStatus) -> Color {
        switch s {
        case .open: return .blue
        case .inProgress: return .orange
        case .blocked: return .red
        case .closed: return .green
        }
    }
    
    private func ticketStatusLabel(_ s: TicketStatus) -> String {
        switch s {
        case .open: return "OPEN"
        case .inProgress: return "IN PROGRESS"
        case .blocked: return "BLOCKED"
        case .closed: return "CLOSED"
        }
    }
    
    private var historyListView: some View {
        let history = vm.allHistory
        return List {
            if history.isEmpty {
                ContentUnavailableView {
                    Label("No History", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("History entries appear when you save notes.\nUse the save button (⬆) in the editor.")
                }
            } else {
                ForEach(history, id: \.entry.id) { item in
                    Button {
                        vm.navigateToNote(id: item.noteID)
                        selectedFolder = "All Notes"
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: item.entry.summary == "Created" ? "plus.circle.fill" : "arrow.up.circle.fill")
                                .foregroundStyle(item.entry.summary == "Created" ? .green : .blue)
                                .font(.system(size: 14))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.entry.summary)
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("·")
                                        .foregroundStyle(.quaternary)
                                    Text(item.noteTitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(item.entry.timestamp, format: .relative(presentation: .named))
                                    .font(.system(size: 11))
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.quaternary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("History")
    }
    
    private var displayedNotes: [Note] {
        if selectedFolder == "Journal" {
            return vm.journalNotes
        }
        if let folder = selectedFolder, folder.hasPrefix("topic:") {
            let topic = String(folder.dropFirst(6))
            return vm.notes.filter { $0.tags.contains(topic) && $0.journalDate == nil }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        }
        return vm.notes
    }
    
    private var middleColumnTitle: String {
        if let folder = selectedFolder, folder.hasPrefix("topic:") {
            return "#" + String(folder.dropFirst(6))
        }
        return selectedFolder ?? "Notes"
    }
    
    private func deleteNotes(offsets: IndexSet) {
        for index in offsets {
            vm.deleteNote(displayedNotes[index])
        }
    }

    // MARK: - Editor

    private var editorView: some View {
        Group {
            if let note = vm.selectedNote {
                VStack(spacing: 0) {
                    // Top bar: date stamp centered, actions on right
                    editorTopBar(note: note)
                    
                    // Formatting Toolbar
                    EditorToolbar(text: $editorText)
                    
                    // Writing Surface
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Title
                            TextField("Title", text: $editorTitle)
                                .font(.system(size: 26, weight: .bold))
                                .textFieldStyle(.plain)
                                .padding(.bottom, 6)
                            
                            // Metadata bar: date + tags
                            noteMetadataBar(note: note)
                                .padding(.bottom, 14)
                            
                            // Content
                            TextEditor(text: $editorText)
                                .font(.system(size: 15))
                                .lineSpacing(5)
                                .scrollContentBackground(.hidden)
                                .scrollDisabled(true)
                                .frame(minHeight: 500, maxHeight: .infinity)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 28)
                        .padding(.bottom, 60)
                    }
                }
                .onChange(of: editorText) { newValue in
                    vm.updateSelectedNote(content: newValue)
                }
                .onChange(of: editorTitle) { newValue in
                    vm.updateSelectedNoteTitle(newValue)
                }
                .onChange(of: vm.selectedNote?.id) { _ in
                    editorText = vm.selectedNote?.content ?? ""
                    editorTitle = vm.selectedNote?.title ?? ""
                }
                .onAppear {
                    editorText = note.content
                    editorTitle = note.title
                }
                .onChange(of: vm.contentVersion) { _ in
                    editorText = vm.selectedNote?.content ?? ""
                    editorTitle = vm.selectedNote?.title ?? ""
                }
            } else {
                ContentUnavailableView("Select a note", systemImage: "doc.text")
            }
        }
    }
    
    // MARK: - Dashboard (shown when no note is selected)
    
    private var dashboardView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dashboard")
                        .font(.system(size: 28, weight: .bold))
                    
                    HStack(spacing: 16) {
                        // Task summary pill
                        HStack(spacing: 5) {
                            Image(systemName: "checklist")
                                .font(.system(size: 11))
                            let active = vm.allTasks.filter { !$0.task.isCompleted }.count
                            Text("\(active) active task\(active == 1 ? "" : "s")")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(.blue.opacity(0.1))
                        )
                        
                        // Ticket summary pill
                        HStack(spacing: 5) {
                            Image(systemName: "ticket")
                                .font(.system(size: 11))
                            let openTickets = vm.allTickets.filter { $0.ticket.status != .closed }.count
                            Text("\(openTickets) open ticket\(openTickets == 1 ? "" : "s")")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(.orange.opacity(0.1))
                        )
                        
                        Spacer()
                        
                        Button(action: vm.createNote) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("New Note")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.blue)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)
                
                // Grid: Tasks & Tickets side by side
                HStack(alignment: .top, spacing: 20) {
                    
                    // ── Tasks Column ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Tasks", systemImage: "checklist")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(vm.allTasks.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.secondary.opacity(0.12)))
                        }
                        
                        Divider()
                        
                        let tasks = vm.allTasks
                        if tasks.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 28, weight: .thin))
                                    .foregroundStyle(.quaternary)
                                Text("No tasks yet")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.tertiary)
                                Text("Add tasks using - [ ] in your notes")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.quaternary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(tasks.prefix(15), id: \.task.id) { item in
                                    dashboardTaskCard(item: item)
                                }
                                
                                if tasks.count > 15 {
                                    Button {
                                        selectedFolder = "Tasks"
                                    } label: {
                                        Text("View all \(tasks.count) tasks →")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(.blue)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.separator.opacity(0.3), lineWidth: 1)
                    )
                    
                    // ── Tickets Column ──
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Tickets", systemImage: "ticket")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Text("\(vm.allTickets.count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(.secondary.opacity(0.12)))
                        }
                        
                        Divider()
                        
                        let tickets = vm.allTickets
                        if tickets.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "ticket")
                                    .font(.system(size: 28, weight: .thin))
                                    .foregroundStyle(.quaternary)
                                Text("No tickets yet")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.tertiary)
                                Text("Add ticket blocks in your notes")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.quaternary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(tickets.prefix(15), id: \.ticket.id) { item in
                                    dashboardTicketCard(item: item)
                                }
                                
                                if tickets.count > 15 {
                                    Button {
                                        selectedFolder = "Tickets"
                                    } label: {
                                        Text("View all \(tickets.count) tickets →")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(.blue)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.separator.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(uiColor: .systemBackground))
        #endif
    }
    
    private func dashboardTaskCard(item: (task: TaskItem, sourceNoteID: UUID)) -> some View {
        HStack(spacing: 10) {
            // Checkbox
            Button {
                vm.toggleTask(item.task, sourceNoteID: item.sourceNoteID)
            } label: {
                Image(systemName: item.task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(item.task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            // Task text — click to navigate
            Button {
                vm.navigateToNote(id: item.sourceNoteID)
                selectedFolder = "All Notes"
            } label: {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.task.title)
                            .font(.system(size: 12, weight: .medium))
                            .strikethrough(item.task.isCompleted)
                            .foregroundStyle(item.task.isCompleted ? .secondary : .primary)
                            .lineLimit(1)
                        
                        if let note = vm.notes.first(where: { $0.id == item.sourceNoteID }) {
                            Text(note.title)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer(minLength: 4)
                    
                    HStack(spacing: 6) {
                        // Priority
                        if let priority = item.task.priority {
                            Text(priority.rawValue.prefix(1).uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(Circle().fill(priorityColor(priority)))
                        }
                        

                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(item.task.isCompleted
                      ? Color.secondary.opacity(0.04)
                      : Color.blue.opacity(0.03))
        )
    }
    
    private func dashboardTicketCard(item: (ticket: Ticket, sourceNoteID: UUID)) -> some View {
        Button {
            vm.navigateToNote(id: item.sourceNoteID)
            selectedFolder = "All Notes"
        } label: {
            HStack(spacing: 10) {
                // Status color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(ticketStatusColor(item.ticket.status))
                    .frame(width: 4, height: 36)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        // Ticket identifier
                        Text(item.ticket.identifier)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(ticketStatusColor(item.ticket.status))
                        
                        Spacer()
                        
                        // Status pill
                        Text(ticketStatusLabel(item.ticket.status))
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(ticketStatusColor(item.ticket.status))
                            )
                    }
                    
                    if let title = item.ticket.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        if let owner = item.ticket.owner {
                            Label(owner, systemImage: "person.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                        
                        if let priority = item.ticket.priority {
                            HStack(spacing: 2) {
                                Image(systemName: priorityIcon(priority))
                                    .font(.system(size: 8))
                                Text(priority.rawValue.capitalized)
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundStyle(priorityColor(priority))
                        }
                        
                        Spacer()
                        
                        if let note = vm.notes.first(where: { $0.id == item.sourceNoteID }) {
                            Text(note.title)
                                .font(.system(size: 9))
                                .foregroundStyle(.quaternary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ticketStatusColor(item.ticket.status).opacity(0.04))
            )
        }
        .buttonStyle(.plain)
    }
    
    private func noteMetadataBar(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date row
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Text(note.createdAt, format: .dateTime.month(.wide).day().year())
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                if note.journalDate != nil {
                    Text("· Journal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.blue.opacity(0.7))
                }
            }
            
            // Tags row
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                
                // Existing tags
                ForEach(note.tags, id: \.self) { tag in
                    HStack(spacing: 3) {
                        Text("#\(tag)")
                            .font(.system(size: 11, weight: .medium))
                        
                        Button {
                            vm.removeTag(tag)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .bold))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(.blue.opacity(0.1))
                    )
                }
                
                // Add new tag field
                TextField("Add tag…", text: $newTagText)
                    .font(.system(size: 11))
                    .textFieldStyle(.plain)
                    .frame(maxWidth: 100)
                    .onSubmit {
                        if !newTagText.isEmpty {
                            vm.addTag(newTagText)
                            newTagText = ""
                        }
                    }
            }
        }
    }
    
    private func editorTopBar(note: Note) -> some View {
        HStack {
            // LEFT: History branch button
            HStack(spacing: 8) {
                Button { showNoteHistory.toggle() } label: {
                    HStack(spacing: 4) {
                        // Git branch icon
                        Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue.opacity(0.7))
                        
                        Text("\(note.history.count)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.blue.opacity(showNoteHistory ? 0.12 : 0.05))
                    )
                }
                .buttonStyle(.plain)
                .help("Note History")
                .popover(isPresented: $showNoteHistory, arrowEdge: .bottom) {
                    noteHistoryPopover(note: note)
                }
                
                // Save snapshot button
                Button {
                    vm.saveSnapshot(summary: "Manual save")
                    // Refresh editorText since history was added
                    editorText = vm.selectedNote?.content ?? editorText
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                        Text("Snapshot")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.secondary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .help("Save a snapshot of the current content")
            }
            
            Spacer()
            
            // CENTER: Date
            Group {
                if let journalDate = note.journalDate {
                    Text(journalDate, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                } else {
                    Text(note.modifiedAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().year())
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.tertiary)
            
            Spacer()
            
            // RIGHT: Save & Delete
            HStack(spacing: 12) {
                Button { Task { await vm.saveAndCommit() } } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Save")
                .keyboardShortcut("s", modifiers: .command)
                
                Rectangle()
                    .fill(.separator.opacity(0.3))
                    .frame(width: 1, height: 14)
                
                Button { showDeleteConfirm = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Delete Note")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .alert("Delete Note", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let note = vm.selectedNote {
                    vm.deleteNote(note)
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(note.title)\"? This cannot be undone.")
        }
    }
    
    private func noteHistoryPopover(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                    .foregroundStyle(.blue)
                Text("History")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(note.history.count) snapshots")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            Divider()
            
            if note.history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24, weight: .thin))
                        .foregroundStyle(.quaternary)
                    Text("No history yet")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                    Text("Use Snapshot or Save to create history")
                        .font(.system(size: 10))
                        .foregroundStyle(.quaternary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(note.history.reversed().enumerated()), id: \.element.id) { index, entry in
                            HStack(alignment: .top, spacing: 10) {
                                // Git-style branch line
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(index == 0 ? Color.blue : Color.secondary.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                    if index < note.history.count - 1 {
                                        Rectangle()
                                            .fill(.secondary.opacity(0.2))
                                            .frame(width: 1.5)
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                .frame(width: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.summary)
                                        .font(.system(size: 12, weight: index == 0 ? .semibold : .regular))
                                        .foregroundStyle(index == 0 ? .primary : .secondary)
                                    
                                    Text(entry.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                        .font(.system(size: 10))
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            
                            if index < note.history.count - 1 {
                                Divider()
                                    .padding(.leading, 32)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .frame(width: 280)
    }
}

// MARK: - Subviews

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .font(.system(size: 13))
                
            }
        }
        .padding(.vertical, 2)
    }
}

struct TicketRow: View {
    let ticket: Ticket
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "ticket.fill")
                .foregroundStyle(.blue)
                .font(.system(size: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(ticket.identifier)
                    .font(.system(size: 12, weight: .semibold))
                if let title = ticket.title {
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct NoteRow: View {
    let note: Note
    
    private var previewText: String {
        let cleaned = note.content
            .components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .prefix(2)
            .joined(separator: " ")
        if cleaned.count > 60 {
            return String(cleaned.prefix(60)) + "…"
        }
        return cleaned.isEmpty ? "No additional text" : cleaned
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(note.title)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Text(note.modifiedAt, format: .dateTime.hour().minute())
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Text(previewText)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 1)
    }
}

private struct StatusTab: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? color : .secondary)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(isSelected ? .white : .secondary)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(isSelected ? color : Color.secondary.opacity(0.2))
                            )
                    }
                }
                
                Rectangle()
                    .fill(isSelected ? color : Color.clear)
                    .frame(height: 2)
                    .cornerRadius(1)
            }
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct ErrorWrapper: Identifiable { let id = UUID(); let message: String }

#Preview {
    ContentView()
}
