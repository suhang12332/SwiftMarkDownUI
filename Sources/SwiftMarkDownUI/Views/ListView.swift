import SwiftUI

/// A view that renders a Markdown ordered or unordered list.
///
/// Supports nested lists with automatic indentation, task list checkboxes,
/// and circular/square bullets for nested unordered lists.
struct ListView: View {
    let ordered: Bool
    let items: [ListItemNode]
    let depth: Int

    init(ordered: Bool, items: [ListItemNode], depth: Int = 0) {
        self.ordered = ordered
        self.items = items
        self.depth = depth
    }

    /// Bullet characters used for unordered lists at increasing nesting depths.
    private let bullets = ["•", "◦", "■"]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ListItemRow(
                    ordered: ordered,
                    index: index,
                    item: item,
                    depth: depth,
                    bullets: bullets,
                )
            }
        }
        .padding(.leading, 4)
    }
}

/// A single row within a list, handling the bullet/number prefix and nested content.
private struct ListItemRow: View {
    let ordered: Bool
    let index: Int
    let item: ListItemNode
    let depth: Int
    let bullets: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            if let completed = item.taskCompleted {
                // Task list item: render a checkbox icon.
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(completed ? Color.accentColor : .secondary)
                    .font(.system(size: 12))
                    .offset(y: 2)
            } else if ordered {
                // Ordered list: render the item number.
                Text("\(index + 1).")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 18, alignment: .trailing)
            } else {
                // Unordered list: cycle through bullet characters by depth.
                Text(bullets[min(depth, bullets.count - 1)])
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 14, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(item.content.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case let .paragraph(inlines):
                        MarkdownTextView(nodes: inlines)
                            .font(.body)
                    case let .list(childOrdered, childItems):
                        // Recursively render nested lists with increased depth.
                        ListView(ordered: childOrdered, items: childItems, depth: depth + 1)
                    default:
                        MarkdownRenderer(blocks: [block])
                    }
                }
            }
        }
        .padding(.leading, CGFloat(depth) * 14)
    }
}
