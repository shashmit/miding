
import SwiftUI

struct EditorToolbar: View {
    @Binding var text: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                // Text Style
                ToolbarGroup {
                    ToolbarButton(icon: "bold", tooltip: "Bold") {
                        wrapSelection(prefix: "**", suffix: "**", placeholder: "bold")
                    }
                    ToolbarButton(icon: "italic", tooltip: "Italic") {
                        wrapSelection(prefix: "*", suffix: "*", placeholder: "italic")
                    }
                    ToolbarButton(icon: "strikethrough", tooltip: "Strikethrough") {
                        wrapSelection(prefix: "~~", suffix: "~~", placeholder: "strikethrough")
                    }
                }
                
                ToolbarSep()
                
                // Headings
                ToolbarGroup {
                    ToolbarTextButton(label: "H₁", tooltip: "Heading 1") {
                        insertLinePrefix("# ")
                    }
                    ToolbarTextButton(label: "H₂", tooltip: "Heading 2") {
                        insertLinePrefix("## ")
                    }
                    ToolbarTextButton(label: "H₃", tooltip: "Heading 3") {
                        insertLinePrefix("### ")
                    }
                }
                
                ToolbarSep()
                
                // Lists
                ToolbarGroup {
                    ToolbarButton(icon: "list.bullet", tooltip: "Bulleted List") {
                        insertLinePrefix("- ")
                    }
                    ToolbarButton(icon: "list.number", tooltip: "Numbered List") {
                        insertLinePrefix("1. ")
                    }
                }
                
                ToolbarSep()
                
                // Code & Rule
                ToolbarGroup {
                    ToolbarButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code Block") {
                        append("\n```\n\n```\n")
                    }
                    ToolbarButton(icon: "text.quote", tooltip: "Block Quote") {
                        insertLinePrefix("> ")
                    }
                    ToolbarButton(icon: "minus", tooltip: "Divider") {
                        append("\n---\n")
                    }
                }
                
                ToolbarSep()
                
                // Links & Media
                ToolbarGroup {
                    ToolbarButton(icon: "link", tooltip: "Link") {
                        append("[text](url)")
                    }
                    ToolbarButton(icon: "photo", tooltip: "Image") {
                        append("![alt](url)")
                    }
                }
                
                ToolbarSep()
                
                // Miding-specific
                ToolbarGroup {
                    ToolbarButton(icon: "checkmark.square", tooltip: "Task") {
                        let today = {
                            let f = DateFormatter()
                            f.dateFormat = "yyyy-MM-dd"
                            return f.string(from: Date())
                        }()
                        append("\n- [ ] Task description @due(\(today)) @priority(medium)")
                    }
                    ToolbarButton(icon: "ticket", tooltip: "Ticket") {
                        append("\n:::ticket\nID: \nTitle: \nStatus: \n:::\n")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
        }
        .frame(height: 36)
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        #else
        .background(Color(uiColor: .systemBackground).opacity(0.5))
        #endif
        .overlay(alignment: .bottom) {
            Rectangle().fill(.separator.opacity(0.3)).frame(height: 0.5)
        }
    }
    
    // MARK: - Helpers
    
    private func append(_ string: String) {
        text.append(string)
    }
    
    private func wrapSelection(prefix: String, suffix: String, placeholder: String) {
        text.append("\(prefix)\(placeholder)\(suffix)")
    }
    
    private func insertLinePrefix(_ prefix: String) {
        text.append("\n\(prefix)")
    }
}

// MARK: - Components

private struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { h in
            withAnimation(.easeOut(duration: 0.1)) { isHovered = h }
        }
    }
}

private struct ToolbarTextButton: View {
    let label: String
    let tooltip: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(isHovered ? .primary : .secondary)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? Color.primary.opacity(0.06) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { h in
            withAnimation(.easeOut(duration: 0.1)) { isHovered = h }
        }
    }
}

private struct ToolbarGroup<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        HStack(spacing: 1) {
            content
        }
    }
}

private struct ToolbarSep: View {
    var body: some View {
        Rectangle()
            .fill(.separator.opacity(0.5))
            .frame(width: 1, height: 16)
            .padding(.horizontal, 6)
    }
}
