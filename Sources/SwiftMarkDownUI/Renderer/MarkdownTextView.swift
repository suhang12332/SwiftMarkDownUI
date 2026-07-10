import SwiftUI

struct MarkdownTextView: View, Equatable {
    let nodes: [InlineNode]

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.nodes == rhs.nodes
    }

    var body: some View {
        Text(InlineRenderer.render(nodes))
            .textSelection(.enabled)
    }
}
