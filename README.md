## SwiftMarkDownUI

Swift 包：不使用 WebKit 的 Markdown / HTML / 混合内容展示。使用 [MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) 渲染，兼容 GFM；HTML 片段经 [SwiftSoup](https://github.com/scinfu/SwiftSoup) 转为 Markdown 后统一渲染。

### 在其他项目中使用

#### 1. 添加依赖

**方式 A：本地路径**（开发调试用）

在目标项目的 `Package.swift` 里：

```swift
dependencies: [
    .package(path: "/Users/su/Development/XCodeProjects/SwiftMarkDownUI"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["SwiftMarkDownUI"]
    ),
]
```

**方式 B：Git 仓库**（已推送后）

```swift
dependencies: [
    .package(url: "https://github.com/<owner>/SwiftMarkDownUI.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: ["SwiftMarkDownUI"]
    ),
]
```

若用 Xcode：**File → Add Package Dependencies**，选上述路径或 URL，再在对应 target 勾选 `SwiftMarkDownUI`。

#### 2. 在代码里使用（仅混合模式）

```swift
import SwiftUI
import SwiftMarkDownUI

struct ContentView: View {
    var body: some View {
        // 混合内容（字符串里既可以写 Markdown 也可以写少量 HTML 片段）
        MixedMarkdownView("**粗体** 与 <b>HTML 粗体</b> 混排")
    }
}
```

> 当前版本仅对外暴露混合模式 `MixedMarkdownView`。  
> 你可以在同一个字符串里自由混写 Markdown 和少量 HTML 片段（如 `<b>`、`<strong>`、`<br>`、`<a>` 等）；  
> 如果字符串里实际上只有 Markdown 或只有 HTML，也会被正常渲染。

### 最低平台

- macOS 14  
- iOS 15
