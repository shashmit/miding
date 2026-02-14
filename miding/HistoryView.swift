
import SwiftUI

struct HistoryView: View {
    let history: [GitCommit]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("History")
                .font(.headline)
                .padding()
            
            List(history) { commit in
                VStack(alignment: .leading, spacing: 4) {
                    Text(commit.message)
                        .font(.body)
                        .bold()
                    HStack {
                        Text(commit.date)
                        Text("•")
                        Text(commit.hash)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}
