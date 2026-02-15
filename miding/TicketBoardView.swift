//
//  TicketBoardView.swift
//  miding
//
//  Created by Shashmit on 15/02/26.
//

import SwiftUI

struct TicketBoardView: View {
    @ObservedObject var vm: NotesViewModel
    let onNavigate: (UUID) -> Void
    
    // Minimalist columns
    private let columns: [TicketStatus] = [.open, .inProgress, .blocked, .closed]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 16) {
                ForEach(columns, id: \.self) { status in
                    TicketColumn(
                        status: status,
                        tickets: ticketsFor(status),
                        vm: vm,
                        onNavigate: onNavigate
                    )
                }
            }
            .padding(24)
        }
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(uiColor: .systemGroupedBackground))
        #endif
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
    
    var body: some View {
        VStack(spacing: 12) {
            // -- Header (Pill Style) --
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(columnTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                )
                
                Spacer()
                
                // Add header actions if needed, for now just a count if > 0
                if !tickets.isEmpty {
                    Text("\(tickets.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Context menu placeholder
                Image(systemName: "ellipsis")
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.bottom, 4)
            
            // -- List Area --
            // We use a ZStack background for the drop target visual to be very subtle
            ZStack {
                // Drop Indicator (Full column height visual when dragging over)
                RoundedRectangle(cornerRadius: 12)
                    .fill(isTargeted ? statusColor.opacity(0.05) : Color.clear)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tickets, id: \.ticket.id) { item in
                            TicketCard(item: item, vm: vm)
                                .onTapGesture {
                                    onNavigate(item.sourceNoteID)
                                }
                        }
                    }
                    .padding(4) // Small padding for card selection ring
                }
            }
        }
        .frame(width: 300)
        .dropDestination(for: String.self) { items, location in
            guard let itemIDString = items.first, let itemID = UUID(uuidString: itemIDString) else { return false }
            if let ticketTuple = vm.allTickets.first(where: { $0.ticket.id == itemID }) {
                vm.updateTicketStatus(ticketTuple.ticket, to: status, inNoteID: ticketTuple.sourceNoteID)
                return true
            }
            return false
        } isTargeted: { targeted in
            isTargeted = targeted
        }
    }
    
    private var columnTitle: String {
        switch status {
        case .open: return "To Do"
        case .inProgress: return "Doing"
        case .blocked: return "Blocked"
        case .closed: return "Done"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .open: return .blue
        case .inProgress: return .orange
        case .blocked: return .red
        case .closed: return .gray
        }
    }
}

struct TicketCard: View {
    let item: (ticket: Ticket, sourceNoteID: UUID)
    @ObservedObject var vm: NotesViewModel
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Title
            if let title = item.ticket.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(item.ticket.body?.prefix(30) ?? "Untitled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            // Description / Body Preview
            if let body = item.ticket.body, !body.isEmpty {
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer().frame(height: 4)
            
            // Footer: ID + Priority (Impact) + Owner
            HStack {
                // ID
                Text(item.ticket.identifier)
                   .font(.system(size: 11, weight: .medium, design: .monospaced))
                   .foregroundStyle(.secondary)
                
                Spacer()
                
                // Priority (Simulating "Impact Score")
                if let priority = item.ticket.priority {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(priorityColor(priority))
                            .frame(width: 6, height: 6)
                        Text(priority.rawValue.capitalized)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Owner Avatar
                if let owner = item.ticket.owner {
                    Text(initials(for: owner))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color.gray))
                }
            }
        }
        .padding(16)
        #if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
        #else
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        #endif
        .cornerRadius(12)
        // Clean border instead of heavy shadow
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // Very subtle shadow on hover only
        .shadow(color: Color.black.opacity(isHovering ? 0.05 : 0), radius: 8, x: 0, y: 4)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
        .draggable(item.ticket.id.uuidString) {
             Text(item.ticket.title ?? "Ticket")
                 .font(.headline)
                 .foregroundStyle(.primary)
                 .padding()
                 #if os(macOS)
                 .background(Color(nsColor: .controlBackgroundColor))
                 #else
                 .background(Color(uiColor: .secondarySystemGroupedBackground))
                 #endif
                 .cornerRadius(10)
                 .shadow(radius: 5)
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

