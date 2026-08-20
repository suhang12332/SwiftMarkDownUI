import Markdown
@testable import SwiftMarkDownUI
import XCTest

final class RenderingTests: XCTestCase {
    func testHTMLTableProducesAllRows() {
        let html = "<table><tr><th>Loader</th><th>Version</th></tr><tr><td>Fabric</td><td>1.21</td></tr><tr><td>Quilt</td><td>1.20.1</td></tr></table>"
        let blocks = ASTConverter.convert(Document(parsing: H2MD.convert(html)))

        guard case let .table(headers, _, rows) = blocks.first else {
            return XCTFail("Expected a Markdown table")
        }
        XCTAssertEqual(headers, ["Loader", "Version"])
        XCTAssertEqual(rows, [["Fabric", "1.21"], ["Quilt", "1.20.1"]])
    }

    func testHTMLBlocksRemainNative() {
        let html = "<svg width=\"10\" height=\"10\"><rect width=\"10\" height=\"10\" /></svg>\n\n<details><summary>Advanced</summary><p>Extra</p></details>"
        let blocks = ASTConverter.convert(Document(parsing: H2MD.convert(html)))

        XCTAssertEqual(blocks.filter {
            if case .html = $0 {
                return true
            }
            return false
        }.count, 1)
        XCTAssertTrue(H2MD.convert(html).contains("<svg"))
        XCTAssertTrue(H2MD.convert(html).contains("<details"))
    }
}
