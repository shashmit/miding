
import SwiftUI

struct TaskDetailView: View {
    @Binding var task: TaskItem
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title Area
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $task.title, axis: .vertical)
                        .font(.system(.title, design: .serif))
                        .bold()
                        .textFieldStyle(.plain)
                    
                    Toggle("Completed", isOn: $task.isCompleted)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                
                Divider()
                
                // Metadata Grid
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    if let priority = task.priority {
                        GridRow {
                            Text("Priority").foregroundStyle(.secondary)
                            Text(priority.rawValue.capitalized)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(priorityColor(priority).opacity(0.1))
                                .foregroundStyle(priorityColor(priority))
                                .cornerRadius(4)
                        }
                    }
                    
                    if !task.tags.isEmpty {
                        GridRow {
                            Text("Tags").foregroundStyle(.secondary)
                            HStack {
                                ForEach(task.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                .font(.subheadline)
            }
            .padding()
        }
        .navigationTitle(task.title)
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
