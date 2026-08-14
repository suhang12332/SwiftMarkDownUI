import SwiftUI

/// A view that renders a Markdown inline image.
///
/// Loads the image asynchronously using ``TimeoutAsyncImage`` and displays it
/// scaled to fit within the available width, aligned to the leading edge.
struct InlineImageView: View {
    let source: String
    let alt: String

    var body: some View {
        if let url = URL(string: source) {
            TimeoutAsyncImage(url: url)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
