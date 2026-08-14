import Foundation

/// A node in the Markdown abstract syntax tree representing a block-level element.
///
/// Block nodes form the top-level structure of a parsed Markdown document.
/// Each case corresponds to a distinct block type supported by the renderer.
enum BlockNode: Hashable, Sendable {

    /// A heading element.
    ///
    /// - Parameters:
    ///   - level: The heading level (1–6).
    ///   - inlines: The inline content of the heading.
    case heading(level: Int, inlines: [InlineNode])

    /// A paragraph of text.
    ///
    /// - Parameter inlines: The inline content of the paragraph.
    case paragraph(inlines: [InlineNode])

    /// A fenced or indented code block.
    ///
    /// - Parameters:
    ///   - language: The optional language identifier for syntax highlighting.
    ///   - code: The raw code content.
    case codeBlock(language: String?, code: String)

    /// A blockquote containing nested block nodes.
    ///
    /// - Parameter children: The block nodes inside the blockquote.
    case blockquote(children: [BlockNode])

    /// An ordered or unordered list.
    ///
    /// - Parameters:
    ///   - ordered: Whether the list is numerically ordered.
    ///   - items: The list items, each containing nested block content.
    case list(ordered: Bool, items: [ListItemNode])

    /// A table with headers and rows.
    ///
    /// - Parameters:
    ///   - headers: The column header strings.
    ///   - alignments: The text alignment for each column.
    ///   - rows: The table rows, each an array of cell strings.
    case table(headers: [String], alignments: [TextAlignment], rows: [[String]])

    /// A thematic break (horizontal rule).
    case thematicBreak

    /// A raw HTML block that is not rendered.
    ///
    /// - Parameter html: The raw HTML string.
    case html(String)
}

/// A single item within a list, containing its nested content and optional task state.
struct ListItemNode: Hashable, Sendable {

    /// The nested block nodes that make up this list item's content.
    let content: [BlockNode]

    /// The task completion state, if this is a task list item.
    ///
    /// - `true` if the task is completed (checked).
    /// - `false` if the task is incomplete (unchecked).
    /// - `nil` if this is not a task list item.
    let taskCompleted: Bool?
}

/// The text alignment for a table column.
enum TextAlignment: Hashable, Sendable {

    /// Left-aligned text.
    case left

    /// Center-aligned text.
    case center

    /// Right-aligned text.
    case right
}
