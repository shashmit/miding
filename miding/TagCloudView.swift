
import SwiftUI

struct TagItem: Hashable {
    let tag: String
    let count: Int
}

struct TagCloudView: View {
    let tags: [(tag: String, count: Int)]
    
    private var tagItems: [TagItem] {
        tags.map { TagItem(tag: $0.tag, count: $0.count) }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Top Tags")
                .font(.headline)
            
            FlowLayout(mode: .scrollable,
                       items: tagItems,
                       itemSpacing: 4) { item in
                Text("#\(item.tag)")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .cornerRadius(8)
            }
        }
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
}

// Simple Flow Layout Implementation
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let mode: Mode
    let items: Data
    let itemSpacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var totalHeight: CGFloat = .zero
    
    enum Mode {
        case scrollable, vstack
    }
    
    var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(items, id: \.self) { item in
                    content(item)
                        .padding([.horizontal, .vertical], itemSpacing)
                        .alignmentGuide(.leading, computeValue: { d in
                            if (abs(width - d.width) > geometry.size.width) {
                                width = 0
                                height -= d.height
                            }
                            let result = width
                            if item == items.last {
                                width = 0 // last item
                            } else {
                                width -= d.width
                            }
                            return result
                        })
                        .alignmentGuide(.top, computeValue: { d in
                            let result = height
                            if item == items.last {
                                height = 0 // last item
                            }
                            return result
                        })
                }
            }
        }
        .frame(height: 200) // Fixed height for now
    }
}
