import SwiftUI

struct TimeoutAsyncImage: View {
    let url: URL

    private enum LoadState {
        case active
        case done
        case failed
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
            loadState = .active
            do {
                try await Task.sleep(for: .seconds(10))
                if loadState == .active {
                    loadState = .timedOut
                }
            } catch {}
        }
        .onDisappear {
            loadState = .active
        }
    }
}
