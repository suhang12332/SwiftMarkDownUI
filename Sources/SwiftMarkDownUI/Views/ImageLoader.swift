import SwiftUI

struct TimeoutAsyncImage: View {
    let url: URL
    @State private var loaded = false
    @State private var failed = false
    @State private var timedOut = false

    var body: some View {
        Group {
            if failed || timedOut {
                EmptyView()
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .onAppear { loaded = true }
                    case .failure:
                        EmptyView()
                            .onAppear { failed = true }
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
            loaded = false
            failed = false
            timedOut = false
            do {
                try await Task.sleep(for: .seconds(10))
                if !loaded && !failed {
                    timedOut = true
                }
            } catch {}
        }
        .onDisappear {
            loaded = false
            failed = false
            timedOut = false
        }
    }
}
