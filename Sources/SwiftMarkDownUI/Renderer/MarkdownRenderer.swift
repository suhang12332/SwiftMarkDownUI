import SwiftUI

/// The main view responsible for rendering a parsed Markdown document.
///
/// `MarkdownRenderer` takes an array of ``BlockNode`` values (produced by ``ASTConverter``)
/// and renders each one as the appropriate SwiftUI view. It pre-analyzes paragraphs
/// to detect images, enabling them to be rendered as separate rows below text content.
private struct MarkdownImageView: View, Equatable {
    let source: String
    let alt: String
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

    /// Pre-computed paragraph analysis results, keyed by block index.
    ///
    /// This cache avoids redundant analysis passes when paragraphs are rendered,
    /// since each paragraph's image/text separation is computed once during init.
    private let paragraphAnalysis: [Int: InlineRenderer.Analysis]

    init(blocks: [BlockNode]) {
        self.blocks = blocks
        // Pre-analyze all paragraphs to preserve text and image order.
        var cache: [Int: InlineRenderer.Analysis] = [:]
        for (i, block) in blocks.enumerated() {
            if case let .paragraph(inlines) = block {
                cache[i] = InlineRenderer.analyze(inlines)
            }
        }
        paragraphAnalysis = cache
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                renderBlock(block, index: index)
            }
        }
    }

    /// Renders a single block node as the corresponding SwiftUI view.
    @ViewBuilder
    private func renderBlock(_ block: BlockNode, index: Int) -> some View {
        switch block {
        case let .heading(level, inlines):
            HeadingView(level: level, inlines: inlines)
        case let .paragraph(inlines):
            if let analysis = paragraphAnalysis[index] {
                renderParagraph(inlines, analysis: analysis)
            } else {
                renderParagraph(inlines, analysis: InlineRenderer.analyze(inlines))
            }
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
        case .html:
            EmptyView()
        }
    }

    /// Renders a paragraph while preserving the source order of text and images.
    @ViewBuilder
    private func renderParagraph(_ inlines: [InlineNode], analysis: InlineRenderer.Analysis) -> some View {
        if analysis.hasImages {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(InlineRenderer.segments(inlines).enumerated()), id: \.offset) { _, segment in
                    switch segment {
                    case let .text(nodes):
                        if nodes.contains(where: hasVisibleText) {
                            MarkdownTextView(nodes: nodes)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                    case let .image(source, alt):
                        MarkdownImageView(source: source, alt: alt, destination: nil)
                    case let .linkedImage(source, alt, destination):
                        MarkdownImageView(source: source, alt: alt, destination: destination)
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
