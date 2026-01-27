import Foundation
import SwiftUI

/// 仅支持混合内容（Markdown + HTML 片段）的通用展示 View。
///
/// 接收混合字符串，将 HTML 片段经 SwiftSoup 转为 Markdown 后，与 Markdown 段拼接，
/// 统一用 [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) 渲染。支持 `<b>`、`<strong>`、`<br>`、`<a>` 等常见标签。
///
/// ```swift
/// MixedMarkdownView("**粗体** 与 <b>HTML 粗体</b> 混排")
/// ```
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
