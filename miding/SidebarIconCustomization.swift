import SwiftUI

// MARK: - Model

enum SidebarIconColor: String, Codable, CaseIterable, Identifiable {
    case blue, green, orange, red, purple, pink, teal, indigo, yellow, gray

    var id: String { rawValue }
    var title: String {
        switch self {
        case .blue: return "Sky"
        case .green: return "Mint"
        case .orange: return "Peach"
        case .red: return "Blush"
        case .purple: return "Lilac"
        case .pink: return "Blush"
        case .teal: return "Sage"
        case .indigo: return "Lilac"
        case .yellow: return "Butter"
        case .gray: return "Neutral"
        }
    }

    /// Maps each legacy raw color to a pastel AccentPair from the theme.
    var pastel: AccentPair {
        switch self {
        case .blue:   return Theme.Palette.sky
        case .green:  return Theme.Palette.mint
        case .orange: return Theme.Palette.peach
        case .red:    return Theme.Palette.blush
        case .purple: return Theme.Palette.lilac
        case .pink:   return Theme.Palette.blush
        case .teal:   return Theme.Palette.sage
        case .indigo: return Theme.Palette.lilac
        case .yellow: return Theme.Palette.butter
        case .gray:   return Theme.Palette.neutral
        }
    }

    /// Foreground/ink color for SF Symbols rendered in the sidebar.
    var swiftUIColor: Color { pastel.ink }
}

struct SidebarIconStyle: Codable, Hashable {
    var symbol: String
    var color: SidebarIconColor

    static let defaults: [String: SidebarIconStyle] = [
        "dashboard": .init(symbol: "square.grid.2x2", color: .indigo),
        "workstream": .init(symbol: "chart.bar.xaxis", color: .teal),
        "allNotes": .init(symbol: "note.text", color: .blue),
        "journal": .init(symbol: "book.closed", color: .orange),
        "tasks": .init(symbol: "checklist", color: .green),
        "tickets": .init(symbol: "ticket", color: .pink),
        "history": .init(symbol: "clock.arrow.circlepath", color: .purple),
        "topic": .init(symbol: "number", color: .gray),
    ]
}

struct TopicEditState: Identifiable {
    let topic: String
    var id: String { topic }
}

struct TopicEditResult {
    let topic: String
    let symbol: String
    let color: SidebarIconColor
}

// MARK: - View modifier

extension View {
    /// Hides the window toolbar on macOS; no-op elsewhere.
    func hideWindowToolbar() -> some View {
        #if os(macOS)
        return self.toolbar(.hidden, for: .windowToolbar)
        #else
        return self
        #endif
    }
}

// MARK: - Sheets

private struct SidebarIconEditorItem: Identifiable {
    let id: String
    let title: String
}

struct SidebarIconEditorSheet: View {
    @Binding var styles: [String: SidebarIconStyle]
    let defaults: [String: SidebarIconStyle]
    @Environment(\.dismiss) private var dismiss

    private let items: [SidebarIconEditorItem] = [
        .init(id: "dashboard", title: "Dashboard"),
        .init(id: "workstream", title: "Workstream"),
        .init(id: "allNotes", title: "All Notes"),
        .init(id: "journal", title: "Journal"),
        .init(id: "tasks", title: "Tasks"),
        .init(id: "tickets", title: "Tickets"),
        .init(id: "history", title: "All History"),
        .init(id: "topic", title: "Topics"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Sidebar Icons") {
                    ForEach(items) { item in
                        let style = styleFor(item.id)
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: style.symbol)
                                .font(.system(size: 15))
                                .foregroundStyle(style.color.swiftUIColor)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.title)
                                    .font(.system(size: 13, weight: .semibold))

                                TextField("SF Symbol name", text: symbolBinding(for: item.id))
                                    .textFieldStyle(.roundedBorder)

                                HStack(spacing: 10) {
                                    Picker("Color", selection: colorBinding(for: item.id)) {
                                        ForEach(SidebarIconColor.allCases) { color in
                                            Text(color.title).tag(color)
                                        }
                                    }
                                    .pickerStyle(.menu)

                                    Button("Reset") {
                                        styles[item.id] = defaults[item.id]
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Text("Tip: Use SF Symbol names like `book.closed`, `chart.bar.xaxis`, or `checklist`.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Customize Sidebar Icons")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset All") { styles = defaults }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
    }

    private func styleFor(_ key: String) -> SidebarIconStyle {
        styles[key] ?? defaults[key] ?? SidebarIconStyle(symbol: "circle", color: .blue)
    }

    private func symbolBinding(for key: String) -> Binding<String> {
        Binding(
            get: { styleFor(key).symbol },
            set: { newValue in
                let symbol = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                var style = styleFor(key)
                style.symbol = symbol.isEmpty ? (defaults[key]?.symbol ?? "circle") : symbol
                styles[key] = style
            }
        )
    }

    private func colorBinding(for key: String) -> Binding<SidebarIconColor> {
        Binding(
            get: { styleFor(key).color },
            set: { newValue in
                var style = styleFor(key)
                style.color = newValue
                styles[key] = style
            }
        )
    }
}

struct TopicEditorSheet: View {
    let initialTopic: String
    let initialStyle: SidebarIconStyle
    let defaultTopicStyle: SidebarIconStyle
    let onSave: (TopicEditResult) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var topicName: String
    @State private var symbolName: String
    @State private var color: SidebarIconColor

    init(
        initialTopic: String,
        initialStyle: SidebarIconStyle,
        defaultTopicStyle: SidebarIconStyle,
        onSave: @escaping (TopicEditResult) -> Void
    ) {
        self.initialTopic = initialTopic
        self.initialStyle = initialStyle
        self.defaultTopicStyle = defaultTopicStyle
        self.onSave = onSave
        _topicName = State(initialValue: initialTopic)
        _symbolName = State(initialValue: initialStyle.symbol)
        _color = State(initialValue: initialStyle.color)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Topic") {
                    TextField("Topic name", text: $topicName)
                    TextField("SF Symbol", text: $symbolName)
                    Picker("Color", selection: $color) {
                        ForEach(SidebarIconColor.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Preview") {
                    HStack(spacing: 10) {
                        Image(systemName: effectiveSymbol)
                            .foregroundStyle(color.swiftUIColor)
                        Text("#\(effectiveTopic)")
                    }
                    .font(.system(size: 14, weight: .medium))
                }
            }
            .navigationTitle("Edit Topic")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        onSave(
                            TopicEditResult(
                                topic: effectiveTopic,
                                symbol: effectiveSymbol,
                                color: color
                            )
                        )
                        dismiss()
                    }
                    .disabled(effectiveTopic.isEmpty)
                }
                ToolbarItem(placement: .automatic) {
                    Button("Reset Icon") {
                        symbolName = defaultTopicStyle.symbol
                        color = defaultTopicStyle.color
                    }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 260)
    }

    private var effectiveTopic: String {
        topicName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var effectiveSymbol: String {
        let clean = symbolName.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? defaultTopicStyle.symbol : clean
    }
}
