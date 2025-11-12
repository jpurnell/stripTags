import XCTest
@testable import StripTags

final class StripTagsTests: XCTestCase {
    func testBasicStripping() throws {
        let html = "<div><h1>This has tags</h1><p>And whitespace too</p></div>Ignore this bit."
        let result = try stripTags(html, selectors: ["div"])
        // Both h1 and p are block elements, so there should be a newline after each
        XCTAssertTrue(result.contains("This has tags"))
        XCTAssertTrue(result.contains("And whitespace too"))
        // There should be at least one newline between them
        XCTAssertTrue(result.contains("\n"))
    }

    func testMinify() throws {
        let html = "<div><h1>This has tags</h1>\n\n<p>And whitespace too</p></div>Ignore this bit."
        let result = try stripTags(html, selectors: ["div"], minify: true)
        XCTAssertTrue(result.contains("This has tags"))
        XCTAssertTrue(result.contains("And whitespace too"))
    }

    func testKeepTags() throws {
        let html = "<div><h1>This has tags</h1><p>And whitespace too</p></div>"
        let result = try stripTags(html, selectors: ["div"], keepTags: ["h1"])
        XCTAssertTrue(result.contains("<h1>"))
        XCTAssertTrue(result.contains("</h1>"))
        XCTAssertTrue(result.contains("This has tags"))
        XCTAssertFalse(result.contains("<p>"))
    }

    func testRemoveBlankLines() throws {
        let html = "<div><h1>Line 1</h1>\n\n\n<p>Line 2</p></div>"
        let result = try stripTags(html, selectors: ["div"], removeBlankLines: true)
        let lines = result.split(separator: "\n")
        XCTAssertTrue(lines.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    func testFirstSelector() throws {
        let html = "<div>First div</div><div>Second div</div>"
        let result = try stripTags(html, selectors: ["div"], first: true)
        XCTAssertEqual(result, "First div")
    }

    func testRemoveSelector() throws {
        let html = "<div><nav>Navigation</nav><p>Content</p></div>"
        let result = try stripTags(html, selectors: ["div"], removes: ["nav"])
        XCTAssertFalse(result.contains("Navigation"))
        XCTAssertTrue(result.contains("Content"))
    }

    func testImageAltText() throws {
        let html = "<div><img alt=\"A picture\" src=\"image.jpg\"/><p>Text</p></div>"
        let result = try stripTags(html, selectors: ["div"])
        XCTAssertTrue(result.contains("A picture"))
        XCTAssertTrue(result.contains("Text"))
        XCTAssertFalse(result.contains("<img"))
    }

    func testKeepImageTag() throws {
        let html = "<div><img alt=\"A picture\" src=\"image.jpg\"/></div>"
        let result = try stripTags(html, selectors: ["div"], keepTags: ["img"])
        XCTAssertTrue(result.contains("<img"))
        XCTAssertTrue(result.contains("alt=\"A picture\""))
    }

    func testTagBundles() throws {
        let html = "<div><h1>H1</h1><h2>H2</h2><h3>H3</h3></div>"
        let result = try stripTags(html, selectors: ["div"], keepTags: ["hs"])
        XCTAssertTrue(result.contains("<h1>"))
        XCTAssertTrue(result.contains("<h2>"))
        XCTAssertTrue(result.contains("<h3>"))
    }

    func testKeepAttributes() throws {
        let html = "<div><a href=\"https://example.com\" class=\"link\" data-foo=\"bar\">Link</a></div>"
        let result = try stripTags(html, selectors: ["div"], keepTags: ["a"])
        XCTAssertTrue(result.contains("href=\"https://example.com\""))
        XCTAssertTrue(result.contains("class=\"link\""))
        // data-foo should be excluded unless allAttrs is true
        XCTAssertFalse(result.contains("data-foo"))
    }

    func testAllAttrs() throws {
        let html = "<div><a href=\"https://example.com\" class=\"link\" data-foo=\"bar\">Link</a></div>"
        let result = try stripTags(html, selectors: ["div"], keepTags: ["a"], allAttrs: true)
        XCTAssertTrue(result.contains("data-foo=\"bar\""))
    }

    func testScriptStyleRemoval() throws {
        let html = "<div><script>alert('test');</script><p>Content</p><style>body{color:red;}</style></div>"
        let result = try stripTags(html, selectors: ["div"])
        XCTAssertFalse(result.contains("alert"))
        XCTAssertFalse(result.contains("color:red"))
        XCTAssertTrue(result.contains("Content"))
    }

    func testPreTag() throws {
        let html = "<div><pre>  Formatted\n  Text  </pre></div>"
        let result = try stripTags(html, selectors: ["div"])
        // Pre tag content should be preserved without minification
        XCTAssertTrue(result.contains("Formatted"))
        XCTAssertTrue(result.contains("Text"))
    }

    func testMinifyWhitespace() throws {
        let html = "<div>Multiple    spaces   and\n\n\nmultiple newlines</div>"
        let result = try stripTags(html, selectors: ["div"], minify: true)
        XCTAssertFalse(result.contains("    "))
        XCTAssertTrue(result.contains("Multiple spaces"))
    }

    func testEmptyInput() throws {
        let html = ""
        let result = try stripTags(html)
        XCTAssertEqual(result, "")
    }

    func testMultipleSelectors() throws {
        let html = "<div class=\"content\">Content</div><div class=\"sidebar\">Sidebar</div><div class=\"footer\">Footer</div>"
        let result = try stripTags(html, selectors: [".content", ".sidebar"])
        XCTAssertTrue(result.contains("Content"))
        XCTAssertTrue(result.contains("Sidebar"))
        XCTAssertFalse(result.contains("Footer"))
    }

    func testComplexHTML() throws {
        let html = """
        <html>
        <head><title>Test Page</title></head>
        <body>
            <header><h1>Welcome</h1></header>
            <nav><a href="/">Home</a></nav>
            <main>
                <article>
                    <h2>Article Title</h2>
                    <p>Article content with <strong>bold</strong> text.</p>
                </article>
            </main>
            <footer>Copyright 2024</footer>
        </body>
        </html>
        """
        let result = try stripTags(html, selectors: ["article"])
        XCTAssertTrue(result.contains("Article Title"))
        XCTAssertTrue(result.contains("Article content"))
        XCTAssertTrue(result.contains("bold"))
        XCTAssertFalse(result.contains("Welcome"))
        XCTAssertFalse(result.contains("Copyright"))
    }
}
