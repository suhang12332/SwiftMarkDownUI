import SwiftUI

/// The main view responsible for rendering a parsed Markdown document.
///
/// `MarkdownRenderer` takes an array of ``BlockNode`` values (produced by ``ASTConverter``)
/// and renders each one as the appropriate SwiftUI view. Paragraphs are split into
/// segments so images can be rendered as separate rows while preserving text order.
private struct MarkdownImageView: View {
    let source: String
    let destination: String?

    var body: some View {
        if let url = URL(string: source) {
            let image = TimeoutAsyncImage(url: url)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let destination,
               let destinationURL = URL(string: destination)
            {
                Link(destination: destinationURL) {
                    image
                }
            } else {
                image
            }
        }
    }
}

struct MarkdownRenderer: View {
    let blocks: [BlockNode]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(blocks.indices, id: \.self) { index in
                renderBlock(blocks[index])
            }
        }
    }

    /// Renders a single block node as the corresponding SwiftUI view.
    @ViewBuilder
    private func renderBlock(_ block: BlockNode) -> some View {
        switch block {
        case let .heading(level, inlines):
            HeadingView(level: level, inlines: inlines)
        case let .paragraph(inlines):
            renderParagraph(inlines)
        case let .codeBlock(language, code):
            CodeBlockView(language: language, code: code)
        case let .blockquote(children):
            BlockquoteView(children: children)
        case let .list(ordered, items):
            ListView(ordered: ordered, items: items)
        case let .table(headers, alignments, rows):
            TableView(headers: headers, alignments: alignments, rows: rows)
        case .thematicBreak:
            ThematicBreakView()
        case let .html(html):
            HTMLBlockView(html: html)
        }
    }

    /// Renders a paragraph while preserving the source order of text and images.
    @ViewBuilder
    private func renderParagraph(_ inlines: [InlineNode]) -> some View {
        let segments = InlineRenderer.segments(inlines)
        if segments.contains(where: \.isImage) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(segments.indices, id: \.self) { index in
                    switch segments[index] {
                    case let .text(nodes):
                        if nodes.contains(where: hasVisibleText) {
                            MarkdownTextView(nodes: nodes)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    case let .image(source):
                        MarkdownImageView(source: source, destination: nil)
                    case let .linkedImage(source, destination):
                        MarkdownImageView(source: source, destination: destination)
                    }
                }
            }
        } else {
            MarkdownTextView(nodes: inlines)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    /// Determines whether an inline node contains visible text content.
    private func hasVisibleText(_ node: InlineNode) -> Bool {
        switch node {
        case let .text(s): !s.trimmingCharacters(in: .whitespaces).isEmpty
        case .code: true
        case let .emphasis(c), let .strong(c), let .strikethrough(c), let .link(_, _, c):
            c.contains { hasVisibleText($0) }
        case .image, .lineBreak, .softBreak: false
        }
    }
}
