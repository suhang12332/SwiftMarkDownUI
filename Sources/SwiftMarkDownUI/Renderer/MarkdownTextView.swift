import SwiftUI

struct MarkdownTextView: View {
    let nodes: [InlineNode]

    var body: some View {
        Text(InlineRenderer.render(nodes))
            .textSelection(.enabled)
    }
}
