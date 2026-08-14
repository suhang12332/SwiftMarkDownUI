import SwiftUI

/// A view that renders a list of inline nodes as selectable text.
///
/// `MarkdownTextView` uses ``InlineRenderer`` to convert ``InlineNode`` values
/// into a styled `AttributedString`, then displays it using SwiftUI's `Text`.
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
