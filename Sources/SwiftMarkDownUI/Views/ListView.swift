import SwiftUI

struct ListView: View {
    let ordered: Bool
    let items: [ListItemNode]

    private let bullets = ["•", "◦", "■"]

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                ListItemRow(
                    ordered: ordered,
                    index: index,
                    item: item,
                    depth: 0,
                    bullets: bullets
                )
            }
        }
        .padding(.leading, 4)
    }
}

private struct ListItemRow: View {
    let ordered: Bool
    let index: Int
    let item: ListItemNode
    let depth: Int
    let bullets: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            if let completed = item.taskCompleted {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(completed ? Color.accentColor : .secondary)
                    .font(.system(size: 12))
                    .offset(y: 2)
            } else if ordered {
                Text("\(index + 1).")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 18, alignment: .trailing)
            } else {
                Text(bullets[min(depth, bullets.count - 1)])
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 14, alignment: .center)
            }

            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(item.content.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .paragraph(let inlines):
                        MarkdownTextView(nodes: inlines)
                    .font(.body)
                    case .list(let childOrdered, let childItems):
                        ListView(ordered: childOrdered, items: childItems)
                    default:
                        MarkdownRenderer(blocks: [block])
                    }
                }
            }
        }
        .padding(.leading, CGFloat(depth) * 14)
    }
}
