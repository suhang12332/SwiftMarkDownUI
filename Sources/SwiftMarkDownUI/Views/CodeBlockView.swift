import SwiftUI

/// A view that renders a fenced or indented code block.
///
/// Displays an optional language label above a horizontally scrollable, monospaced
/// code region with a subtle background and rounded corners.
struct CodeBlockView: View {
    let language: String?
    let code: String

    private let cornerRadius: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                    .padding(.bottom, 3)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                // Strip the trailing newline that Markdown parsers commonly include.
                Text(code.hasSuffix("\n") ? String(code.dropLast()) : code)
                    .font(.caption.monospaced())
                    .foregroundStyle(.primary)
                    .padding(10)
            }
        }
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
