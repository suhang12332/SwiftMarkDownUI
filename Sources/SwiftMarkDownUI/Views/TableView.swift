import SwiftUI

struct TableView: View {
    let headers: [String]
    let alignments: [TextAlignment]
    let rows: [[String]]

    private let borderColor = Color.secondary.opacity(0.3)
    private let headerBg = Color.secondary.opacity(0.08)
    private let cornerRadius: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            if !headers.isEmpty {
                headerRow
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                dataRow(row)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                cellText(header, weight: .semibold, alignment: index)
                    .background(headerBg)
                    .overlay(alignment: .trailing) {
                        if index < headers.count - 1 {
                            Divider().frame(width: 1)
                        }
                    }
            }
        }
    }

    private func dataRow(_ row: [String]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(row.enumerated()), id: \.offset) { index, cell in
                cellText(cell, weight: .regular, alignment: index)
                    .overlay(alignment: .trailing) {
                        if index < row.count - 1 {
                            Divider().frame(width: 1)
                        }
                    }
            }
        }
        .overlay(alignment: .top) { Divider() }
    }

    private func cellText(_ text: String, weight: Font.Weight, alignment index: Int) -> some View {
        Text(text)
            .font(.footnote.weight(weight))
            .foregroundStyle(.primary)
            .lineLimit(nil)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: cellAlignment(index))
    }

    private func cellAlignment(_ index: Int) -> Alignment {
        guard index < alignments.count else { return .leading }
        switch alignments[index] {
        case .left:   return .leading
        case .center: return .center
        case .right:  return .trailing
        }
    }
}
