
import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject var viewModel: StatisticsViewModel
    var onNavigateToNote: (UUID) -> Void

    init(notesViewModel: NotesViewModel, onNavigateToNote: @escaping (UUID) -> Void) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(notesViewModel: notesViewModel))
        self.onNavigateToNote = onNavigateToNote
    }

    private let widgetColumns = [GridItem(.adaptive(minimum: 380), spacing: 20)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Hero greeting
                heroBanner

                // Hero metrics — three big stats in one card
                heroStats

                // Tasks & Tickets summary
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 20),
                                    GridItem(.flexible(), spacing: 20)], spacing: 20) {
                    TaskThreeDayView(tasks: viewModel.notesViewModel.allTasks) { noteId in
                        onNavigateToNote(noteId)
                    }
                    TicketListView(tickets: viewModel.notesViewModel.allTickets) { noteId in
                        onNavigateToNote(noteId)
                    }
                }

                TimelineWidget(vm: viewModel.notesViewModel) { noteId in
                    onNavigateToNote(noteId)
                }

                ActivityFlowChart(
                    tasks: viewModel.taskHistory,
                    tickets: viewModel.ticketHistory,
                    journal: viewModel.journalHistory
                )

                ContributionHeatmap(activity: viewModel.activityHeatmap)

                LazyVGrid(columns: widgetColumns, spacing: 20) {
                    ActivityOverviewWidget(
                        journalCount: viewModel.activityCounts.journal,
                        taskCount: viewModel.activityCounts.task,
                        ticketCount: viewModel.activityCounts.ticket,
                        noteCount: viewModel.activityCounts.note
                    )

                    if !viewModel.priorityDistribution.isEmpty {
                        PriorityPieChart(data: viewModel.priorityDistribution)
                    }

                    if !viewModel.categoryDistribution.isEmpty {
                        CategoryBarChart(data: viewModel.categoryDistribution)
                    }

                    if !viewModel.topTags.isEmpty {
                        TagCloudView(tags: viewModel.topTags)
                    }

                    RecentActivityWidget(history: viewModel.recentActivity)
                }
            }
            .padding(28)
        }
        .background(Theme.Palette.canvas)
    }

    private var heroBanner: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting.uppercased())
                    .font(Theme.Typo.sectionHead)
                    .tracking(1.4)
                    .foregroundStyle(Theme.Palette.inkMuted)
                Text("Your workspace")
                    .font(Theme.Typo.title)
                    .foregroundStyle(Theme.Palette.ink)
            }
            Spacer()
            Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.Palette.inkSoft)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(Theme.Palette.surface)
                        .overlay(Capsule().strokeBorder(Theme.Palette.hairline, lineWidth: 1))
                )
        }
    }

    private var heroStats: some View {
        HStack(spacing: 0) {
            StatHero(
                label: "Daily Focus",
                value: String(format: "%.1f", viewModel.dailyAvgTasks),
                subtitle: "Tasks / day",
                symbol: "scope",
                accent: Theme.Palette.lilac
            )
            divider
            StatHero(
                label: "Total Tasks",
                value: "\(viewModel.totalTasks)",
                subtitle: "Completed",
                symbol: "checkmark.circle.fill",
                accent: Theme.Palette.mint
            )
            divider
            StatHero(
                label: "Ticket Success",
                value: "\(Int(viewModel.ticketCompletionRate * 100))%",
                subtitle: "Completion rate",
                symbol: "ticket.fill",
                accent: Theme.Palette.peach
            )
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
                .fill(Theme.Palette.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous)
                        .strokeBorder(Theme.Palette.hairline, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
        )
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.Palette.hairline)
            .frame(width: 1)
            .padding(.horizontal, 22)
            .padding(.vertical, 6)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Welcome back"
        }
    }
}
