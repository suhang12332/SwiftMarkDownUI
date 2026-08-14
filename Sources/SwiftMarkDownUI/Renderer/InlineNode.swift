import Foundation

/// A node in the Markdown abstract syntax tree representing an inline-level element.
///
/// Inline nodes appear within block-level elements (e.g., paragraphs, headings)
/// and represent text formatting, links, images, and other inline constructs.
enum InlineNode: Hashable, Sendable {

    /// Plain text content.
    ///
    /// - Parameter text: The text string.
    case text(String)

    /// Inline code span.
    ///
    /// - Parameter code: The code content without backtick delimiters.
    case code(String)

    /// Emphasized (italic) text.
    ///
    /// - Parameter children: The inline nodes inside the emphasis.
    case emphasis(children: [InlineNode])

    /// Strongly emphasized (bold) text.
    ///
    /// - Parameter children: The inline nodes inside the strong emphasis.
    case strong(children: [InlineNode])

    /// Strikethrough text.
    ///
    /// - Parameter children: The inline nodes inside the strikethrough.
    case strikethrough(children: [InlineNode])

    /// A hyperlink.
    ///
    /// - Parameters:
    ///   - destination: The URL the link points to.
    ///   - title: An optional tooltip or title for the link.
    ///   - children: The inline nodes forming the link text.
    case link(destination: String, title: String?, children: [InlineNode])

    /// An image.
    ///
    /// - Parameters:
    ///   - source: The image URL.
    ///   - alt: The alternative text describing the image.
    case image(source: String, alt: String)

    /// A hard line break (`\` or `<br>`).
    case lineBreak

    /// A soft line break (a newline in the source that renders as a space).
    case softBreak
}
