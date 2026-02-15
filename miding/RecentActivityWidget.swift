
import SwiftUI

struct RecentActivityWidget: View {
    let history: [NoteHistoryEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
            
            if history.isEmpty {
                Text("No recent activity")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: iconFor(entry.summary))
                            .foregroundStyle(colorFor(entry.summary))
                            .font(.system(size: 12))
                            .frame(width: 20, height: 20)
                            .background(colorFor(entry.summary).opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.summary)
                                .font(.system(size: 12, weight: .medium))
                            Text(entry.timestamp, format: .relative(presentation: .named))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
    
    func iconFor(_ summary: String) -> String {
        if summary.contains("Created") { return "plus" }
        if summary.contains("Saved") { return "checkmark" }
        return "pencil"
    }
    
    func colorFor(_ summary: String) -> Color {
        if summary.contains("Created") { return .green }
        if summary.contains("Saved") { return .blue }
        return .orange
    }
}
