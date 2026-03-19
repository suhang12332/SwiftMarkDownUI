import Foundation
import SwiftSoup

/// 使用 SwiftSoup 解析 HTML，转换为 Markdown 文本。
/// 用于 HTML / Mixed 模式统一走 Markdown 渲染，保证 `<b>`、`<strong>` 等样式生效。
enum HTMLToMarkdown {
    /// 将 HTML 字符串转为 Markdown。解析失败时返回原字符串。
    static func convert(_ html: String, baseURL: URL?) -> String {
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return html
        }
        let base = baseURL?.absoluteString ?? ""
        do {
            let doc = try base.isEmpty ? SwiftSoup.parse(html) : SwiftSoup.parse(html, base)
            guard let body = doc.body() else { return html }
            return nodesToMarkdown(body.getChildNodes(), baseUri: base, blockContext: true)
        } catch {
            return html
        }
    }

    private static func nodesToMarkdown(_ nodes: [Node], baseUri: String, blockContext: Bool) -> String {
        var out = ""
        var needBlockSep = false
        for node in nodes {
            if let textNode = node as? TextNode {
                out += textNode.getWholeText()
                needBlockSep = false
                continue
            }
            guard let el = node as? Element else { continue }
            let tag = el.tagName().lowercased()
            switch tag {
            case "h1": out += blockSep(&needBlockSep) + "# " + inlineContent(el, baseUri: baseUri) + "\n"
            case "h2": out += blockSep(&needBlockSep) + "## " + inlineContent(el, baseUri: baseUri) + "\n"
            case "h3": out += blockSep(&needBlockSep) + "### " + inlineContent(el, baseUri: baseUri) + "\n"
            case "h4": out += blockSep(&needBlockSep) + "#### " + inlineContent(el, baseUri: baseUri) + "\n"
            case "h5": out += blockSep(&needBlockSep) + "##### " + inlineContent(el, baseUri: baseUri) + "\n"
            case "h6": out += blockSep(&needBlockSep) + "###### " + inlineContent(el, baseUri: baseUri) + "\n"
            case "p", "div":
                let inner = nodesToMarkdown(el.getChildNodes(), baseUri: baseUri, blockContext: false)
                out += blockSep(&needBlockSep) + inner.trimmingCharacters(in: .whitespacesAndNewlines)
                if !inner.isEmpty { out += "\n" }
            case "br":
                out += "\n"
                needBlockSep = false
            case "b", "strong":
                out += "**" + inlineContent(el, baseUri: baseUri) + "**"
                needBlockSep = false
            case "i", "em":
                out += "*" + inlineContent(el, baseUri: baseUri) + "*"
                needBlockSep = false
            case "a":
                let href = (baseUri.isEmpty ? (try? el.attr("href")) : (try? el.absUrl("href"))) ?? ""
                let text = inlineContent(el, baseUri: baseUri)
                out += href.isEmpty ? text : "[\(text)](\(href))"
                needBlockSep = false
            case "img":
                let src = (baseUri.isEmpty ? (try? el.attr("src")) : (try? el.absUrl("src"))) ?? ""
                let alt = ((try? el.attr("alt")) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let label = alt.isEmpty ? "image" : alt
                let s = src.trimmingCharacters(in: .whitespacesAndNewlines)
                let lower = s.lowercased()
                if !s.isEmpty {
                    let isSVG = lower.hasPrefix("data:image/svg+xml") || lower.contains("image/svg+xml") || lower.hasSuffix(".svg")
                    out += isSVG ? "[\(label)](\(s))" : "![\(label)](\(s))"
                }
                needBlockSep = false
            case "code":
                out += "`" + inlineContent(el, baseUri: baseUri) + "`"
                needBlockSep = false
            case "ul":
                out += blockSep(&needBlockSep) + listToMarkdown(el, baseUri: baseUri, style: "-") + "\n"
            case "ol":
                out += blockSep(&needBlockSep) + listToMarkdown(el, baseUri: baseUri, style: "1.") + "\n"
            case "li":
                let inner = nodesToMarkdown(el.getChildNodes(), baseUri: baseUri, blockContext: false)
                out += blockSep(&needBlockSep) + "- " + inner.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
            case "blockquote":
                let inner = nodesToMarkdown(el.getChildNodes(), baseUri: baseUri, blockContext: true)
                let quoted = inner.split(separator: "\n", omittingEmptySubsequences: false)
                    .map { "> " + String($0) }
                    .joined(separator: "\n") + (inner.isEmpty ? "" : "\n")
                out += blockSep(&needBlockSep) + quoted
            case "pre":
                let code = (try? el.select("code").first()?.text()) ?? (try? el.text()) ?? ""
                out += blockSep(&needBlockSep) + "```\n" + code + "\n```\n"
            case "hr":
                out += blockSep(&needBlockSep) + "---\n"
            default:
                out += nodesToMarkdown(el.getChildNodes(), baseUri: baseUri, blockContext: blockContext)
                needBlockSep = false
            }
        }
        return out
    }

    private static func blockSep(_ need: inout Bool) -> String {
        defer { need = true }
        return need ? "\n\n" : ""
    }

    private static func inlineContent(_ el: Element, baseUri: String) -> String {
        nodesToMarkdown(el.getChildNodes(), baseUri: baseUri, blockContext: false)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func listToMarkdown(_ list: Element, baseUri: String, style: String) -> String {
        var out = ""
        for (idx, li) in list.children().array().enumerated() {
            let prefix = style == "1." ? "\(idx + 1). " : "- "
            let inner = nodesToMarkdown(li.getChildNodes(), baseUri: baseUri, blockContext: false)
            out += prefix + inner.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }
        return out
    }

}
