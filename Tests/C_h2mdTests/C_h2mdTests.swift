import XCTest
@testable import C_h2md

final class C_h2mdTests: XCTestCase {
    func testVersion() {
        let v = h2md_version()
        XCTAssertNotNil(v)
    }

    func testNullEmpty() {
        XCTAssertEqual(String(cString: h2md_convert(nil)), "")
        XCTAssertEqual(String(cString: h2md_convert("")), "")
    }

    func testHeadings() {
        XCTAssertEqual(String(cString: h2md_convert("<h1>Hello</h1>")), "# Hello\n")
        XCTAssertEqual(String(cString: h2md_convert("<h2>World</h2>")), "## World\n")
    }

    func testParagraphs() {
        XCTAssertEqual(String(cString: h2md_convert("<p>Hello</p>")), "Hello\n")
        XCTAssertEqual(String(cString: h2md_convert("<p>One</p><p>Two</p>")), "One\n\nTwo\n")
    }

    func testBoldItalic() {
        XCTAssertEqual(String(cString: h2md_convert("<p><b>bold</b></p>")), "**bold**\n")
        XCTAssertEqual(String(cString: h2md_convert("<p><i>italic</i></p>")), "*italic*\n")
    }

    func testLinks() {
        let r = h2md_convert("<a href=\"http://example.com\">click</a>")!
        XCTAssertTrue(String(cString: r).contains("[click](http://example.com)"))
        h2md_free(r)
    }

    func testHTMLControlsAndIgnoredContent() {
        let input = "<p>Block one<br>Block two</p><button data-url=\"https://example.com/download\">Download</button><script>alert('x')</script><style>body{color:red}</style>"
        let result = String(cString: h2md_convert(input))
        XCTAssertTrue(result.contains("Block one  \nBlock two"))
        XCTAssertTrue(result.contains("[Download](https://example.com/download)"))
        XCTAssertFalse(result.contains("alert"))
        XCTAssertFalse(result.contains("color:red"))
    }

    func testTableMarkdown() {
        let input = "<table><tr><th>Loader</th><th>Version</th></tr><tr><td>Fabric</td><td>1.21</td></tr></table>"
        let result = String(cString: h2md_convert(input))
        XCTAssertTrue(result.contains("| Loader | Version |"))
        XCTAssertTrue(result.contains("| --- | --- |"))
        XCTAssertTrue(result.contains("| Fabric | 1.21 |"))
    }

    func testImages() {
        let r = h2md_convert("<img src=\"http://img.png\" alt=\"alt\">")!
        XCTAssertTrue(String(cString: r).contains("![alt](http://img.png)"))
        h2md_free(r)
    }

    func testSVGImages() {
        let r = h2md_convert("<img src=\"icon.svg\" alt=\"icon\">")!
        XCTAssertTrue(String(cString: r).contains("![icon](icon.svg)"))
        h2md_free(r)
    }

    func testNativeHTMLBlocks() {
        let input = "<svg width=\"10\" height=\"10\"><rect width=\"10\" height=\"10\" /></svg><details><summary>Advanced</summary><p>Extra</p></details>"
        let result = String(cString: h2md_convert(input))
        XCTAssertTrue(result.contains("<svg width=\"10\" height=\"10\">") )
        XCTAssertTrue(result.contains("<details><summary>Advanced</summary><p>Extra</p></details>"))
        XCTAssertFalse(result.contains("[SVG]"))
    }

    func testCode() {
        XCTAssertEqual(String(cString: h2md_convert("<p><code>code</code></p>")), "`code`\n")
        XCTAssertTrue(String(cString: h2md_convert("<pre><code>hello</code></pre>")).contains("```"))
    }

    func testLists() {
        XCTAssertEqual(String(cString: h2md_convert("<ul><li>a</li><li>b</li></ul>")), "- a\n- b\n")
        XCTAssertEqual(String(cString: h2md_convert("<ol><li>a</li><li>b</li></ol>")), "1. a\n2. b\n")
    }

    func testEntities() {
        XCTAssertEqual(String(cString: h2md_convert("<p>&lt;</p>")), "<\n")
        XCTAssertEqual(String(cString: h2md_convert("<p>&amp;</p>")), "&\n")
        XCTAssertEqual(String(cString: h2md_convert("<p>&#65;</p>")), "A\n")
    }

    func testGIFSkipped() {
        let r = h2md_convert("<img src=\"animation.gif\" alt=\"gif\">")!
        XCTAssertFalse(String(cString: r).contains("![gif]"))
        h2md_free(r)
    }

    func testVideoSkipped() {
        let r = h2md_convert("<video src=\"test.mp4\"></video>")!
        XCTAssertEqual(String(cString: r), "")
        h2md_free(r)
    }

    func testComplexDocument() {
        let input = "<h1>Title</h1><p>Text with <b>bold</b>.</p><ul><li>Item</li></ul>"
        let r = h2md_convert(input)!
        let result = String(cString: r)
        XCTAssertTrue(result.contains("# Title"))
        XCTAssertTrue(result.contains("**bold**"))
        XCTAssertTrue(result.contains("- Item"))
        h2md_free(r)
    }
}
