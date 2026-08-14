import SwiftUI

/// An asynchronous image loader with a built-in timeout.
///
/// `TimeoutAsyncImage` wraps SwiftUI's `AsyncImage` and adds a 10-second timeout.
/// If the image fails to load or times out, the view renders nothing (`EmptyView`).
/// While loading, a small `ProgressView` placeholder is shown.
struct TimeoutAsyncImage: View {
    let url: URL

    /// The current loading state of the image.
    private enum LoadState {
        /// The image is being loaded.
        case active
        /// The image loaded successfully.
        case done
        /// The image failed to load.
        case failed
        /// The image load timed out after 10 seconds.
        case timedOut
    }

    @State private var loadState: LoadState = .active

    var body: some View {
        Group {
            if loadState == .failed || loadState == .timedOut {
                EmptyView()
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .onAppear { loadState = .done }
                    case .failure:
                        EmptyView()
                            .onAppear { loadState = .failed }
                    case .empty:
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity, minHeight: 40)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .task(id: url) {
            // Start a timeout timer. If the image hasn't loaded within 10 seconds,
            // mark it as timed out to prevent indefinite loading states.
            loadState = .active
            do {
                try await Task.sleep(for: .seconds(10))
                if loadState == .active {
                    loadState = .timedOut
                }
            } catch {}
        }
        .onDisappear {
            // Reset state so the image can reload if the view reappears.
            loadState = .active
        }
    }
}
