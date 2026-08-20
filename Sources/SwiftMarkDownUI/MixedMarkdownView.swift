import Foundation
import Markdown
import SwiftUI

/// A SwiftUI view that renders a mixture of HTML and Markdown content.
///
/// `MixedMarkdownView` accepts a string containing HTML or Markdown, converts it
/// to Markdown using the ``H2MD`` converter, then renders the result as a
/// native SwiftUI view hierarchy.
///
/// Usage:
///
///     MixedMarkdownView("<h1>Hello</h1><p>World</p>")
///
/// The view supports text selection and automatically clears its state when
/// removed from the view hierarchy.
public struct MixedMarkdownView: View {
    let content: String

    @State private var blocks: [BlockNode] = []

    /// Creates a new mixed Markdown view with the given HTML or Markdown content.
    ///
    /// - Parameter content: A string containing HTML or Markdown to render.
    public init(_ content: String) {
        self.content = content
    }

    public var body: some View {
        MarkdownRenderer(blocks: blocks)
            .padding(.vertical, 4)
            .textSelection(.enabled)
            .task(id: content) {
                // Convert supported HTML to Markdown, then parse into an AST.
                let md = HTMLToMarkdownConverter.convertIfNeeded(content)
                blocks = ASTConverter.convert(Document(parsing: md))
            }
            .onDisappear {
                // Release parsed blocks when the view disappears.
                blocks = []
            }
    }
}
