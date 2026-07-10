import Markdown

struct MarkdownDocument: Hashable, Sendable {
    let blocks: [BlockNode]

    init(parsing markdown: String) {
        let document = Document(parsing: markdown)
        self.blocks = ASTConverter.convert(document)
    }
}
