import SwiftUI

/// An asynchronous image loader backed by SwiftUI's ``AsyncImage``.
///
/// The request and decoded image phase are owned by the view. When the view leaves
/// the hierarchy, SwiftUI can cancel the request and release the image phase.
struct TimeoutAsyncImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: nil)) { phase in
            switch phase {
            case let .success(image):
                ViewThatFits(in: .horizontal) {
                    image
                    image
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .empty:
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            case .failure:
                EmptyView()
            @unknown default:
                EmptyView()
            }
        }
    }
}
