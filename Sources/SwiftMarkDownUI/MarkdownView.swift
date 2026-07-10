import Markdown
import SwiftUI

public struct MarkdownView: View {
    let markdown: String

    @State private var blocks: [BlockNode] = []
    @State private var debounceTask: Task<Void, Never>?

    public init(_ markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        MarkdownRenderer(blocks: blocks)
            .padding(.vertical, 4)
            .textSelection(.enabled)
            .onChange(of: markdown) { newValue in
                debounceParse(newValue)
            }
            .onAppear {
                parse(markdown)
            }
            .onDisappear {
                debounceTask?.cancel()
                blocks = []
            }
    }

    private func debounceParse(_ text: String) {
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            parse(text)
        }
    }

    private func parse(_ text: String) {
        let doc = Document(parsing: text)
        blocks = ASTConverter.convert(doc)
    }
}
