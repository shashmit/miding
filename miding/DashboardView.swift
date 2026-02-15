
import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject var viewModel: StatisticsViewModel
    var onNavigateToNote: (UUID) -> Void
    
    // Grid Columns for Widgets
    let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 500), spacing: 16)
    ]
    
    init(notesViewModel: NotesViewModel, onNavigateToNote: @escaping (UUID) -> Void) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(notesViewModel: notesViewModel))
        self.onNavigateToNote = onNavigateToNote
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Dashboard")
                    .font(.system(size: 32, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 1. Key Metrics Row
                HStack(spacing: 16) {
                    StatCard(title: "Daily Focus", value: String(format: "%.1f", viewModel.dailyAvgTasks), subtitle: "Tasks / Day", icon: "checkmark.circle.fill", color: .blue)
                    StatCard(title: "Total Tasks", value: "\(viewModel.totalTasks)", subtitle: "Completed", icon: "tray.full.fill", color: .green)
                    StatCard(title: "Ticket Success", value: "\(Int(viewModel.ticketCompletionRate * 100))%", subtitle: "Completion Rate", icon: "ticket.fill", color: .purple)
                }
                
                // 1.1 Tasks 3-Day View (New)
                TaskThreeDayView(tasks: viewModel.notesViewModel.allTasks) { noteId in
                    onNavigateToNote(noteId)
                }
                
                // 1.2 Ticket List (New)
                TicketListView(tickets: viewModel.notesViewModel.allTickets) { noteId in
                    onNavigateToNote(noteId)
                }
                
                // 1. Timeline (New)
                TimelineWidget(vm: viewModel.notesViewModel) { noteId in
                    onNavigateToNote(noteId)
                }
                
                // 1.5 Activity Flow (New)
                ActivityFlowChart(
                    tasks: viewModel.taskHistory,
                    tickets: viewModel.ticketHistory,
                    journal: viewModel.journalHistory
                )
                
                // 2. Heatmap (Full Width)
                ContributionHeatmap(activity: viewModel.activityHeatmap)
                
                // 3. Widgets Grid
                LazyVGrid(columns: columns, spacing: 16) {
                    // Ticket Flow
                    if !viewModel.ticketFlow.isEmpty {
                         VStack(alignment: .leading) {
                            Text("Ticket Flow")
                                .font(.headline)
                            
                            Chart {
                                ForEach(viewModel.ticketFlow, id: \.date) { data in
                                    LineMark(x: .value("Date", data.date, unit: .day), y: .value("New", data.new))
                                        .foregroundStyle(Color.green)
                                        .interpolationMethod(.catmullRom)
                                    
                                    LineMark(x: .value("Date", data.date, unit: .day), y: .value("Closed", data.closed))
                                        .foregroundStyle(Color.purple)
                                        .interpolationMethod(.catmullRom)
                                }
                            }
                            .frame(height: 200)
                            
                            HStack {
                                Label("New", systemImage: "circle.fill").foregroundStyle(.green)
                                Label("Closed", systemImage: "circle.fill").foregroundStyle(.purple)
                            }
                            .font(.caption)
                        }
                        .padding()
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
        .background(DynamicGradientView(viewModel: viewModel))
    }
}


