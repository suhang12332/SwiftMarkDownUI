import SwiftUI

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
