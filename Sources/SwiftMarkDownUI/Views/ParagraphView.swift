import SwiftUI

struct ParagraphView: View {
    let inlines: [InlineNode]

    var body: some View {
        MarkdownTextView(nodes: inlines)
            .font(.body)
            .foregroundStyle(.primary)
    }
}
