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
    @State private var ticketFilter = "all"  // all, open, in-progress, blocked, closed
    @State private var taskFilter = "all"    // all, pending, done
    @State private var showDeleteConfirm = false
    @State private var topicsExpanded = true
    @State private var newTagText = ""
    @State private var editorText = ""
    @State private var editorTitle = ""
    @State private var showNoteHistory = false
    @State private var isZenMode = false

    var body: some View {
        ZStack {
            if !isZenMode {
                mainLayout
                    .transition(.opacity)
            }
            
            if isZenMode {
                editorView
                    #if os(macOS)
                    .background(Color(nsColor: .windowBackgroundColor))
                    #else
                    .background(Color(uiColor: .systemBackground))
                    #endif
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(100)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .alert(item: Binding(get: {
            vm.errorMessage.map { ErrorWrapper(message: $0) }
        }, set: { _ in vm.errorMessage = nil })) { wrapper in
            Alert(title: Text("Error"), message: Text(wrapper.message))
        }
        .onChange(of: selectedFolder) { _, newValue in
            if ["Dashboard", "Workstream", "Tasks", "Tickets"].contains(newValue) {
                vm.selectedNote = nil
            }
        }
    }

    private var mainLayout: some View {
        Group {
            if selectedFolder == "Dashboard" || selectedFolder == "Workstream" || selectedFolder == "Tasks" || selectedFolder == "Tickets" {
                NavigationSplitView {
                    sidebar
                        .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
                } detail: {
                    if selectedFolder == "Workstream" {
                        TaskTimelineView(vm: vm) { noteID in
                            vm.navigateToNote(id: noteID)
                            selectedFolder = "All Notes"
                        }
                        #if os(macOS)
                        .toolbar(.hidden, for: .windowToolbar)
                        #endif
                        .navigationTitle("Workstream")
                    } else if selectedFolder == "Tasks" {
                        tasksListView
                        #if os(macOS)
                        .toolbar(.hidden, for: .windowToolbar)
                        #endif
                    } else if selectedFolder == "Tickets" {
                        ticketsListView
                        #if os(macOS)
                        .toolbar(.hidden, for: .windowToolbar)
                        #endif
                    } else {
                        dashboardView
                        #if os(macOS)
                        .toolbar(.hidden, for: .windowToolbar)
                        #endif
                        .navigationTitle("Dashboard")
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                HStack {
                                    Button {
                                        vm.createNote(isJournal: true)
                                        selectedFolder = "Journal"
                                    } label: {
                                        Label("New Journal", systemImage: "book.closed")
                                    }
                                    .help("New Journal Entry")
                                    
                                    Button {
                                        vm.createNote(isJournal: false)
                                        selectedFolder = "All Notes"
                                    } label: {
                                        Label("New Note", systemImage: "square.and.pencil")
                                    }
                                    .help("New Note")
                                }
                            }
                        }
                    }
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
            NavigationLink(value: "Workstream") {
                Label("Workstream", systemImage: "chart.bar.xaxis")
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
                    if vm.pendingTaskCount > 0 {
                        Text("\(vm.pendingTaskCount)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(.orange))
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
        case "History":
            historyListView
        case "Workstream", "Tasks", "Tickets", "Dashboard":
            // Handled in detail pane (fullscreen), shouldn't reach here
            EmptyView()
        default:
            noteListView
        }
    }
    
    private var noteListView: some View {
        List(selection: $vm.selectedNote) {
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
        .navigationTitle(middleColumnTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    if selectedFolder != "Journal" {
                        Button {
                            vm.createNote(isJournal: true)
                            // Auto-switch to Journal view so the user sees the right context
                            selectedFolder = "Journal"
                        } label: {
                            Image(systemName: "book.closed")
                        }
                        .help("New Journal Entry")
                    }
                    
                    Button {
                        vm.createNote(isJournal: selectedFolder == "Journal")
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .help(selectedFolder == "Journal" ? "New Journal Entry" : "New Note")
                }
            }
        }
    }
    

    
    @State private var ticketViewMode: String = "list" // "list" or "board"

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
            // Jira-style status tabs + View Switcher
            VStack(spacing: 0) {
                HStack {
                   Picker("View", selection: $ticketViewMode) {
                       Image(systemName: "list.bullet").tag("list")
                       Image(systemName: "square.grid.3x3.fill").tag("board")
                   }
                   .pickerStyle(.segmented)
                   .frame(width: 100)
                   .padding(.leading, 12)
                   
                   Spacer()
                }
                .padding(.vertical, 8)
                
                if ticketViewMode == "list" {
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
                }
            }
            
            if ticketViewMode == "board" {
                TicketBoardView(vm: vm) { noteID in
                    vm.navigateToNote(id: noteID)
                    selectedFolder = "All Notes"
                }
                .padding(.top, 8)
            } else {
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
    
    // MARK: - Tasks List View
    
    private var tasksListView: some View {
        let all = vm.allTasks
        let filtered: [(task: TaskItem, sourceNoteID: UUID)] = {
            switch taskFilter {
            case "pending": return all.filter { !$0.task.isCompleted }
            case "done": return all.filter { $0.task.isCompleted }
            default: return all
            }
        }()
        
        let pendingCount = all.filter { !$0.task.isCompleted }.count
        let doneCount = all.filter { $0.task.isCompleted }.count
        
        return VStack(spacing: 0) {
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    StatusTab(label: "All", count: all.count, isSelected: taskFilter == "all", color: .primary) {
                        taskFilter = "all"
                    }
                    StatusTab(label: "Pending", count: pendingCount, isSelected: taskFilter == "pending", color: .orange) {
                        taskFilter = "pending"
                    }
                    StatusTab(label: "Done", count: doneCount, isSelected: taskFilter == "done", color: .green) {
                        taskFilter = "done"
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "checklist")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(.quaternary)
                    Text(taskFilter == "all" ? "No tasks" : "No \(taskFilter) tasks")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.tertiary)
                    Text("Add tasks with - [ ] in your notes")
                        .font(.system(size: 11))
                        .foregroundStyle(.quaternary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(filtered, id: \.task.id) { item in
                         HStack(spacing: 10) {
                            // Checkbox toggle
                            Button {
                                vm.toggleTask(item.task, inNoteID: item.sourceNoteID)
                            } label: {
                                Image(systemName: item.task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundStyle(item.task.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            // Entire row — tap to navigate to source note
                            Button {
                                vm.navigateToNote(id: item.sourceNoteID)
                                selectedFolder = "All Notes"
                            } label: {
                                HStack(spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            // Priority dot
                                            if let p = item.task.priority {
                                                Circle()
                                                    .fill(priorityColor(p))
                                                    .frame(width: 7, height: 7)
                                            }
                                            
                                            Text(item.task.text)
                                                .font(.system(size: 13, weight: .medium))
                                                .strikethrough(item.task.isCompleted)
                                                .foregroundStyle(item.task.isCompleted ? .secondary : .primary)
                                                .lineLimit(2)
                                        }
                                        
                                        // Metadata row: date, time, category, source note
                                        HStack(spacing: 8) {
                                            if let dueDate = item.task.dueDate {
                                                let isOverdue = !item.task.isCompleted && Calendar.current.startOfDay(for: dueDate) < Calendar.current.startOfDay(for: Date())
                                                Label {
                                                    Text(dueDate, format: .dateTime.month(.abbreviated).day())
                                                } icon: {
                                                    Image(systemName: "calendar")
                                                }
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundStyle(isOverdue ? .red : .secondary)
                                            }
                                            
                                            if let dueTime = item.task.dueTime {
                                                Label {
                                                    Text(dueTime, format: .dateTime.hour().minute())
                                                } icon: {
                                                    Image(systemName: "clock")
                                                }
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                            }
                                            
                                            if let cat = item.task.category {
                                                Text(cat)
                                                    .font(.system(size: 9, weight: .semibold))
                                                    .foregroundStyle(.blue)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 1)
                                                    .background(Capsule().fill(.blue.opacity(0.1)))
                                            }
                                            
                                            if let note = vm.notes.first(where: { $0.id == item.sourceNoteID }) {
                                                Spacer()
                                                Label(note.title, systemImage: "doc.text")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.tertiary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.quaternary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Tasks")
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
                        .padding(.top, isZenMode ? 12 : 0)
                        .padding(.horizontal, isZenMode ? 20 : 0)
                    
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
                        .frame(maxWidth: isZenMode ? 750 : .infinity)
                        .padding(.horizontal, 40)
                        .padding(.top, isZenMode ? 50 : 28)
                        .padding(.bottom, 60)
                        .frame(maxWidth: .infinity) // Center content
                    }
                }
                .onChange(of: editorText) { _, newValue in
                    vm.updateSelectedNote(content: newValue)
                }
                .onChange(of: editorTitle) { _, newValue in
                    vm.updateSelectedNoteTitle(newValue)
                }
                .onChange(of: vm.selectedNote?.id) { _, _ in
                    editorText = vm.selectedNote?.content ?? ""
                    editorTitle = vm.selectedNote?.title ?? ""
                }
                .onAppear {
                    editorText = note.content
                    editorTitle = note.title
                }
                .onChange(of: vm.contentVersion) { _, _ in
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
        DashboardView(notesViewModel: vm) { noteId in
            vm.navigateToNote(id: noteId)
            selectedFolder = "All Notes"
        }
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
                // Zen Mode Toggle
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isZenMode.toggle()
                    }
                } label: {
                    Image(systemName: isZenMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 12))
                        .foregroundStyle(isZenMode ? Color.blue : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(isZenMode ? "Exit Zen Mode" : "Enter Zen Mode")
                .keyboardShortcut("f", modifiers: [.command, .shift])
                
                Rectangle()
                    .fill(.separator.opacity(0.3))
                    .frame(width: 1, height: 14)
                
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


private struct ErrorWrapper: Identifiable { let id = UUID(); let message: String }

#Preview {
    ContentView()
}
