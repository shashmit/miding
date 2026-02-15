
import SwiftUI

struct TagCloudView: View {
    let tags: [(tag: String, count: Int)]
    
    var topTags: [(tag: String, count: Int)] {
        Array(tags.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top Tags")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(topTags, id: \.tag) { item in
                        HStack(spacing: 4) {
                            Text("#\(item.tag)")
                                .font(.system(size: 12, weight: .medium))
                            Text("\(item.count)")
                                .font(.system(size: 10, weight: .bold))
                                .opacity(0.6)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.08))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        #if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
        #else
        .background(Color(uiColor: .secondarySystemBackground))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
