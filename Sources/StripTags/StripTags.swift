import Foundation
import SwiftSoup

/// Elements that should be followed by a newline, derived from
/// https://www.w3.org/TR/2011/WD-html5-20110405/rendering.html#display-types
public let newlineElements: Set<String> = [
    // display: block; default in the spec
    "address", "article", "aside", "blockquote", "body", "center", "dd", "dir",
    "div", "dl", "dt", "figure", "figcaption", "footer", "form", "h1", "h2",
    "h3", "h4", "h5", "h6", "header", "hgroup", "hr", "html", "legend",
    "listing", "menu", "nav", "ol", "p", "plaintext", "pre", "section",
    "summary", "ul", "xmp",
    // And <li> too, which default to display: list-item; in the spec:
    "li"
]

/// CSS selectors for elements with display: none
public let displayNoneSelectors: [String] = [
    "[hidden]", "area", "base", "basefont", "command", "datalist", "head",
    "input[type=hidden]", "link", "menu[type=context]", "meta", "noembed",
    "noframes", "param", "rp", "script", "source", "style", "track", "title"
]

/// Self-closing HTML tags
public let selfClosingTags: Set<String> = [
    "area", "base", "br", "col", "command", "embed", "hr", "img", "input",
    "keygen", "link", "meta", "param", "source", "track", "wbr"
]

/// Tag bundles for convenience
public let bundles: [String: [String]] = [
    "hs": ["h1", "h2", "h3", "h4", "h5", "h6"],
    "metadata": ["title", "meta"],
    "structure": ["header", "nav", "main", "article", "section", "aside", "footer"],
    "tables": ["table", "tr", "td", "th", "thead", "tbody", "tfoot", "caption", "colgroup", "col"],
    "lists": ["ul", "ol", "li", "dl", "dd", "dt"]
]

/// Attributes to keep for specific tags
public let attrsToKeep: [String: Set<String>] = [
    "a": ["href"],
    "img": ["alt"],
    "meta": ["name", "value", "property", "content"]
]

/// Strip tags from HTML, optionally from areas identified by CSS selectors
///
/// - Parameters:
///   - input: The HTML string to process
///   - selectors: CSS selectors to target specific elements (defaults to ["html"])
///   - removes: CSS selectors for elements to remove entirely
///   - minify: Whether to minify whitespace
///   - removeBlankLines: Whether to remove blank lines from output
///   - first: Whether to return only the first matching element
///   - keepTags: Tags to keep in the output (with limited attributes)
///   - allAttrs: Whether to keep all attributes on kept tags
/// - Returns: The processed text with tags stripped according to the parameters
public func stripTags(
    _ input: String,
    selectors: [String]? = nil,
    removes: [String]? = nil,
    minify: Bool = false,
    removeBlankLines: Bool = false,
    first: Bool = false,
    keepTags: [String]? = nil,
    allAttrs: Bool = false
) throws -> String {
    let doc = try SwiftSoup.parse(input)

    let finalSelectors = selectors?.isEmpty == false ? selectors! : ["html"]
    var outputBits: [String] = []

    // Remove specified elements
    if let removes = removes {
        for removeSelector in removes {
            let elements = try doc.select(removeSelector)
            try elements.forEach { try $0.remove() }
        }
    }

    // Expand tag bundles
    var expandedKeepTags: [String] = []
    if let keepTags = keepTags {
        for tag in keepTags {
            if let bundleTags = bundles[tag] {
                expandedKeepTags.append(contentsOf: bundleTags)
            } else {
                expandedKeepTags.append(tag)
            }
        }
    }

    let keepTagsSet = Set(expandedKeepTags)

    // Helper function to check if element should be kept
    func shouldKeep(_ element: Element) -> Bool {
        if keepTagsSet.contains(element.tagName()) {
            return true
        }
        for tagName in keepTagsSet {
            if (try? element.select(tagName).first()) != nil {
                return true
            }
        }
        return false
    }

    // Remove elements with display: none, but only if they shouldn't be kept
    for noneSelector in displayNoneSelectors {
        let elements = try doc.select(noneSelector)
        for element in elements {
            if !shouldKeep(element) {
                try element.remove()
            }
        }
    }

    // Replace images with alt text
    if !keepTagsSet.contains("img") {
        let images = try doc.select("img[alt]")
        for img in images {
            if let alt = try? img.attr("alt") {
                try img.replaceWith(TextNode(alt, nil))
            }
        }
    }

    // Extract text from selected elements
    var breakOut = false
    for selector in finalSelectors {
        let elements = try doc.select(selector)
        for element in elements {
            let processed = try processNode(element, minify: minify, keepTags: keepTagsSet, allAttrs: allAttrs)
            outputBits.append(processed)
            if newlineElements.contains(element.tagName()) {
                outputBits.append("\n")
            }
            if first {
                breakOut = true
                break
            }
        }
        if breakOut {
            break
        }
    }

    var output = outputBits.joined().trimmingCharacters(in: .whitespacesAndNewlines)

    if removeBlankLines {
        output = output.split(separator: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: "\n")
    }

    return output
}

/// Process a node recursively
private func processNode(
    _ node: Node,
    minify: Bool,
    keepTags: Set<String>,
    allAttrs: Bool
) throws -> String {
    if node is Comment {
        return ""
    }

    if let textNode = node as? TextNode {
        let text = textNode.text()
        if minify {
            return minifyWhitespace(text)
        } else {
            return text
        }
    }

    if let element = node as? Element {
        let tagName = element.tagName()

        if tagName == "pre" {
            let text = try element.text()
            if keepTags.contains("pre") {
                return try tagWithAttributes(element, content: text, allAttrs: allAttrs)
            } else {
                return text
            }
        }

        var bits: [String] = []
        for child in element.getChildNodes() {
            let processed = try processNode(child, minify: minify, keepTags: keepTags, allAttrs: allAttrs)
            bits.append(processed)
            // Add newline after block-level elements
            if let childElement = child as? Element,
               newlineElements.contains(childElement.tagName()) {
                bits.append("\n")
            }
        }

        var result = bits.joined()

        if keepTags.contains(tagName) {
            result = try tagWithAttributes(element, content: result, allAttrs: allAttrs)
        }

        return result
    }

    return ""
}

/// Minify whitespace in text
private func minifyWhitespace(_ text: String) -> String {
    let pattern = "\\s+"
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(text.startIndex..., in: text)

    var result = ""
    var lastEnd = text.startIndex

    regex.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
        guard let match = match else { return }
        let matchRange = Range(match.range, in: text)!

        // Add text before match
        result += text[lastEnd..<matchRange.lowerBound]

        // Process whitespace
        let whitespace = String(text[matchRange])
        let newlineCount = whitespace.filter { $0 == "\n" }.count

        if newlineCount >= 2 {
            result += "\n\n"
        } else if newlineCount == 1 {
            result += "\n"
        } else {
            result += " "
        }

        lastEnd = matchRange.upperBound
    }

    // Add remaining text
    result += text[lastEnd...]

    // Special case: if result is just a newline, replace with space
    if result == "\n" {
        return " "
    }

    return result
}

/// Generate tag with attributes
private func tagWithAttributes(
    _ element: Element,
    content: String,
    allAttrs: Bool
) throws -> String {
    let tagName = element.tagName()
    var toKeep: Set<String> = ["id", "class"]

    if let specificAttrs = attrsToKeep[tagName] {
        toKeep.formUnion(specificAttrs)
    }

    var bits: [String] = ["<\(tagName)"]

    if let attrs = element.getAttributes() {
        for attr in attrs {
            let key = attr.getKey()
            let value = attr.getValue()
            if allAttrs || toKeep.contains(key) {
                bits.append("\(key)=\"\(value)\"")
            }
        }
    }

    var output = bits.joined(separator: " ") + ">" + content

    if !selfClosingTags.contains(tagName) {
        output += "</\(tagName)>"
    }

    return output
}
