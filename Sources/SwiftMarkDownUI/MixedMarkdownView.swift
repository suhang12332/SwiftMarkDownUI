import Foundation
import SwiftUI

public struct MixedMarkdownView: View {
    @State private var document: MarkdownDocument

    public init(_ content: String) {
        let markdown = H2MD.convert(content)
        _document = State(initialValue: MarkdownDocument(parsing: markdown))
    }

    public var body: some View {
        MarkdownRenderer(blocks: document.blocks)
            .padding(.vertical, 4)
            .textSelection(.enabled)
    }
}
