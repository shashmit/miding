
import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject var viewModel: StatisticsViewModel
    var onNavigateToNote: (UUID) -> Void
    
    // Grid Columns for Widgets
    let metricColumns = [
        GridItem(.adaptive(minimum: 240), spacing: 16)
    ]
    
    let widgetColumns = [
        GridItem(.adaptive(minimum: 360), spacing: 16)
    ]
    
    init(notesViewModel: NotesViewModel, onNavigateToNote: @escaping (UUID) -> Void) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(notesViewModel: notesViewModel))
        self.onNavigateToNote = onNavigateToNote
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                // (Title moved to navigation bar)
                
                // 1. Key Metrics Row
                LazyVGrid(columns: metricColumns, spacing: 16) {
                    StatCard(title: "Daily Focus", value: String(format: "%.1f", viewModel.dailyAvgTasks), subtitle: "Tasks / Day", icon: "checkmark.circle.fill", color: .blue)
                    StatCard(title: "Total Tasks", value: "\(viewModel.totalTasks)", subtitle: "Completed", icon: "tray.full.fill", color: .green)
                    StatCard(title: "Ticket Success", value: "\(Int(viewModel.ticketCompletionRate * 100))%", subtitle: "Completion Rate", icon: "ticket.fill", color: .purple)
                }
                
                // 1.1 Tasks & Tickets Grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    TaskThreeDayView(tasks: viewModel.notesViewModel.allTasks) { noteId in
                        onNavigateToNote(noteId)
                    }
                    
                    TicketListView(tickets: viewModel.notesViewModel.allTickets) { noteId in
                        onNavigateToNote(noteId)
                    }
                }
                
                // 1. Timeline (New)
                TimelineWidget(vm: viewModel.notesViewModel) { noteId in
                    onNavigateToNote(noteId)
                }
                .padding(.top, 12)
                
                // 1.5 Activity Flow (New)
                ActivityFlowChart(
                    tasks: viewModel.taskHistory,
                    tickets: viewModel.ticketHistory,
                    journal: viewModel.journalHistory
                )
                
                // 2. Heatmap (Full Width)
                ContributionHeatmap(activity: viewModel.activityHeatmap)
                
                // 3. Widgets Grid
                LazyVGrid(columns: widgetColumns, spacing: 16) {
                    // Activity Overview
                    ActivityOverviewWidget(
                        journalCount: viewModel.activityCounts.journal,
                        taskCount: viewModel.activityCounts.task,
                        ticketCount: viewModel.activityCounts.ticket,
                        noteCount: viewModel.activityCounts.note
                    )
                    
                    // Priority Distribution
                    if !viewModel.priorityDistribution.isEmpty {
                        PriorityPieChart(data: viewModel.priorityDistribution)
                    }
                    
                    // Category Distribution
                    if !viewModel.categoryDistribution.isEmpty {
                        CategoryBarChart(data: viewModel.categoryDistribution)
                    }
                    
                    // Tag Cloud
                    if !viewModel.topTags.isEmpty {
                        TagCloudView(tags: viewModel.topTags)
                    }
                    
                    // Recent Activity
                    RecentActivityWidget(history: viewModel.recentActivity)
                }
            }
            .padding(24)
        }
    }
}


