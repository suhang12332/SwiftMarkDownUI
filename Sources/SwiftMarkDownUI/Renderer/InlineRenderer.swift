import SwiftUI

/// Renders an array of ``InlineNode`` values into a styled `AttributedString`.
///
/// `InlineRenderer` performs a recursive walk over inline nodes, applying
/// typographic styles (bold, italic, strikethrough, code, links) as it builds
/// the final attributed string. It also provides analysis utilities for
/// separating image nodes from text content.
enum InlineRenderer {
    /// Renders an array of inline nodes into a single `AttributedString`.
    ///
    /// - Parameter nodes: The inline nodes to render.
    /// - Returns: A fully styled attributed string.
    static func render(_ nodes: [InlineNode]) -> AttributedString {
        var result = AttributedString()
        for node in nodes {
            render(node, into: &result)
        }
        return result
    }

    /// Recursively renders a single inline node, appending styled content to the result.
    ///
    /// Each node type applies its own typographic attributes:
    /// - `.text`: plain text, no special styling.
    /// - `.code`: monospaced caption font with accent color.
    /// - `.emphasis`: italic variant of the current font.
    /// - `.strong`: bold variant of the current font.
    /// - `.strikethrough`: adds a single strikethrough style.
    /// - `.link`: blue foreground with underline and URL binding.
    /// - `.image`: ignored (images are handled at the block level).
    /// - `.lineBreak` / `.softBreak`: inserted as newline or space respectively.
    private static func render(_ node: InlineNode, into result: inout AttributedString) {
        switch node {
        case let .text(text):
            result.append(AttributedString(text))
        case let .code(code):
            var attr = AttributedString(code)
            attr.foregroundColor = Color.accentColor
            attr.font = .caption.monospaced()
            result.append(attr)
        case let .emphasis(children):
            var seg = AttributedString()
            for c in children {
                render(c, into: &seg)
            }
            seg.font = seg.font?.italic() ?? .body.italic()
            result.append(seg)
        case let .strong(children):
            var seg = AttributedString()
            for c in children {
                render(c, into: &seg)
            }
            seg.font = seg.font?.bold() ?? .body.bold()
            result.append(seg)
        case let .strikethrough(children):
            var seg = AttributedString()
            for c in children {
                render(c, into: &seg)
            }
            seg.strikethroughStyle = .single
            result.append(seg)
        case let .link(dest, _, children):
            var seg = AttributedString()
            for c in children {
                render(c, into: &seg)
            }
            seg.foregroundColor = .blue
            seg.underlineStyle = .single
            if let url = URL(string: dest) {
                seg.link = url
            }
            result.append(seg)
        case .image: break
        case .lineBreak: result.append(AttributedString("\n"))
        case .softBreak: result.append(AttributedString(" "))
        }
    }


    /// A paragraph segment that preserves the order of text and images.
    enum Segment {
        case text([InlineNode])
        case image(source: String)
        case linkedImage(source: String, destination: String)

        /// Whether this segment renders an image.
        var isImage: Bool {
            if case .text = self { return false }
            return true
        }
    }

    /// Splits a paragraph into renderable segments without moving images to its end.
    static func segments(_ nodes: [InlineNode]) -> [Segment] {
        var result: [Segment] = []
        var textNodes: [InlineNode] = []

        func flushText() {
            guard !textNodes.isEmpty else { return }
            result.append(.text(textNodes))
            textNodes.removeAll(keepingCapacity: true)
        }

        for node in nodes {
            switch node {
            case let .image(source, _):
                flushText()
                result.append(.image(source: source))
            case let .link(destination, _, children):
                guard children.count == 1,
                      case let .image(source, _) = children[0]
                else {
                    textNodes.append(node)
                    continue
                }
                flushText()
                result.append(.linkedImage(source: source, destination: destination))
            default:
                textNodes.append(node)
            }
        }
        flushText()
        return result
    }
}
