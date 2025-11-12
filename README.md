# StripTags (Swift)

A Swift package for stripping HTML tags from content, with support for CSS selectors, minification, and selective tag retention.

This is a Swift translation of the [Python strip-tags](https://github.com/simonw/strip-tags) project by Simon Willison.

## Features

- Strip HTML tags from content
- Target specific elements using CSS selectors
- Remove specific sections by selector
- Minify whitespace
- Keep specific tags with their markup
- Support for tag bundles (headings, lists, tables, etc.)
- Command-line tool and Swift library

## Installation

### Swift Package Manager

Add this package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/jpurnell/strip-tags-swift.git", from: "1.0.0")
]
```

Then add it to your target dependencies:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["StripTags"])
]
```

### Command-Line Tool

Build and install the CLI tool:

```bash
swift build -c release
cp .build/release/strip-tags /usr/local/bin/
```

Or run directly:

```bash
swift run strip-tags --help
```

## Usage

### Command Line

Pipe content into the tool to strip tags:

```bash
cat input.html | strip-tags > output.txt
```

Or pass a filename:

```bash
strip-tags -i input.html > output.txt
```

Target specific areas with CSS selectors:

```bash
strip-tags '.content' -i input.html > output.txt
```

Multiple selectors:

```bash
cat input.html | strip-tags '.content' '.sidebar' > output.txt
```

Return just the first matching element:

```bash
cat input.html | strip-tags .content --first > output.txt
```

Remove specific sections:

```bash
cat input.html | strip-tags -r nav > output.txt
```

Minify whitespace:

```bash
cat input.html | strip-tags -m > output.txt
```

### Keeping Specific Tags

Keep certain tags in the output (useful for language models):

```bash
curl -s https://datasette.io/ | strip-tags header --keep-tag h1 --keep-tag li
```

Output:
```html
<li>Uses</li>
<li>Documentation Docs</li>
<h1>Datasette</h1>
Find stories in data
```

Attributes are filtered to only include `id`, `class`, `href` (for links), `alt` (for images), and `name`/`value`/`property`/`content` (for meta tags).

### Tag Bundles

Use tag bundles for convenience:

```bash
strip-tags --keep-tag hs  # Keeps all heading tags (h1-h6)
```

Available bundles:

- `-t hs`: `<h1>`, `<h2>`, `<h3>`, `<h4>`, `<h5>`, `<h6>`
- `-t metadata`: `<title>`, `<meta>`
- `-t structure`: `<header>`, `<nav>`, `<main>`, `<article>`, `<section>`, `<aside>`, `<footer>`
- `-t tables`: `<table>`, `<tr>`, `<td>`, `<th>`, `<thead>`, `<tbody>`, `<tfoot>`, `<caption>`, `<colgroup>`, `<col>`
- `-t lists`: `<ul>`, `<ol>`, `<li>`, `<dl>`, `<dd>`, `<dt>`

### As a Swift Library

Import and use in your Swift code:

```swift
import StripTags

let html = """
<div>
<h1>This has tags</h1>

<p>And whitespace too</p>
</div>
Ignore this bit.
"""

let stripped = try stripTags(
    html,
    selectors: ["div"],
    minify: true,
    keepTags: ["h1"]
)

print(stripped)
```

Output:
```
<h1>This has tags</h1>

And whitespace too
```

#### Function Signature

```swift
func stripTags(
    _ input: String,
    selectors: [String]? = nil,
    removes: [String]? = nil,
    minify: Bool = false,
    removeBlankLines: Bool = false,
    first: Bool = false,
    keepTags: [String]? = nil,
    allAttrs: Bool = false
) throws -> String
```

**Parameters:**

- `input`: The HTML string to process
- `selectors`: CSS selectors to target specific elements (defaults to `["html"]`)
- `removes`: CSS selectors for elements to remove entirely
- `minify`: Whether to minify whitespace
- `removeBlankLines`: Whether to remove blank lines from output
- `first`: Whether to return only the first matching element
- `keepTags`: Tags to keep in the output (with limited attributes)
- `allAttrs`: Whether to keep all attributes on kept tags

## CLI Help

```
USAGE: strip-tags [<selectors> ...] [--remove TEXT ...] [--input FILENAME] [--minify] [--keep-tag TEXT ...] [--all-attrs] [--first]

ARGUMENTS:
  <selectors>             CSS selectors to target specific elements

OPTIONS:
  --version               Show the version.
  -r, --remove TEXT  	  Remove content in these selectors
  -i, --input FILENAME     Input file (defaults to stdin)
  -m, --minify            Minify whitespace
  -t  --keep-tag TEXT     Keep these <tags>
  --all-attrs             Include all attributes on kept tags
  --first                 First element matching the selectors
  -h, --help              Show help information.
```

## Development

### Running Tests

```bash
swift test
```

### Building

```bash
swift build
```

### Release Build

```bash
swift build -c release
```

## Requirements

- Swift 5.9+
- macOS 13+, iOS 16+, tvOS 16+, or watchOS 9+

## Dependencies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - Swift HTML parser (similar to BeautifulSoup)
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - Command-line argument parsing

## Credits

This Swift package is a translation of the [Python strip-tags](https://github.com/simonw/strip-tags) project by Simon Willison.

## License

Apache License, Version 2.0 (same as the original Python project)
