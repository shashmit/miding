
import SwiftUI

struct TicketDetailView: View {
    @Binding var ticket: Ticket
    @State private var viewMode: ViewMode = .normal
    
    enum ViewMode: String, CaseIterable, Identifiable {
        case normal = "Normal"
        case calendar = "Calendar"
        var id: String { self.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("View Mode", selection: $viewMode) {
                ForEach(ViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            if viewMode == .normal {
                normalView
            } else {
                calendarView
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(ticket.identifier)
    }

    private var normalView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(ticket.identifier)
                        .font(.caption).bold()
                        .foregroundStyle(.secondary)
                    
                    TextField("Title", text: Binding(get: { ticket.title ?? "" }, set: { ticket.title = $0 }), axis: .vertical)
                        .font(.system(.title, design: .serif))
                        .bold()
                        .textFieldStyle(.plain)
                }
                
                Divider()
                
                // Status & Priority
                HStack(spacing: 12) {
                    Picker("Status", selection: $ticket.status) {
                        ForEach(TicketStatus.allCases, id: \.self) { status in
                            Text(status.rawValue.capitalized).tag(status)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 150)
                    
                    if let priority = ticket.priority {
                        Text(priority.rawValue.capitalized)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor(priority).opacity(0.1))
                            .foregroundStyle(priorityColor(priority))
                            .cornerRadius(4)
                    }
                }
                
                Divider()
                
                // Details Grid
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    if let owner = ticket.owner {
                        GridRow {
                            Text("Owner").foregroundStyle(.secondary)
                            Text(owner)
                        }
                    }
                    
                    if let project = ticket.project {
                        GridRow {
                            Text("Project").foregroundStyle(.secondary)
                            Text(project)
                        }
                    }
                    
                    if let due = ticket.dueDate {
                        GridRow {
                            Text("Due").foregroundStyle(.secondary)
                            Text(due, formatter: { let f = DateFormatter(); f.dateStyle = .long; return f }())
                        }
                    }
                }
                .font(.subheadline)
                
                Divider()
                
                // Body
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: Binding(get: { ticket.body ?? "" }, set: { ticket.body = $0 }))
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 150)
                        #if os(macOS)
                        .background(Color(nsColor: .textBackgroundColor))
                        #else
                        .background(Color(uiColor: .systemBackground))
                        #endif
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    private var calendarView: some View {
        VStack {
            if let due = ticket.dueDate {
                CalendarView(selectedDate: .constant(due))
            } else {
                Text("No due date set for this ticket.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
    
    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}
