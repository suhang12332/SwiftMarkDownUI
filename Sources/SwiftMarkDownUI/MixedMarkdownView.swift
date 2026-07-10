import Foundation
import Markdown
import SwiftUI

public struct MixedMarkdownView: View {
    let content: String

    @State private var blocks: [BlockNode] = []

    public init(_ content: String) {
        self.content = content
    }

    public var body: some View {
        MarkdownRenderer(blocks: blocks)
            .padding(.vertical, 4)
            .textSelection(.enabled)
            .onAppear {
                let md = H2MD.convert(content)
                blocks = ASTConverter.convert(Document(parsing: md))
            }
            .onDisappear {
                blocks = []
            }
    }
}
