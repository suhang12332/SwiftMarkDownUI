import Foundation
import Markdown
import SwiftUI

public struct MixedMarkdownView: View {
    let content: String

    @State private var blocks: [BlockNode] = []
    @State private var lastParsed: String = ""

    public init(_ content: String) {
        self.content = content
    }

    public var body: some View {
        MarkdownRenderer(blocks: blocks)
            .padding(.vertical, 4)
            .textSelection(.enabled)
            .onChange(of: content) { newValue in
                guard newValue != lastParsed else { return }
                lastParsed = newValue
                let md = H2MD.convert(newValue)
                blocks = ASTConverter.convert(Document(parsing: md))
            }
            .onAppear {
                guard content != lastParsed else { return }
                lastParsed = content
                let md = H2MD.convert(content)
                blocks = ASTConverter.convert(Document(parsing: md))
            }
            .onDisappear {
                blocks = []
                lastParsed = ""
            }
    }
}
