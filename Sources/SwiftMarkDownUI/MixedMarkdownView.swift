import Foundation
import SwiftUI
import MarkdownUI

public struct MixedMarkdownView: View {
    @State private var markdown: String

    public init(_ content: String) {
        _markdown = State(initialValue: H2MD.convert(content))
    }

    public var body: some View {
        Markdown(markdown)
            .textSelection(.enabled)
            .onDisappear {
                markdown = ""
            }
    }
}
