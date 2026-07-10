import SwiftUI

private struct MarkdownImageView: View, Equatable {
    let source: String
    let alt: String

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.source == rhs.source && lhs.alt == rhs.alt
    }

    var body: some View {
        if let url = URL(string: source) {
            TimeoutAsyncImage(url: url)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct MarkdownRenderer: View {
    let blocks: [BlockNode]

    private let paragraphAnalysis: [Int: InlineRenderer.Analysis]

    init(blocks: [BlockNode]) {
        self.blocks = blocks
        var cache: [Int: InlineRenderer.Analysis] = [:]
        for (i, block) in blocks.enumerated() {
            if case .paragraph(let inlines) = block {
                cache[i] = InlineRenderer.analyze(inlines)
            }
        }
        self.paragraphAnalysis = cache
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                renderBlock(block, index: index)
            }
        }
    }

    @ViewBuilder
    private func renderBlock(_ block: BlockNode, index: Int) -> some View {
        switch block {
        case .heading(let level, let inlines):
            HeadingView(level: level, inlines: inlines)
        case .paragraph(let inlines):
            if let analysis = paragraphAnalysis[index] {
                renderParagraph(inlines, analysis: analysis)
            } else {
                renderParagraph(inlines, analysis: InlineRenderer.analyze(inlines))
            }
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
    private func renderParagraph(_ inlines: [InlineNode], analysis: InlineRenderer.Analysis) -> some View {
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
