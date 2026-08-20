import AppKit
import SwiftUI

/// An asynchronous image loader with a built-in timeout.
///
/// `TimeoutAsyncImage` wraps SwiftUI's `AsyncImage` and adds a 10-second timeout.
/// If the image fails to load or times out, the view renders nothing (`EmptyView`).
/// While loading, a small `ProgressView` placeholder is shown.
struct TimeoutAsyncImage: View {
    let url: URL
    let maxSize: CGSize

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

    private struct ImageLoadTimeout: Error {}

    @State private var loadState: LoadState = .active
    @State private var image: NSImage?

    init(url: URL, maxSize: CGSize = CGSize(width: 600, height: 600)) {
        self.url = url
        self.maxSize = maxSize
    }

    var body: some View {
        Group {
            if loadState == .failed || loadState == .timedOut {
                EmptyView()
            } else {
                if let image {
                    let size = fittedSize(for: image.size)
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: size.width, height: size.height)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
            }
        }
        .task(id: url) {
            // Start a timeout timer. If the image hasn't loaded within 10 seconds,
            // mark it as timed out to prevent indefinite loading states.
            loadState = .active
            image = nil
            do {
                let data = try await withThrowingTaskGroup(of: Data.self) { group in
                    group.addTask {
                        try await URLSession.shared.data(from: url).0
                    }
                    group.addTask {
                        try await Task.sleep(for: .seconds(10))
                        throw ImageLoadTimeout()
                    }
                    defer { group.cancelAll() }
                    return try await group.next() ?? Data()
                }
                guard let loadedImage = NSImage(data: data) else {
                    loadState = .failed
                    return
                }
                image = loadedImage
                loadState = .done
            } catch is ImageLoadTimeout {
                loadState = .timedOut
            } catch {}
        }
        .onDisappear {
            // Reset state so the image can reload if the view reappears.
            loadState = .active
        }
    }

    private func fittedSize(for originalSize: CGSize) -> CGSize {
        guard originalSize.width > 0, originalSize.height > 0 else {
            return .zero
        }
        let scale = min(
            1,
            maxSize.width / originalSize.width,
            maxSize.height / originalSize.height,
        )
        return CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
    }
}
