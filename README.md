## SwiftMarkDownUI


SwiftMarkDownUI 是一个 Swift Package，用于在 SwiftUI 里展示 Markdown / HTML / 混合内容：

- 底层使用 [`MarkdownUI`](https://github.com/gonzalezreal/swift-markdown-ui)，兼容 GitHub Flavored Markdown（GFM）  
- 对于 `<b>` / `<strong>` / `<br>` / `<a>` 等 **轻量 HTML 片段**，通过 [`SwiftSoup`](https://github.com/scinfu/SwiftSoup) 转成 Markdown 后统一渲染  
- 对外只暴露一个简单 API：**`MixedMarkdownView`**

本包服务于 [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher)

### 参考项目（依赖与致谢）

本项目基于以下开源库进行封装，非常感谢原作者的工作：

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) —— 提供 SwiftUI 环境下的 Markdown 渲染能力  
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) —— 用于解析 HTML 并转换为文本/Markdown

---

### License

MIT License. 具体条款请见仓库中的 `LICENSE` 文件。
