import SwiftUI

private struct MarkdownImageView: View {
    let source: String
    let alt: String

    var body: some View {
        if let url = URL(string: source) {
            TimeoutAsyncImage(url: url)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MarkdownRenderer: View {
    let blocks: [BlockNode]

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: BlockNode) -> some View {
        switch block {
        case .heading(let level, let inlines):
            HeadingView(level: level, inlines: inlines)
        case .paragraph(let inlines):
            renderParagraph(inlines)
        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code)
        case .blockquote(let children):
            BlockquoteView(children: children)
        case .list(let ordered, let items):
            ListView(ordered: ordered, items: items)
        case .table(let headers, let alignments, let rows):
            TableView(headers: headers, alignments: alignments, rows: rows)
        case .thematicBreak:
            ThematicBreakView()
        case .html:
            EmptyView()
        }
    }

    @ViewBuilder
    private func renderParagraph(_ inlines: [InlineNode]) -> some View {
        let analysis = InlineRenderer.analyze(inlines)

        if analysis.hasImages {
            let hasText = analysis.nonImageText.contains { hasVisibleText($0) }

            VStack(alignment: .leading, spacing: 8) {
                if hasText {
                    MarkdownTextView(nodes: analysis.nonImageText)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                ForEach(Array(analysis.images.enumerated()), id: \.offset) { _, img in
                    MarkdownImageView(source: img.source, alt: img.alt)
                }
            }
        } else {
            MarkdownTextView(nodes: inlines)
                .font(.body)
                .foregroundStyle(.primary)
        }
    }

    private func hasVisibleText(_ node: InlineNode) -> Bool {
        switch node {
        case .text(let s): return !s.trimmingCharacters(in: .whitespaces).isEmpty
        case .code: return true
        case .emphasis(let c), .strong(let c), .strikethrough(let c), .link(_, _, let c):
            return c.contains { hasVisibleText($0) }
        case .image, .lineBreak, .softBreak: return false
        }
    }
}
