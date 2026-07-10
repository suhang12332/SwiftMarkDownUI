## SwiftMarkDownUI

SwiftMarkDownUI 是一个纯 Swift Package，用于在 SwiftUI 里展示 Markdown / HTML / 混合内容：

- 使用 [swift-markdown](https://github.com/swiftlang/swift-markdown) 解析 Markdown AST，自行渲染为 SwiftUI 视图
- 对于 `<b>` / `<strong>` / `<br>` / `<a>` 等 **轻量 HTML 片段**，通过内置 C 库 `h2md` 转成 Markdown 后统一渲染
- 对外只暴露一个简单 API：**`MixedMarkdownView`**

本包服务于 [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher)

## Usage

```swift
import SwiftMarkDownUI

MixedMarkdownView("**bold** and <b>HTML bold</b>")
```

## Architecture

- `C_h2md` (C) — HTML → Markdown 转换
- `Markdown` (Apple swift-markdown) — Markdown 解析为 AST
- `InlineRenderer` / `MarkdownRenderer` — 将 AST 渲染为 SwiftUI 视图（Heading、Paragraph、CodeBlock、List、Table、Blockquote 等）

## Build

```bash
swift build
```

### License

MIT License. 具体条款请见仓库中的 `LICENSE` 文件。
