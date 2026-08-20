import AppKit
import SwiftUI

/// Renders the small set of native HTML blocks that cannot be represented by Markdown.
struct HTMLBlockView: View {
    let html: String

    var body: some View {
        if let svg = html.firstMatch(pattern: "(?is)(<svg\\b.*?</svg>)", group: 1),
           let details = html.firstMatch(pattern: "(?is)(<details\\b.*?</details>)", group: 1)
        {
            VStack(alignment: .leading, spacing: 12) {
                SVGBlockView(svg: svg)
                DetailsBlockView(html: details)
            }
        } else if html.range(of: "<details", options: [.caseInsensitive]) != nil {
            DetailsBlockView(html: html)
        } else if html.range(of: "<svg", options: [.caseInsensitive]) != nil {
            SVGBlockView(svg: html)
        }
    }
}

private struct SVGBlockView: View {
    let svg: String

    var body: some View {
        if let image = NSImage(data: Data(svg.utf8)) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(maxWidth: 600, maxHeight: 600, alignment: .leading)
        }
    }
}

private struct DetailsBlockView: View {
    let html: String
    @State private var isExpanded: Bool

    init(html: String) {
        self.html = html
        _isExpanded = State(initialValue: html.range(of: "<details[^>]*\\bopen\\b", options: [.caseInsensitive, .regularExpression]) != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                Label(summaryText, systemImage: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                MixedMarkdownView(bodyHTML)
                    .padding(.top, 6)
            }
        }
    }

    private var summaryText: String {
        guard let summary = html.firstMatch(pattern: "(?is)<summary[^>]*>(.*?)</summary>", group: 1) else {
            return "Details"
        }
        return summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var bodyHTML: String {
        guard let summaryEnd = html.range(of: "</summary>", options: [.caseInsensitive]),
              let detailsEnd = html.range(of: "</details>", options: [.caseInsensitive], range: summaryEnd.upperBound ..< html.endIndex)
        else {
            return html
        }
        return String(html[summaryEnd.upperBound ..< detailsEnd.lowerBound])
    }
}

private extension String {
    func firstMatch(pattern: String, group: Int) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(startIndex ..< endIndex, in: self)
        guard let match = expression.firstMatch(in: self, range: range),
              group < match.numberOfRanges,
              let matchRange = Range(match.range(at: group), in: self)
        else {
            return nil
        }
        return String(self[matchRange])
    }
}
