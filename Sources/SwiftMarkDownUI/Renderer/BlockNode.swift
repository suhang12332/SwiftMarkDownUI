import Foundation

enum BlockNode: Hashable, Sendable {
    case heading(level: Int, inlines: [InlineNode])
    case paragraph(inlines: [InlineNode])
    case codeBlock(language: String?, code: String)
    case blockquote(children: [BlockNode])
    case list(ordered: Bool, items: [ListItemNode])
    case table(headers: [String], alignments: [TextAlignment], rows: [[String]])
    case thematicBreak
    case html(String)
}

struct ListItemNode: Hashable, Sendable {
    let content: [BlockNode]
    let taskCompleted: Bool?
}

enum TextAlignment: Hashable, Sendable {
    case left, center, right
}
