import SwiftUI

struct InlineImageView: View {
    let source: String
    let alt: String

    var body: some View {
        if let url = URL(string: source) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                case .failure:
                    EmptyView()
                case .empty:
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 20, height: 20)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onDisappear {
                URLCache.shared.removeCachedResponse(for: URLRequest(url: url))
            }
        }
    }
}
