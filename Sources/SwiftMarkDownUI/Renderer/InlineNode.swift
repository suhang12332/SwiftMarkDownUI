import Foundation

enum InlineNode: Hashable, Sendable {
    case text(String)
    case code(String)
    case emphasis(children: [InlineNode])
    case strong(children: [InlineNode])
    case strikethrough(children: [InlineNode])
    case link(destination: String, title: String?, children: [InlineNode])
    case image(source: String, alt: String)
    case lineBreak
    case softBreak
}
