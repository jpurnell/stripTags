import Foundation
import ArgumentParser
import StripTags

@main
struct StripTagsCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "strip-tags",
        abstract: "Strip tags from HTML, optionally from areas identified by CSS selectors",
        discussion: """
        Example usage:

            cat input.html | strip-tags > output.txt

        To run against just specific areas identified by CSS selectors:

            cat input.html | strip-tags .entry .footer > output.txt
        """,
        version: "0.6"
    )

    @Argument(help: "CSS selectors to target specific elements")
    var selectors: [String] = []

    @Option(name: .shortAndLong, help: "Remove content in these selectors")
    var remove: [String] = []

    @Option(name: .shortAndLong, help: "Input file (defaults to stdin)")
    var input: String?

    @Flag(name: .shortAndLong, help: "Minify whitespace")
    var minify: Bool = false

	@Option(name: [.customShort("t"), .customLong("keep-tag")], help: "Keep these <tags>")
    var keepTag: [String] = []

    @Flag(help: "Include all attributes on kept tags")
    var allAttrs: Bool = false

    @Flag(help: "First element matching the selectors")
    var first: Bool = false

    mutating func run() throws {
        let htmlInput: String

        // Read input from file or stdin
        if let inputFile = input {
            let url = URL(fileURLWithPath: inputFile)
            let data = try Data(contentsOf: url)

            // Try to detect encoding, fallback to UTF-8
            if let detected = String(data: data, encoding: .utf8) {
                htmlInput = detected
            } else if let detected = String(data: data, encoding: .utf16) {
                htmlInput = detected
            } else if let detected = String(data: data, encoding: .ascii) {
                htmlInput = detected
            } else {
                // Last resort: force UTF-8 decoding
                htmlInput = String(decoding: data, as: UTF8.self)
            }
        } else {
            // Read from stdin
            var stdinData = Data()
            while let line = readLine(strippingNewline: false) {
                if let data = line.data(using: .utf8) {
                    stdinData.append(data)
                }
            }

            if let detected = String(data: stdinData, encoding: .utf8) {
                htmlInput = detected
            } else if let detected = String(data: stdinData, encoding: .utf16) {
                htmlInput = detected
            } else {
                htmlInput = String(decoding: stdinData, as: UTF8.self)
            }
        }

        // Process the HTML
        let result = try stripTags(
            htmlInput,
            selectors: selectors.isEmpty ? nil : selectors,
            removes: remove.isEmpty ? nil : remove,
            minify: minify,
            removeBlankLines: minify,
            first: first,
            keepTags: keepTag.isEmpty ? nil : keepTag,
            allAttrs: allAttrs
        )

        print(result)
    }
}
