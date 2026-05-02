//
//  TicketBoardView.swift
//  miding
//

import SwiftUI

struct TicketBoardView: View {
    @ObservedObject var vm: NotesViewModel
    let onNavigate: (UUID) -> Void

    private let columns: [TicketStatus] = [.open, .inProgress, .blocked, .closed]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(columns, id: \.self) { status in
                    TicketColumn(
                        status: status,
                        tickets: ticketsFor(status),
                        vm: vm,
                        onNavigate: onNavigate
                    )
                }
            }
            .padding(28)
        }
        .background(Theme.Palette.canvas)
    }

    private func ticketsFor(_ status: TicketStatus) -> [(ticket: Ticket, sourceNoteID: UUID)] {
        vm.allTickets.filter { $0.ticket.status == status }
    }
}

struct TicketColumn: View {
    let status: TicketStatus
    let tickets: [(ticket: Ticket, sourceNoteID: UUID)]
    @ObservedObject var vm: NotesViewModel
    let onNavigate: (UUID) -> Void

    @State private var isTargeted = false

    private var accent: AccentPair { status.accent }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Pill(text: columnTitle, icon: nil, accent: accent, style: .tinted, size: 12)
                if !tickets.isEmpty {
                    Text("\(tickets.count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Palette.inkMuted)
            }
            .padding(.horizontal, 4)

            // Drop target / list
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(isTargeted ? accent.tint.opacity(0.6) : Theme.Palette.surfaceMuted)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .strokeBorder(isTargeted ? accent.ink.opacity(0.4) : Theme.Palette.hairline,
                                          style: StrokeStyle(lineWidth: 1, dash: isTargeted ? [4, 4] : []))
                    )

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(tickets, id: \.ticket.id) { item in
                            TicketCard(item: item, vm: vm)
                                .onTapGesture { onNavigate(item.sourceNoteID) }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .frame(width: 300)
        .dropDestination(for: String.self) { items, _ in
            guard let itemIDString = items.first, let itemID = UUID(uuidString: itemIDString) else { return false }
            if let ticketTuple = vm.allTickets.first(where: { $0.ticket.id == itemID }) {
                vm.updateTicketStatus(ticketTuple.ticket, to: status, inNoteID: ticketTuple.sourceNoteID)
                return true
            }
            return false
        } isTargeted: { isTargeted = $0 }
    }

    private var columnTitle: String {
        switch status {
        case .open: return "To Do"
        case .inProgress: return "Doing"
        case .blocked: return "Blocked"
        case .closed: return "Done"
        }
    }
}

struct TicketCard: View {
    let item: (ticket: Ticket, sourceNoteID: UUID)
    @ObservedObject var vm: NotesViewModel

    @State private var isHovering = false

    private var accent: AccentPair { item.ticket.status.accent }

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent.ink)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 8) {
                if let title = item.ticket.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(item.ticket.body?.prefix(30) ?? "Untitled")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Palette.inkSoft)
                }

                if let body = item.ticket.body, !body.isEmpty {
                    Text(body)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Palette.inkSoft)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 6) {
                    Pill(text: item.ticket.identifier, accent: Theme.Palette.neutral, style: .outline, size: 10)
                    if let priority = item.ticket.priority {
                        Pill(text: priority.rawValue.capitalized, accent: priority.accent, style: .tinted, size: 10)
                    }
                    Spacer()
                    if let owner = item.ticket.owner {
                        Text(initials(for: owner))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Theme.Palette.neutral.ink))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.cardSmall, style: .continuous)
                .fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.cardSmall, style: .continuous)
                .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovering ? 0.06 : 0.02), radius: isHovering ? 8 : 2, x: 0, y: isHovering ? 4 : 1)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) { isHovering = hover }
        }
        .draggable(item.ticket.id.uuidString) {
            Text(item.ticket.title ?? "Ticket")
                .font(.headline)
                .foregroundStyle(Theme.Palette.ink)
                .padding()
                .background(Theme.Palette.surface)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "?" }
        let first = parts[0].prefix(1)
        if parts.count > 1 {
            let last = parts[1].prefix(1)
            return String(first + last).uppercased()
        }
        return String(first).uppercased()
    }
}
