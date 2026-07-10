import Markdown

struct ASTConverter {

    private struct BlockVisitor: MarkupVisitor {
        typealias Result = BlockNode?

        mutating func defaultVisit(_ markup: any Markup) -> BlockNode? { nil }

        mutating func visitHeading(_ heading: Heading) -> BlockNode? {
            .heading(level: heading.level, inlines: collectInlineChildren(heading))
        }

        mutating func visitParagraph(_ paragraph: Paragraph) -> BlockNode? {
            .paragraph(inlines: collectInlineChildren(paragraph))
        }

        mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> BlockNode? {
            .codeBlock(language: codeBlock.language, code: codeBlock.code)
        }

        mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> BlockNode? {
            var v = BlockVisitor()
            return .blockquote(children: blockQuote.children.compactMap { v.visit($0) })
        }

        mutating func visitOrderedList(_ orderedList: OrderedList) -> BlockNode? {
            convertListItems(orderedList.listItems, ordered: true)
        }

        mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> BlockNode? {
            convertListItems(unorderedList.listItems, ordered: false)
        }

        mutating func visitTable(_ table: Table) -> BlockNode? {
            let alignments = table.columnAlignments.map { alignment -> TextAlignment in
                switch alignment {
                case .left:   return .left
                case .center: return .center
                case .right:  return .right
                case .none:   return .left
                }
            }
            return .table(
                headers: table.head.cells.map(\.plainText),
                alignments: alignments,
                rows: table.body.rows.map { row in row.cells.map(\.plainText) }
            )
        }

        mutating func visitThematicBreak(_: ThematicBreak) -> BlockNode? { .thematicBreak }

        mutating func visitHTMLBlock(_ html: HTMLBlock) -> BlockNode? { .html(html.rawHTML) }

        mutating func visitDocument(_: Document) -> BlockNode? { nil }

        private mutating func collectInlineChildren(_ container: any InlineContainer) -> [InlineNode] {
            var v = InlineVisitor()
            return Array(container.inlineChildren.flatMap { v.visit($0) })
        }

        private mutating func convertListItems(_ listItems: LazyMapSequence<MarkupChildren, ListItem>, ordered: Bool) -> BlockNode? {
            var items = [ListItemNode]()
            for item in listItems {
                var v = BlockVisitor()
                items.append(ListItemNode(
                    content: item.children.compactMap { v.visit($0) },
                    taskCompleted: item.checkbox == .checked ? true : (item.checkbox == .unchecked ? false : nil)
                ))
            }
            return .list(ordered: ordered, items: items)
        }
    }

    private struct InlineVisitor: MarkupVisitor {
        typealias Result = [InlineNode]

        mutating func defaultVisit(_: any Markup) -> [InlineNode] { [] }

        mutating func visitText(_ text: Text) -> [InlineNode] { [.text(text.string)] }

        mutating func visitInlineCode(_ inlineCode: InlineCode) -> [InlineNode] { [.code(inlineCode.code)] }

        mutating func visitEmphasis(_ emphasis: Emphasis) -> [InlineNode] {
            [.emphasis(children: collectInlineChildren(emphasis))]
        }

        mutating func visitStrong(_ strong: Strong) -> [InlineNode] {
            [.strong(children: collectInlineChildren(strong))]
        }

        mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> [InlineNode] {
            [.strikethrough(children: collectInlineChildren(strikethrough))]
        }

        mutating func visitLink(_ link: Link) -> [InlineNode] {
            [.link(destination: link.destination ?? "", title: link.title, children: collectInlineChildren(link))]
        }

        mutating func visitImage(_ image: Image) -> [InlineNode] {
            [.image(source: image.source ?? "", alt: image.plainText)]
        }

        mutating func visitLineBreak(_: LineBreak) -> [InlineNode] { [.lineBreak] }

        mutating func visitSoftBreak(_: SoftBreak) -> [InlineNode] { [.softBreak] }

        private mutating func collectInlineChildren(_ container: any InlineContainer) -> [InlineNode] {
            var result = [InlineNode]()
            for child in container.inlineChildren {
                result += self.visit(child)
            }
            return result
        }
    }

    static func convert(_ document: Document) -> [BlockNode] {
        var visitor = BlockVisitor()
        return document.children.compactMap { visitor.visit($0) }
    }
}
