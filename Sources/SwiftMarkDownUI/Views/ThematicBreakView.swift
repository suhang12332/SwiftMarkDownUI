import SwiftUI

/// A view that renders a Markdown thematic break (horizontal rule).
///
/// Displays a thin, quaternary-colored horizontal line with vertical padding.
struct ThematicBreakView: View {
    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}
