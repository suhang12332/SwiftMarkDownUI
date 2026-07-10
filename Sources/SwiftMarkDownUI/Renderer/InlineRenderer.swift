import SwiftUI

struct InlineRenderer {

    // MARK: - Render to AttributedString

    static func render(_ nodes: [InlineNode]) -> AttributedString {
        var result = AttributedString()
        for node in nodes {
            render(node, into: &result)
        }
        return result
    }

    private static func render(_ node: InlineNode, into result: inout AttributedString) {
        switch node {
        case .text(let text):
            result.append(AttributedString(text))
        case .code(let code):
            var attr = AttributedString(code)
            attr.foregroundColor = Color.accentColor
            attr.font = .caption.monospaced()
            result.append(attr)
        case .emphasis(let children):
            var seg = AttributedString()
            for c in children { render(c, into: &seg) }
            seg.font = seg.font?.italic() ?? .body.italic()
            result.append(seg)
        case .strong(let children):
            var seg = AttributedString()
            for c in children { render(c, into: &seg) }
            seg.font = seg.font?.bold() ?? .body.bold()
            result.append(seg)
        case .strikethrough(let children):
            var seg = AttributedString()
            for c in children { render(c, into: &seg) }
            seg.strikethroughStyle = .single
            result.append(seg)
        case .link(let dest, _, let children):
            var seg = AttributedString()
            for c in children { render(c, into: &seg) }
            seg.foregroundColor = .blue
            seg.underlineStyle = .single
            if let url = URL(string: dest) { seg.link = url }
            result.append(seg)
        case .image: break
        case .lineBreak: result.append(AttributedString("\n"))
        case .softBreak: result.append(AttributedString(" "))
        }
    }

    // MARK: - Single-pass analysis (replaces 3 separate traversals)

    struct Analysis {
        var hasImages = false
        var images: [(source: String, alt: String)] = []
        var nonImageText: [InlineNode] = []
    }

    static func analyze(_ nodes: [InlineNode]) -> Analysis {
        var a = Analysis()
        for node in nodes {
            analyzeNode(node, into: &a)
        }
        return a
    }

    private static func analyzeNode(_ node: InlineNode, into a: inout Analysis) {
        switch node {
        case .image(let source, let alt):
            a.hasImages = true
            a.images.append((source, alt))
        case .emphasis(let c), .strong(let c), .strikethrough(let c):
            a.hasImages = a.hasImages || c.contains { isImageNode($0) }
            for child in c { analyzeNode(child, into: &a) }
            a.nonImageText.append(node)
        case .link(let d, let t, let c):
            a.hasImages = a.hasImages || c.contains { isImageNode($0) }
            let filtered = c.filter { !isImageNode($0) }
            a.nonImageText.append(.link(destination: d, title: t, children: filtered))
            for child in c { analyzeNode(child, into: &a) }
        case .text, .code, .lineBreak, .softBreak:
            a.nonImageText.append(node)
        }
    }

    private static func isImageNode(_ node: InlineNode) -> Bool {
        if case .image = node { return true }
        return false
    }
}
