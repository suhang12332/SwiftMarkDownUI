## SwiftMarkDownUI


SwiftMarkDownUI 是一个 Swift Package，用于在 SwiftUI 里展示 Markdown / HTML / 混合内容：

- 底层使用 [`MarkdownUI`](https://github.com/gonzalezreal/swift-markdown-ui)，兼容 GitHub Flavored Markdown（GFM）  
- 对于 `<b>` / `<strong>` / `<br>` / `<a>` 等 **轻量 HTML 片段**，通过 [`SwiftSoup`](https://github.com/scinfu/SwiftSoup) 转成 Markdown 后统一渲染  
- 对外只暴露一个简单 API：**`MixedMarkdownView`**

这个仓库本身也可以作为一个「如何在 Swift 项目里封装第三方 Markdown 库」的参考实现。

---

### 特性（Features）

- **纯 SwiftUI 渲染**：不使用 `WKWebView`，更轻量、可组合
- **混合内容支持**：同一段字符串中既可以写 Markdown，也可以写少量 HTML 内联标签
- **统一 Markdown 渲染链路**：所有内容最终都走 `MarkdownUI`，样式一致
- **简单 API 设计**：业务层只需要关心 `MixedMarkdownView(_:)`
- **易于复用与扩展**：内部通过小型分段器 + HTML → Markdown 转换器解耦

---

### 安装（Swift Package Manager）

#### 1. Package.swift 手动添加

```swift
dependencies: [
    .package(url: "https://github.com/suhang12332/SwiftMarkDownUI.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["SwiftMarkDownUI"]
    ),
]
```

#### 2. Xcode 图形界面

1. 打开 Xcode，目标项目选中后：`File` → `Add Package Dependencies...`  
2. 在搜索框填入仓库地址：  
   `https://github.com/suhang12332/SwiftMarkDownUI.git`  
3. 选择版本规则（推荐：`Up to Next Major`）  
4. 在对应 target 勾选 `SwiftMarkDownUI` 并完成添加

---

### 快速上手（Usage）

#### 最简单的用法

```swift
import SwiftUI
import SwiftMarkDownUI

struct ContentView: View {
    var body: some View {
        MixedMarkdownView(
            """
            **Markdown 粗体**
            和 <b>HTML 粗体</b> 混排，
            还可以带 `<a href="https://github.com">链接</a>`。
            """
        )
        .padding()
    }
}
```

#### 只写 Markdown 也可以

```swift
MixedMarkdownView("""
# 标题

正文里有 **加粗**、_斜体_ 和代码片段 `print("Hello")`。
""")
```

#### 只写 HTML 也可以

```swift
MixedMarkdownView("""
<h1>标题</h1>
<p>这是一段 <b>HTML</b> 文本。</p>
""")
```

> 内部会把可识别的 HTML 片段转换为 Markdown，再交给 MarkdownUI 渲染；  
> 未覆盖到的复杂 HTML 结构则不建议在这里使用（可以考虑 WebView）。

---

### 适用场景（When to Use）

- 在 App 内展示来自后台/接口的富文本说明，格式大多为 Markdown，夹杂少量 HTML
- 帮助中心 / FAQ / 更新日志等需要 Markdown 渲染的页面
- 想完全使用 SwiftUI，但又不想引入 WebView 的场景

不适合的场景：

- 需要完整 HTML/CSS/JS 支持的复杂网页 → 建议直接使用 `WKWebView`
- 需要大量自定义 HTML 渲染规则的场景

---

### 平台要求（Minimum Deployment Targets）

- **iOS 15+**
- **macOS 14+**

（如需支持更低版本，可自行参考本项目封装思路做裁剪或调整。）

---

### 参考/实现细节

内部主要由三部分组成（可作为封装参考）：

- `MixedMarkdownView`：对外暴露的 SwiftUI 组件
- `MarkupTextView`：内部通用渲染 View，统一把内容交给 `MarkdownUI`
- `MixedSegmenter` + `HTMLToMarkdown`：把混合字符串拆分为 Markdown / HTML 片段，并将 HTML 片段转换为 Markdown

如想在自己项目中实现类似能力，可以直接参考 `Sources/SwiftMarkDownUI` 下的实现结构。

---

### 参考项目（依赖与致谢）

本项目基于以下开源库进行封装，非常感谢原作者的工作：

- [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) —— 提供 SwiftUI 环境下的 Markdown 渲染能力  
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) —— 用于解析 HTML 并转换为文本/Markdown

---

### License

MIT License. 具体条款请见仓库中的 `LICENSE` 文件。
