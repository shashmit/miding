
import SwiftUI

struct EditorToolbar: View {
    @Binding var text: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
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

                ToolbarGroup {
                    ToolbarTextButton(label: "H₁", tooltip: "Heading 1") { insertLinePrefix("# ") }
                    ToolbarTextButton(label: "H₂", tooltip: "Heading 2") { insertLinePrefix("## ") }
                    ToolbarTextButton(label: "H₃", tooltip: "Heading 3") { insertLinePrefix("### ") }
                }

                ToolbarSep()

                ToolbarGroup {
                    ToolbarButton(icon: "list.bullet", tooltip: "Bulleted List") { insertLinePrefix("- ") }
                    ToolbarButton(icon: "list.number", tooltip: "Numbered List") { insertLinePrefix("1. ") }
                }

                ToolbarSep()

                ToolbarGroup {
                    ToolbarButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code Block") {
                        append("\n```\n\n```\n")
                    }
                    ToolbarButton(icon: "text.quote", tooltip: "Block Quote") { insertLinePrefix("> ") }
                    ToolbarButton(icon: "minus", tooltip: "Divider") { append("\n---\n") }
                }

                ToolbarSep()

                ToolbarGroup {
                    ToolbarButton(icon: "link", tooltip: "Link") { append("[text](url)") }
                    ToolbarButton(icon: "photo", tooltip: "Image") { append("![alt](url)") }
                }

                ToolbarSep()

                ToolbarGroup {
                    ToolbarButton(icon: "checkmark.square", tooltip: "Task", accent: Theme.Palette.mint) {
                        let today = {
                            let f = DateFormatter()
                            f.dateFormat = "yyyy-MM-dd"
                            return f.string(from: Date())
                        }()
                        append("\n- [ ] Task description @due(\(today)) @priority(medium)")
                    }
                    ToolbarButton(icon: "ticket", tooltip: "Ticket", accent: Theme.Palette.blush) {
                        append("\n:::ticket\nID: \nTitle: \nStatus: \n:::\n")
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .frame(height: 40)
        .background(Theme.Palette.surfaceMuted)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Palette.hairline).frame(height: 1)
        }
    }

    private func append(_ string: String) { text.append(string) }
    private func wrapSelection(prefix: String, suffix: String, placeholder: String) {
        text.append("\(prefix)\(placeholder)\(suffix)")
    }
    private func insertLinePrefix(_ prefix: String) { text.append("\n\(prefix)") }
}

private struct ToolbarButton: View {
    let icon: String
    let tooltip: String
    var accent: AccentPair = Theme.Palette.lilac
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isHovered ? accent.ink : Theme.Palette.inkSoft)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? accent.tint : Color.clear)
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
                .foregroundStyle(isHovered ? Theme.Palette.lilac.ink : Theme.Palette.inkSoft)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? Theme.Palette.lilac.tint : Color.clear)
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
        HStack(spacing: 2) { content }
    }
}

private struct ToolbarSep: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Palette.hairline)
            .frame(width: 1, height: 18)
            .padding(.horizontal, 8)
    }
}
