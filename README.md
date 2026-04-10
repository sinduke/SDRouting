# SDRouting

`SDRouting` 是一个面向 SwiftUI 的轻量路由层，统一管理：

- `push`
- `sheet`
- `fullScreenCover`
- `alert / confirmationDialog`
- 自定义 `modal`

它的目标不是再包一层“语法糖”，而是给 SwiftUI 建一个更稳定的页面流转模型。

## 平台要求

- iOS 16+
- macOS 15+
- Swift 6

## 安装

### Swift Package Manager

```swift
dependencies: [
  .package(url: "https://github.com/sinduke/SDRouting.git", from: "1.0.0")
]
```

然后在目标中引入：

```swift
dependencies: [
  .product(name: "SDRouting", package: "SDRouting")
]
```

## 快速开始

```swift
import SwiftUI
import SDRouting

struct RootView: View {
  var body: some View {
    RouterView { router in
      HomeView(router: router)
    }
  }
}

struct HomeView: View {
  let router: RouterProtocol

  var body: some View {
    VStack(spacing: 16) {
      Button("Push") {
        router.navigateTo(.push) { router in
          DetailView(router: router)
        }
      }

      Button("Sheet") {
        router.navigateTo(.sheet) { router in
          DetailView(router: router)
        }
      }

      Button("Full Screen") {
        router.navigateTo(.fullScreenCover) { router in
          DetailView(router: router)
        }
      }
    }
    .padding()
  }
}

struct DetailView: View {
  let router: RouterProtocol

  var body: some View {
    VStack(spacing: 16) {
      Text("Detail")

      Button("Dismiss") {
        router.dismissScreen()
      }
    }
    .padding()
  }
}
```

## 核心设计

`SDRouting` 现在采用两个明确分离的上下文：

### 1. Navigation Context

负责当前 `NavigationStack` 的 `path`。

规则：

- `push` 复用当前 navigation context
- 同一条 push 链共享同一个 `path`

### 2. Presentation Context

负责当前展示层的：

- `sheet`
- `fullScreenCover`
- `alert`
- `modal`

规则：

- `sheet` 会创建一个新的 presentation context
- `fullScreenCover` 也会创建一个新的 presentation context
- 当前 context 内只有根节点负责真正挂载 presentation modifier

这意味着：

- pushed page 不再自己挂 `.sheet` / `.fullScreenCover`
- pushed page 只是当前上下文中的一个 screen
- 真正的展示宿主只有当前 context root

这套规则是整个库稳定性的关键。

## 为什么这样设计

之前最容易出问题的结构是：

`fullScreenCover -> sheet -> fullScreenCover -> push -> sheet`

旧实现里，每个递归的 `RouterView` 都会自己挂：

- `.sheet`
- `.fullScreenCover`
- `.alert`
- `.modal`

这会导致两个问题：

1. `push` 页面也会成为 presentation host  
2. `fullScreenCover` 内部再弹 `sheet` 时，SwiftUI 会反复重建展示宿主

具体表现就是：

- `fullScreen.content.appear/disappear` 反复抖动
- `sheet` 看起来像直接覆盖全屏
- 长按导航栏返回按钮时，系统在读取历史导航项时可能闪退

根因不是业务页面本身，而是 presentation host 分散在整条递归视图树里，导致宿主不稳定。

## 这次修复做了什么

核心修复不是改某一个 `fullScreenCover` 调用，而是改路由结构：

1. 引入 `RouterPresentationCoordinator`

它集中管理当前 context 的展示状态：

- `path`
- `sheet`
- `fullScreenCover`
- `alert`
- `modal`

2. 把 `RouterView` 分成两种角色

- `hostsPresentation == true`
  当前 context 的根节点，会挂所有 presentation modifier
- `hostsPresentation == false`
  纯 push 页面，不再挂 presentation modifier

3. 明确路由规则

- `push`：复用当前 coordinator，且新页面 `hostsPresentation = false`
- `sheet`：创建新的 coordinator，且新页面 `hostsPresentation = true`
- `fullScreenCover`：创建新的 coordinator，且新页面 `hostsPresentation = true`

最终效果是：

- 一个 presentation context 只有一个宿主
- push 链不会再把 presentation host 越推越深
- `sheet/fullScreenCover` 的宿主位置稳定
- 嵌套 `full -> sheet -> full -> push -> sheet` 的行为恢复正常

## RouterProtocol

对外统一入口是 `RouterProtocol`：

```swift
@MainActor
public protocol RouterProtocol {
  func navigateTo<T: View>(
    _ segue: SegueType,
    @ViewBuilder destination: @escaping (RouterProtocol) -> T
  )

  func dismissScreen()

  func showAlert(_ alert: AnyAppAlert)
  func dismissAlert()

  func showModal<T: View>(
    configuration: AppModalConfiguration,
    @ViewBuilder content: @escaping () -> T
  )

  func dismissModal()
}
```

## 常见用法

### Push

```swift
router.navigateTo(.push) { router in
  DetailView(router: router)
}
```

### Sheet

```swift
router.navigateTo(.sheet) { router in
  SettingsView(router: router)
}
```

### Full Screen Cover

```swift
router.navigateTo(.fullScreenCover) { router in
  LoginView(router: router)
}
```

### Alert

```swift
router.showAlert(
  .ok(title: "Done", message: "Saved successfully.")
)
```

确认弹窗：

```swift
router.showAlert(
  .confirm(
    title: "Delete",
    message: "This action cannot be undone.",
    confirmTitle: "Delete"
  ) {
    print("delete confirmed")
  }
)
```

### Custom Modal

```swift
router.showModal {
  VStack(spacing: 12) {
    Text("Custom Modal")
    Button("Close") {
      router.dismissModal()
    }
  }
  .padding()
}
```

如果需要自定义展示参数：

```swift
router.showModal(configuration: .default) {
  Text("Modal Content")
}
```

## Environment 注入

`RouterView` 会自动把 `router` 注入环境。

```swift
struct ChildView: View {
  @Environment(\.router) private var router

  var body: some View {
    Button("Open") {
      router.navigateTo(.push) { router in
        Text("Next")
      }
    }
  }
}
```

如果你更重视依赖清晰，也可以继续显式传 `RouterProtocol`。

## 调试日志

库内置了调试输出：

```swift
import SDRouting

@main
struct DemoApp: App {
  init() {
    SDRoutingDebug.isEnabled = true
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
  }
}
```

也可以自定义输出方式：

```swift
SDRoutingDebug.printer = { message in
  print(message)
}
```

当前日志会输出：

- `routerID`
- `coordinatorID`
- `hostsPresentation`
- `path`
- `sheet`
- `fullScreen`
- `modal`
- `alert`

这些信息足够定位大多数路由链问题。

## AnyAppAlert.AppButton

`AnyAppAlert.AppButton` 现在可以在包外直接构造：

```swift
let button = AnyAppAlert.AppButton(
  title: "OK",
  role: .cancel
)
```

也可以继续使用便捷方法：

- `.ok()`
- `.cancel()`
- `.destructive(...)`

## 当前语义总结

可以把 `SDRouting` 理解成下面这套规则：

- `push` 是“当前导航上下文内继续前进”
- `sheet` 是“开启一个新的展示上下文”
- `fullScreenCover` 是“开启一个新的全屏展示上下文”
- 每个展示上下文只有一个真正的 presentation host
- pushed page 不承担 presentation host 角色

这也是当前版本能稳定处理复杂嵌套场景的根本原因。
