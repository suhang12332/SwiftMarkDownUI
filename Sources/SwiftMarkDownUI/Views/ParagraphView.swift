import SwiftUI

/// A view that renders a Markdown paragraph.
///
/// Displays inline content using ``MarkdownTextView`` with body font and primary
/// foreground color.
struct ParagraphView: View {
    let inlines: [InlineNode]

    var body: some View {
        MarkdownTextView(nodes: inlines)
            .font(.body)
            .foregroundStyle(.primary)
    }
}
