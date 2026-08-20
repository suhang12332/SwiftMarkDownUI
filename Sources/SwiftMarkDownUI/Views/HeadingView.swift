import SwiftUI

/// A view that renders a Markdown heading at the appropriate font size and weight.
///
/// The heading level (1–6) maps to SwiftUI's built-in text styles:
/// - Level 1: `.largeTitle` bold
/// - Level 2: `.title` bold
/// - Level 3: `.title2` bold
/// - Level 4: `.title3` bold
/// - Level 5: `.headline`
/// - Level 6 and above: `.subheadline`
struct HeadingView: View {
    let level: Int
    let inlines: [InlineNode]

    /// The font style for this heading based on its level.
    private var font: Font {
        switch level {
        case 1: return .largeTitle.bold()
        case 2: return .title.bold()
        case 3: return .title2.bold()
        case 4: return .title3.bold()
        case 5: return .headline
        default: return .subheadline
        }
    }

    /// The foreground color, with deeper headings using secondary color.
    private var foregroundColor: Color {
        level <= 4 ? .primary : .secondary
    }

    var body: some View {
        MarkdownTextView(nodes: inlines)
            .font(font)
            .foregroundStyle(foregroundColor)
            .padding(.top, level <= 2 ? 6 : 3)
    }
}
