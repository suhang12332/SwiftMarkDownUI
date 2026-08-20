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

    // MARK: - Analysis

    /// The result of analyzing a list of inline nodes for image content.
    struct Analysis {
        /// Whether the node list contains at least one image.
        var hasImages = false

        /// All image nodes found in the list, in document order.
        var images: [(source: String, alt: String)] = []

        /// Non-image inline nodes, with image children stripped from containers.
        var nonImageText: [InlineNode] = []
    }

    /// A paragraph segment that preserves the order of text and images.
    enum Segment {
        case text([InlineNode])
        case image(source: String, alt: String)
        case linkedImage(source: String, alt: String, destination: String)
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
            case let .image(source, alt):
                flushText()
                result.append(.image(source: source, alt: alt))
            case let .link(destination, _, children):
                guard children.count == 1,
                      case let .image(source, alt) = children[0]
                else {
                    textNodes.append(node)
                    continue
                }
                flushText()
                result.append(.linkedImage(source: source, alt: alt, destination: destination))
            default:
                textNodes.append(node)
            }
        }
        flushText()
        return result
    }

    /// Analyzes a list of inline nodes to separate image content from text content.
    ///
    /// This is used by ``MarkdownRenderer`` to render images as separate view rows
    /// within a paragraph, rather than inline with text.
    ///
    /// - Parameter nodes: The inline nodes to analyze.
    /// - Returns: An ``Analysis`` result containing separated images and text.
    static func analyze(_ nodes: [InlineNode]) -> Analysis {
        var a = Analysis()
        for node in nodes {
            analyzeNode(node, into: &a)
        }
        return a
    }

    /// Recursively analyzes a single node, appending results to the analysis.
    ///
    /// Image nodes are collected separately. Container nodes (emphasis, strong,
    /// strikethrough, link) have their image children filtered out before being
    /// added to `nonImageText`.
    private static func analyzeNode(_ node: InlineNode, into a: inout Analysis) {
        switch node {
        case let .image(source, alt):
            a.hasImages = true
            a.images.append((source, alt))
        case let .emphasis(c), let .strong(c), let .strikethrough(c):
            a.hasImages = a.hasImages || c.contains { isImageNode($0) }
            for child in c {
                analyzeNode(child, into: &a)
            }
            a.nonImageText.append(node)
        case let .link(d, t, c):
            a.hasImages = a.hasImages || c.contains { isImageNode($0) }
            // Strip image children from the link's non-image text representation.
            let filtered = c.filter { !isImageNode($0) }
            a.nonImageText.append(.link(destination: d, title: t, children: filtered))
            for child in c {
                analyzeNode(child, into: &a)
            }
        case .text, .code, .lineBreak, .softBreak:
            a.nonImageText.append(node)
        }
    }

    /// Returns whether the given node is an image node.
    private static func isImageNode(_ node: InlineNode) -> Bool {
        if case .image = node {
            return true
        }
        return false
    }
}
