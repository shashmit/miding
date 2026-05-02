
import SwiftUI

struct HistoryView: View {
    let history: [GitCommit]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionHeader("History", accent: Theme.Palette.history)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            List(history) { commit in
                HStack(alignment: .top, spacing: 12) {
                    IconBadge(symbol: "circle.fill", accent: Theme.Palette.history, size: 20, symbolSize: 7)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(commit.message)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Palette.ink)
                        HStack(spacing: 6) {
                            Text(commit.date)
                            Text("·").foregroundStyle(Theme.Palette.inkFaint)
                            Text(commit.hash).font(.system(.caption, design: .monospaced))
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.Palette.inkMuted)
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Theme.Palette.canvas)
        .frame(minWidth: 300, minHeight: 400)
    }
}
