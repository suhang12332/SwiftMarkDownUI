import Markdown

/// A lightweight wrapper that parses a Markdown string into an array of ``BlockNode`` values.
///
/// `MarkdownDocument` combines parsing (via Apple's `swift-markdown`) and AST conversion
/// (via ``ASTConverter``) into a single initializer, providing a convenient entry point
/// for rendering Markdown content.
struct MarkdownDocument: Hashable, Sendable {

    /// The top-level block nodes parsed from the Markdown source.
    let blocks: [BlockNode]

    /// Parses a Markdown string and converts it to block nodes.
    ///
    /// - Parameter markdown: The Markdown source string to parse.
    init(parsing markdown: String) {
        let document = Document(parsing: markdown)
        self.blocks = ASTConverter.convert(document)
    }
}
