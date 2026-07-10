import SwiftUI

struct HeadingView: View, Equatable {
    let level: Int
    let inlines: [InlineNode]

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.level == rhs.level && lhs.inlines == rhs.inlines
    }

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
