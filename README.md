# SwiftMarkDownUI

A Swift Package for rendering Markdown, HTML, and mixed content in SwiftUI using a `swift-markdown` AST and a lightweight HTML-to-Markdown bridge. This package is used by [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher).

## Features

- Markdown parsing and native SwiftUI rendering
- Lightweight inline HTML support via the `h2md` C library
- Headings, paragraphs, lists, tables, code blocks, blockquotes, and images
- Text selection and dynamic content updates
- Single public API

## Entry Points

- `MixedMarkdownView`: renders mixed Markdown and HTML content

## Requirements

- macOS 14+
- Swift 6
