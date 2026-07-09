import Foundation
import SwiftUI

public struct MixedMarkdownView: View {
    private let content: MarkupContent
    private let baseURL: URL?
    private let placeholder: String

    public init(
        _ mixed: String,
        baseURL: URL? = nil,
        placeholder: String = ""
    ) {
        self.content = .mixed(mixed)
        self.baseURL = baseURL
        self.placeholder = placeholder
    }

    public var body: some View {
        MarkupTextView(content, baseURL: baseURL, placeholder: placeholder)
    }
}
