# Strict Markdown Grammar Specification

This document defines a strict, machine-parseable Markdown grammar that is:

- Human-readable
- Deterministic (no ambiguity in parsing)
- Extensible
- Backward-compatible with standard Markdown

## 1. Design Principles

1. Markdown remains valid if opened anywhere.
2. Structured blocks must be uniquely identifiable.
3. Inline metadata must use reserved prefixes.
4. Everything must be parsable via:
   - Regex (MVP)
   - AST (Phase 2)

## 2. Global Syntax Rules

### Reserved Prefixes

| Symbol | Meaning            |
| :----- | :----------------- |
| `@`    | System attribute   |
| `#`    | Tag                |
| `!`    | Priority           |
| `^`    | ID reference       |
| `~`    | Recurrence         |
| `📅`   | Calendar shorthand |
| `🎫`   | Ticket shorthand   |

These are reserved and cannot be used casually without escaping.

## 3. Task Grammar Specification

### Basic Task

```markdown
- [ ] Task title
- [x] Completed task
```

### Extended Task (Inline Metadata)

```markdown
- [ ] Prepare investor pitch @due(2026-02-18) @time(14:00) !high #work ^T-102
```

### Grammar Definition

```
TASK :=
- [STATE] SPACE TITLE (SPACE ATTRIBUTE)*

STATE := " " | "x"
TITLE := free text until first attribute
ATTRIBUTE :=
    @due(YYYY-MM-DD)
  | @time(HH:MM)
  | @date(YYYY-MM-DD)
  | @estimate(2h|30m)
  | @project(NAME)
  | !low|!medium|!high|!critical
  | #tag
  | ^ID
  | ~daily|~weekly|~monthly
```

### Parsing Rules

- Attributes may appear in any order.
- Duplicate attributes → last one wins.
- Invalid date → ignore attribute but keep task.
- @due always overrides @date.

## 4. Ticket Grammar Specification

Tickets must be block-level.

### Ticket Block (Primary Format)

```markdown
🎫 TICKET: Fix Payment Failure

Status: Open Priority: High Due: 2026-02-20 Owner: Shashmit

---

Detailed explanation of issue. Steps to reproduce.
```

### Strict Machine Format (Preferred for Parsing)

```markdown
:::ticket id: T-101 title: Fix Payment Failure status: open priority: high due:
2026-02-20 owner: Shashmit project: SaaS-Core :::

User unable to complete Stripe checkout.
```

### Grammar Definition

```
TICKET_BLOCK :=
:::ticket
(KEY: VALUE)+
:::
BODY
```

**Allowed Keys:**

| Key        | Type                                             |
| :--------- | :----------------------------------------------- |
| `id`       | string                                           |
| `title`    | string                                           |
| `status`   | `open` \| `in-progress` \| `blocked` \| `closed` |
| `priority` | `low` \| `medium` \| `high` \| `critical`        |
| `due`      | `YYYY-MM-DD`                                     |
| `owner`    | string                                           |
| `project`  | string                                           |
| `created`  | `YYYY-MM-DD`                                     |
| `closed`   | `YYYY-MM-DD`                                     |

Unknown keys → stored as metadata.

## 5. Calendar Entry Grammar

Two valid formats.

### Inline Calendar Entry

```markdown
📅 2026-02-20 14:00 Client meeting
```

**Grammar**

```
📅 YYYY-MM-DD HH:MM TITLE
```

HH:MM optional.

### Attribute-Based Calendar

```markdown
Meeting with Rahul @date(2026-02-20) @time(14:00)
```

**Parsing Priority**

1. `📅` shorthand
2. `@date` + `@time`
3. `@due` if no other date found

## 6. Journal Metadata Header

Every daily journal file can include:

```markdown
---
date: 2026-02-14
mood: focused
energy: 8
sleep: 7h
---
```

This is standard YAML frontmatter.

**Recognized Keys:**

| Key      | Type         |
| :------- | :----------- |
| `date`   | `YYYY-MM-DD` |
| `mood`   | string       |
| `energy` | 1-10         |
| `sleep`  | duration     |
| `tags`   | array        |

## 7. Project Definition Grammar

Projects are defined as blocks.

```markdown
:::project name: SaaS-Core status: active owner: Shashmit deadline: 2026-04-01
:::
```

This lets you link tasks:

```markdown
@project(SaaS-Core)
```

## 8. Linking System

### Reference a Ticket

`^T-101`

### Reference a Project

`@project(SaaS-Core)`

### Backlink Strategy

Store references in SQLite index:

```sql
reference_table:
from_file
from_line
reference_type
reference_value
```

## 9. Recurrence Rules

```markdown
- [ ] Gym session ~daily
- [ ] Weekly review ~weekly
- [ ] Salary processing ~monthly
```

Optional advanced format:

```
~weekly(Mon)
~monthly(15)
~yearly(02-14)
```

## 10. Formal Grammar (EBNF Style)

```ebnf
document = (frontmatter | block | paragraph)* ;

frontmatter = "---" newline (key ":" value newline)+ "---" ;

block = task | ticket_block | project_block | calendar_line ;

task = "- [" state "] " title attributes ;

attributes = (space attribute)* ;

attribute =
    "@due(" date ")"
  | "@time(" time ")"
  | "@date(" date ")"
  | "@project(" text ")"
  | "!" priority
  | "#" tag
  | "^" id
  | "~" recurrence ;

ticket_block =
  ":::ticket" newline
  (key ":" value newline)+
  ":::" newline
  text ;

calendar_line =
  "📅" space date (space time)? space text ;
```

## 11. Parsing Precedence Rules

Order of parsing:

1. YAML frontmatter
2. Ticket blocks
3. Project blocks
4. Tasks
5. Calendar shorthand
6. Inline attributes
7. Tags and IDs

This prevents conflicts.

## 12. Error Handling Philosophy

- Never delete user content.
- Invalid attributes → ignore but store raw text.
- Broken block syntax → treat as normal Markdown.
- Log parsing errors silently.

## 13. Data Index Model

When parsed, store:

- `tasks_table`
- `tickets_table`
- `calendar_table`
- `projects_table`
- `references_table`
- `tags_table`

Markdown remains canonical. SQLite = query layer.
