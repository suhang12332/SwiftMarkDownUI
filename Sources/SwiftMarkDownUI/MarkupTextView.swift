import Foundation
import SwiftUI
import Markdown

enum MarkupContent: Sendable, Equatable {
    case markdown(String)
    case html(String)
    case mixed(String)
}

private struct InlineFlags {
    let hasImage: Bool
    let hasLink: Bool
    var isTextOnly: Bool { !hasImage }
    var needsRichRender: Bool { hasImage || hasLink }
}

private func computeFlags(_ node: Markup) -> InlineFlags {
    var img = false
    var lnk = false
    if node is Markdown.Image { return InlineFlags(hasImage: true, hasLink: true) }
    if node is Markdown.Link { lnk = true }
    if let container = node as? InlineContainer {
        for child in container.children {
            let f = computeFlags(child)
            if f.hasImage { img = true }
            if f.hasLink { lnk = true }
            if img && lnk { break }
        }
    }
    return InlineFlags(hasImage: img, hasLink: lnk)
}

struct MarkupTextView: View {
    private let content: MarkupContent
    private let baseURL: URL?
    private let placeholder: String

    @State private var rendered: String = ""
    @State private var document: Document?

    init(_ content: MarkupContent, baseURL: URL? = nil, placeholder: String = "") {
        self.content = content
        self.baseURL = baseURL
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if rendered.isEmpty {
                SwiftUI.Text(placeholder)
            } else if let doc = document {
                MarkdownDocumentView(document: doc)
            }
        }
        .task(id: content) {
            let result = await MarkupRenderer.render(content, baseURL: baseURL)
            rendered = result
            document = Document(parsing: result)
        }
        .onDisappear {
            rendered = ""
            document = nil
        }
        .textSelection(.enabled)
    }
}

private enum MarkupRenderer {
    static func render(_ content: MarkupContent, baseURL: URL?) async -> String {
        let raw: String
        switch content {
        case .markdown(let md): raw = md
        case .html(let html): raw = H2MD.convert(html)
        case .mixed(let mixed): raw = H2MD.convert(mixed)
        }
        return sanitizeUnsupportedImages(in: raw)
    }

    private static func sanitizeUnsupportedImages(in markdown: String) -> String {
        guard !markdown.isEmpty else { return markdown }
        guard markdown.contains("!") else { return markdown }

        var result = markdown
        var searchStart = result.startIndex

        while searchStart < result.endIndex {
            guard let bangRange = result.range(of: "![", range: searchStart..<result.endIndex) else { break }
            guard let bracketRange = result.range(of: "](", range: bangRange.upperBound..<result.endIndex) else { break }
            guard let parenRange = result.range(of: ")", range: bracketRange.upperBound..<result.endIndex) else { break }

            let altStr = String(result[bangRange.upperBound..<bracketRange.lowerBound])
            let urlStr = String(result[bracketRange.upperBound..<parenRange.lowerBound])
            let urlLower = urlStr.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            let isSVG = urlLower.hasSuffix(".svg")
                || urlLower.hasPrefix("data:image/svg+xml")
                || urlLower.contains("image/svg+xml")

            if isSVG {
                let linkText = altStr.isEmpty ? "image" : altStr
                let replacement = "[\(linkText)](\(urlStr))"
                result.replaceSubrange(bangRange.lowerBound...parenRange.upperBound, with: replacement)
                searchStart = result.index(bangRange.lowerBound, offsetBy: replacement.count)
            } else {
                searchStart = parenRange.upperBound
            }
        }
        return result
    }
}

private struct MarkdownDocumentView: View {
    let document: Document

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, child in
                BlockNodeView(node: child)
            }
        }
    }
}

private struct BlockNodeView: View {
    let node: Markup
    var body: some View {
        if let h = node as? Heading {
            HeadingView(heading: h)
        } else if let p = node as? Paragraph {
            ParagraphView(paragraph: p)
        } else if let cb = node as? CodeBlock {
            CodeBlockView(codeBlock: cb)
        } else if let bq = node as? BlockQuote {
            BlockQuoteView(blockQuote: bq)
        } else if let ul = node as? UnorderedList {
            ListView(items: Array(ul.children), ordered: false)
        } else if let ol = node as? OrderedList {
            ListView(items: Array(ol.children), ordered: true)
        } else if let table = node as? Markdown.Table {
            TableView(table: table)
        } else if node is ThematicBreak {
            Divider().padding(.vertical, 8)
        } else if let hb = node as? HTMLBlock {
            SwiftUI.Text(hb.format()).font(.body).padding(.vertical, 4)
        } else {
            SwiftUI.Text(node.format()).font(.body).padding(.vertical, 2)
        }
    }
}

private struct HeadingView: View {
    let heading: Heading
    var body: some View {
        InlineRichView(container: heading)
            .font(headingFont)
            .bold()
            .padding(.top, heading.level <= 2 ? 16 : 8)
    }
    private var headingFont: Font {
        switch heading.level {
        case 1: return .largeTitle
        case 2: return .title
        case 3: return .title2
        case 4: return .title3
        case 5: return .headline
        default: return .subheadline
        }
    }
}

private struct ParagraphView: View {
    let paragraph: Paragraph
    var body: some View {
        InlineRichView(container: paragraph)
            .font(.body)
    }
}

private struct CodeBlockView: View {
    let codeBlock: CodeBlock
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lang = codeBlock.language {
                SwiftUI.Text(lang).font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 12).padding(.top, 8)
            }
            SwiftUI.Text(codeBlock.code)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled).padding(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.vertical, 6)
    }
}

private struct BlockQuoteView: View {
    let blockQuote: BlockQuote
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                BlockNodeView(node: child)
            }
        }
        .padding(.leading, 16)
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.accentColor).frame(width: 3)
        }
        .padding(.vertical, 4)
    }
}

private struct TableView: View {
    let table: Markdown.Table
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                TableHeaderView(row: table.head)
                Divider()
                ForEach(Array(table.body.children.enumerated()), id: \.offset) { _, row in
                    if let tr = row as? Markdown.Table.Row {
                        TableRowDataView(row: tr)
                    }
                }
            }
            .border(Color.gray.opacity(0.3))
        }
        .padding(.vertical, 6)
    }
}

private struct TableHeaderView: View {
    let row: any _TableRowProtocol
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                InlineRichView(container: cell)
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
            }
        }
        .background(Color.gray.opacity(0.15))
        Divider()
    }
}

private struct TableRowDataView: View {
    let row: Markdown.Table.Row
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(row.cells.enumerated()), id: \.offset) { _, cell in
                InlineRichView(container: cell)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
            }
        }
        Divider()
    }
}

private struct ListView: View {
    let items: [Markup]
    let ordered: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if let li = item as? ListItem {
                    HStack(alignment: .top, spacing: 6) {
                        SwiftUI.Text(ordered ? "\(index + 1)." : "\u{2022}")
                            .font(.body).monospacedDigit()
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(li.children.enumerated()), id: \.offset) { _, child in
                                BlockNodeView(node: child)
                            }
                        }
                    }
                }
            }
        }
        .padding(.leading, 8).padding(.vertical, 2)
    }
}

private func buildAttributedString(from container: InlineContainer) -> AttributedString {
    var result = AttributedString()
    for child in container.children {
        result += buildAttrString(from: child)
    }
    return result
}

private func buildAttrString(from node: Markup) -> AttributedString {
    if let t = node as? Markdown.Text {
        return AttributedString(t.string)
    } else if let b = node as? Strong {
        var inner = buildAttrStringFromContainer(b)
        inner.font = .bold(.body)()
        return inner
    } else if let i = node as? Emphasis {
        var inner = buildAttrStringFromContainer(i)
        inner.font = .italic(.body)()
        return inner
    } else if let s = node as? Strikethrough {
        var inner = buildAttrStringFromContainer(s)
        inner.strikethroughStyle = .single
        return inner
    } else if let code = node as? InlineCode {
        var attr = AttributedString(code.code)
        attr.font = .monospaced(.body)()
        attr.backgroundColor = Color.gray.opacity(0.15)
        return attr
    } else if let link = node as? Markdown.Link {
        var inner = buildAttrStringFromContainer(link)
        inner.foregroundColor = .blue
        inner.underlineStyle = .single
        if let dest = link.destination, let url = URL(string: dest) {
            inner.link = url
        }
        return inner
    } else if let container = node as? InlineContainer {
        return buildAttrStringFromContainer(container)
    } else {
        return AttributedString(node.format())
    }
}

private func buildAttrStringFromContainer(_ container: InlineContainer) -> AttributedString {
    var result = AttributedString()
    for child in container.children {
        result += buildAttrString(from: child)
    }
    return result
}

private func buildText(from node: Markup) -> SwiftUI.Text {
    if let t = node as? Markdown.Text {
        return SwiftUI.Text(t.string)
    } else if let b = node as? Strong {
        return buildTextFromContainer(b).bold()
    } else if let i = node as? Emphasis {
        return buildTextFromContainer(i).italic()
    } else if let s = node as? Strikethrough {
        return buildTextFromContainer(s).strikethrough()
    } else if let code = node as? InlineCode {
        return SwiftUI.Text(code.code).font(.system(.body, design: .monospaced))
    } else if let link = node as? Markdown.Link {
        return buildTextFromContainer(link).foregroundColor(.blue).underline()
    } else if let container = node as? InlineContainer {
        return buildTextFromContainer(container)
    } else {
        return SwiftUI.Text(node.format())
    }
}

private func buildTextFromContainer(_ container: InlineContainer) -> SwiftUI.Text {
    var result = SwiftUI.Text("")
    for child in container.children {
        result = result + buildText(from: child)
    }
    return result
}

private struct InlineRichView: View {
    let container: any InlineContainer

    var body: some View {
        let flags = computeFlags(container)
        if !flags.needsRichRender {
            buildTextFromContainer(container)
        } else if flags.hasImage {
            InlineRichMixedView(container: container)
        } else {
            SwiftUI.Text(buildAttributedString(from: container))
        }
    }
}

private struct InlineRichMixedView: View {
    let container: any InlineContainer

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(container.children.enumerated()), id: \.offset) { _, node in
                InlineNodeOrView(node: node)
            }
        }
    }
}

private struct InlineNodeOrView: View {
    let node: Markup
    var body: some View {
        let flags = computeFlags(node)
        if !flags.needsRichRender {
            buildText(from: node)
        } else if let img = node as? Markdown.Image, let src = img.source {
            NetworkImageView(src: src, alt: img.plainText)
        } else if let link = node as? Markdown.Link {
            if let dest = link.destination, let url = URL(string: dest) {
                Link(destination: url) {
                    InlineRichView(container: link).foregroundColor(.blue)
                }
            } else {
                InlineRichView(container: link).foregroundColor(.blue)
            }
        } else if let container = node as? InlineContainer {
            InlineRichView(container: container)
        } else {
            SwiftUI.Text(node.format())
        }
    }
}

private struct NetworkImageView: View {
    let src: String
    let alt: String

    var body: some View {
        let imageURL = URL(string: src)
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
            case .failure:
                SwiftUI.Text("[\(alt)](\(src))").foregroundColor(.red)
            default:
                ProgressView().controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .onDisappear {
            if let url = imageURL {
                DispatchQueue.global(qos: .utility).async {
                    let request = URLRequest(url: url)
                    URLCache.shared.removeCachedResponse(for: request)
                }
            }
        }
    }
}
