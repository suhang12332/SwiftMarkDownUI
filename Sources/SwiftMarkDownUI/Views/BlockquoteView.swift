import SwiftUI

/// A view that renders a Markdown blockquote.
///
/// Displays a tinted vertical bar on the left with the quoted content rendered
/// at a secondary foreground color and indented to the right.
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
