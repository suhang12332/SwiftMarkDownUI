# SwiftMarkDownUI

SwiftUI Markdown/HTML rendering via C converter + [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui).

## Usage

```swift
import SwiftMarkDownUI

MixedMarkdownView("**bold** and <b>HTML bold</b>")
```

## Architecture

- `h2md` (C) — HTML → Markdown conversion
- `MarkdownUI` — Markdown rendering via SwiftUI `Markdown` view

## Build

```bash
swift build
```

## License

MIT
