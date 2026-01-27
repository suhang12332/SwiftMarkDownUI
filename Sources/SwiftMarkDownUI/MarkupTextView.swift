import Foundation
import SwiftUI
import MarkdownUI

/// 内部使用的内容类型。
enum MarkupContent: Sendable, Equatable {
    case markdown(String)
    case html(String)
    /// 混合内容：Markdown 文本中夹杂少量 HTML 片段（例如 `<b>`, `<br>`, `<a>` 等）。
    case mixed(String)
}

/// 内部使用的通用渲染 View，外部仅通过 `MixedMarkdownView` 访问。
struct MarkupTextView: View {
    private let content: MarkupContent
    private let baseURL: URL?
    private let placeholder: String

    @State private var rendered: String = ""

    public init(
        _ content: MarkupContent,
        baseURL: URL? = nil,
        placeholder: String = ""
    ) {
        self.content = content
        self.baseURL = baseURL
        self.placeholder = placeholder
    }

    public var body: some View {
        Group {
            if rendered.isEmpty {
                Markdown(placeholder)
            } else {
                Markdown(rendered, baseURL: baseURL, imageBaseURL: nil)
            }
        }
        .task(id: content) {
            let newValue = await MarkupRenderer.render(content, baseURL: baseURL)
            rendered = newValue
        }
        .textSelection(.enabled)
        .accessibilityLabel(Text("Markup Content"))
    }
}

// MARK: - Renderer

private enum MarkupRenderer {
    static func render(_ content: MarkupContent, baseURL: URL?) async -> String {
        switch content {
        case .markdown(let md):
            return md
        case .html(let html):
            return HTMLToMarkdown.convert(html, baseURL: baseURL)
        case .mixed(let mixed):
            let parts = MixedSegmenter.segment(mixed)
            var mdAccum = ""
            for part in parts {
                switch part {
                case .markdown(let s): mdAccum += s
                case .html(let s): mdAccum += HTMLToMarkdown.convert(s, baseURL: baseURL)
                }
            }
            return mdAccum
        }
    }
}

// MARK: - Mixed segmenter (very lightweight)

private enum MixedSegmenter {
    enum Part: Sendable {
        case markdown(String)
        case html(String)
    }

    static func segment(_ s: String) -> [Part] {
        // 简单状态机：识别 `<tag ...> ... </tag>` 或自闭合 `<br/>`
        // 注意：这不是完整 HTML 解析器，只用于“混合里夹少量 HTML”的常见场景。
        var parts: [Part] = []
        parts.reserveCapacity(8)

        var buffer = ""
        buffer.reserveCapacity(min(s.count, 1024))

        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "<", let tagRange = consumeTagBlock(from: i, in: s) {
                // flush markdown buffer
                if !buffer.isEmpty {
                    parts.append(.markdown(buffer))
                    buffer.removeAll(keepingCapacity: true)
                }
                parts.append(.html(String(s[tagRange])))
                i = tagRange.upperBound
            } else {
                buffer.append(s[i])
                i = s.index(after: i)
            }
        }

        if !buffer.isEmpty {
            parts.append(.markdown(buffer))
        }
        return coalesce(parts)
    }

    private static func consumeTagBlock(from start: String.Index, in s: String) -> Range<String.Index>? {
        guard s[start] == "<" else { return nil }

        // 解析起始标签，拿到标签名、是否自闭合以及起始标签范围
        guard let (tagName, startTagRange, selfClosing) = parseStartTag(from: start, in: s) else {
            return nil
        }
        if selfClosing {
            return startTagRange
        }

        // 查找对应的结束标签，若未找到则认为不是合法片段
        let searchStart = startTagRange.upperBound
        let closingToken = "</\(tagName)>"
        guard let closingRange = s.range(of: closingToken, range: searchStart..<s.endIndex) else {
            return nil
        }

        return start..<closingRange.upperBound
    }

    private static func parseStartTag(from start: String.Index, in s: String) -> (name: String, range: Range<String.Index>, selfClosing: Bool)? {
        // 形如：<tag ...> 或 <tag .../>
        guard s[start] == "<" else { return nil }
        var i = s.index(after: start)

        // 读取标签名（字母数字组合）
        var nameStart = i
        while i < s.endIndex, s[i].isLetter || s[i].isNumber {
            i = s.index(after: i)
        }
        let nameRange = nameStart..<i
        guard !nameRange.isEmpty else { return nil }
        let name = String(s[nameRange])

        // 跳过属性直到遇到 '>'
        var sawNonSpace = false
        var selfClosing = false
        while i < s.endIndex {
            let ch = s[i]
            if ch == ">" {
                let end = s.index(after: i)
                let range = start..<end
                return (name, range, selfClosing)
            }
            if ch == "/" {
                // 检查是否为自闭合的 "/>"
                if let next = s.index(i, offsetBy: 1, limitedBy: s.index(before: s.endIndex)), next < s.endIndex, s[next] == ">" {
                    let end = s.index(after: next)
                    let range = start..<end
                    return (name, range, true)
                }
            }
            if ch == "\n" { return nil }
            if !ch.isWhitespace { sawNonSpace = true }
            i = s.index(after: i)
        }
        return nil
    }

    private static func coalesce(_ parts: [Part]) -> [Part] {
        guard !parts.isEmpty else { return [] }
        var out: [Part] = []
        out.reserveCapacity(parts.count)

        var current = parts[0]
        for p in parts.dropFirst() {
            switch (current, p) {
            case (.markdown(let a), .markdown(let b)):
                current = .markdown(a + b)
            case (.html(let a), .html(let b)):
                current = .html(a + b)
            default:
                out.append(current)
                current = p
            }
        }
        out.append(current)
        return out
    }
}


