import Markdown
import SwiftUI

public struct MarkdownView: View {
    let markdown: String

    @State private var blocks: [BlockNode] = []
    @State private var lastParsed: String = ""

    public init(_ markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        MarkdownRenderer(blocks: blocks)
            .padding(.vertical, 4)
            .textSelection(.enabled)
            .onChange(of: markdown) { newValue in
                guard newValue != lastParsed else { return }
                lastParsed = newValue
                blocks = ASTConverter.convert(Document(parsing: newValue))
            }
            .onAppear {
                guard markdown != lastParsed else { return }
                lastParsed = markdown
                blocks = ASTConverter.convert(Document(parsing: markdown))
            }
            .onDisappear {
                blocks = []
                lastParsed = ""
            }
    }
}
