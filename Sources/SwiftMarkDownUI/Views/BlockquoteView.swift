import SwiftUI

struct BlockquoteView: View {
    let children: [BlockNode]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(.tint)
                .frame(width: 3)
            MarkdownRenderer(blocks: children)
                .padding(.leading, 10)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
