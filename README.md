# Miding

Miding is a powerful, distraction-free productivity tool for macOS and iOS that seamlessly blends note-taking, task management, ticket tracking, and journaling. Built with SwiftUI, it leverages Markdown as its core format, giving you full control over your data while providing rich visualizations and organizational tools.

## Key Features

### 📝 Smart Note-Taking
- **Markdown-First**: Write naturally in Markdown.
- **Zen Mode**: Distraction-free editing environment.
- **Note History**: Automatically tracks changes, allowing you to review and revert to previous versions.
- **Git Integration**: Built-in version control for your notes (macOS only).

### ✅ Task Management
- **Inline Tasks**: Create tasks anywhere in your notes using standard syntax (`- [ ]`).
- **Rich Metadata**: Add due dates, priorities, and categories using simple tags.
- **Task Timeline**: Visualize your schedule with a dedicated timeline view.
- **Smart Filtering**: Filter tasks by status, priority, or category.

### 🎫 Ticket System
- **Embedded Tickets**: Define tickets directly within your markdown notes using custom blocks.
- **Kanban Board**: Manage your workflow with a drag-and-drop board view.
- **Detailed Tracking**: Track status, assignees, deadlines, and more.

### 📅 Journaling & Analytics
- **Daily Journal**: dedicated interface for daily entries with mood, energy, and sleep tracking.
- **Calendar View**: Browse your history by date.
- **Visual Analytics**:
  - **Contribution Heatmap**: visualize your productivity streaks.
  - **Category Charts**: See where you spend your time.
  - **Priority Breakdown**: Analyze your workload distribution.

## Getting Started

### Prerequisites
- Xcode 15.0 or later
- macOS 14.0 or later (for macOS target)
- iOS 17.0 or later (for iOS target)

### Installation
1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/miding.git
    ```
2.  Open the project in Xcode:
    ```bash
    open miding.xcodeproj
    ```
3.  Select your target (MyMac or iPhone Simulator) and run (`Cmd + R`).

## Usage Guide

### Task Syntax
Add metadata to your tasks using `@` tags:

```markdown
- [ ] Buy groceries @due(2024-03-20) @priority(medium) @cat(Personal)
- [ ] Finish report @due(2024-03-21) @time(14:00) @priority(high) @cat(Work)
```

Supported tags:
- `@due(yyyy-MM-dd)`: Set a due date.
- `@time(HH:mm)`: Set a due time.
- `@priority(low|medium|high|critical)`: Set priority level.
- `@cat(CategoryName)`: Assign a category.

### Ticket Syntax
Create tickets using the `:::ticket` block:

```markdown
:::ticket
id: T-101
title: Fix login bug
status: open
priority: high
due: 2024-03-25
owner: Alice
project: App Revamp
:::
Here is the detailed description of the ticket.
It can span multiple lines.
```

### Project Syntax
Define projects using the `:::project` block:

```markdown
:::project
name: App Revamp
status: active
owner: Bob
deadline: 2024-04-01
:::
```

### Journal Metadata
Add frontmatter to your journal entries:

```yaml
---
date: 2024-03-20
mood: Happy
energy: 8
sleep: 7h
tags: [journal, reflection]
---
```

## Technologies
- **SwiftUI**: 100% SwiftUI for a modern, declarative UI.
- **Swift Charts**: Native, beautiful data visualization.
- **Combine**: Reactive data handling.
- **File-Based**: All data is stored in local text files, making it future-proof and portable.

## License
MIT

