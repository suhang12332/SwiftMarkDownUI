# SwiftMarkDownUI

SwiftUI Markdown/HTML rendering via C converter + swift-markdown parser.

## Usage

```swift
import SwiftMarkDownUI

MixedMarkdownView("**bold** and <b>HTML bold</b>")
```

## Architecture

- `h2md` (C) — HTML → Markdown conversion (197 MB/s)
- `swift-markdown` — Markdown AST parser
- Custom SwiftUI renderer

## Build

```bash
swift build
```

## License

MIT
