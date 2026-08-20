import SwiftUI

/// A view that renders a list of inline nodes as selectable text.
///
/// `MarkdownTextView` uses ``InlineRenderer`` to convert ``InlineNode`` values
/// into a styled `AttributedString`, then displays it using SwiftUI's `Text`.
struct MarkdownTextView: View {
    let nodes: [InlineNode]

    var body: some View {
        Text(InlineRenderer.render(nodes))
            .textSelection(.enabled)
    }
}
