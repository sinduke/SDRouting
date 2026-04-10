# SDRouting

`SDRouting` 是一个基于 SwiftUI 的轻量级路由封装，用一个统一的 `RouterProtocol` 管理常见页面流转与弹层行为。

它当前覆盖的能力包括：

- `push` 导航
- `sheet` 展示
- `fullScreenCover` 展示
- 系统 `alert / confirmationDialog`
- 自定义内容型 `modal`

适合的场景：

- 不想在每个页面手动维护一堆 `@State` 导航状态
- 想把页面跳转、弹窗、模态层统一收口到一个路由对象
- 希望在 SwiftUI 页面树中通过环境值拿到同一个路由入口

## 平台要求

- iOS 16+
- macOS 15+
- Swift 6 / SwiftPM tools 6.3

## 安装

### Swift Package Manager

如果你已经把项目托管到 Git 仓库，可以在 Xcode 中通过 `Add Package Dependency` 添加。

也可以在 `Package.swift` 中声明：

```swift
dependencies: [
    .package(url: "[SDRouting](https://github.com/sinduke/SDRouting.git)", from: "1.0.0")
]
```

然后在目标中引入：

```swift
dependencies: [
    .product(name: "SDRouting", package: "SDRouting")
]
```

如果你当前是本地开发，也可以直接以本地 package 的方式添加。

## 核心概念

### 1. RouterView

`RouterView` 是整个库的入口容器。它会在内部维护：

- `NavigationStack` 的路径
- `sheet`
- `fullScreenCover`
- `alert`
- 自定义 `modal`

你通常会把它作为页面根容器使用。

### 2. RouterProtocol

`RouterProtocol` 是对外暴露的统一路由接口，当前主要方法有：

- `navigateTo(_:destination:)`
- `dismissScreen()`
- `showAlert(_:)`
- `dismissAlert()`
- `showModal(configuration:content:)`
- `dismissModal()`

这个协议被标记为 `@MainActor`，意味着所有路由操作都应该在主线程 UI 上下文里执行。

### 3. SegueType

`SegueType` 用于声明跳转方式：

- `.push`
- `.sheet`
- `.fullScreenCover`

## 最基本用法

下面是一个最小可运行的结构示例：

```swift
import SwiftUI
import SDRouting

struct RootView: View {
    var body: some View {
        RouterView { router in
            HomePage(router: router)
        }
    }
}

struct HomePage: View {
    let router: RouterProtocol

    var body: some View {
        VStack(spacing: 16) {
            Button("Push 到详情页") {
                router.navigateTo(.push) { router in
                    DetailPage(router: router)
                }
            }

            Button("Sheet 打开详情页") {
                router.navigateTo(.sheet) { router in
                    DetailPage(router: router)
                }
            }

            Button("FullScreenCover 打开详情页") {
                router.navigateTo(.fullScreenCover) { router in
                    DetailPage(router: router)
                }
            }
        }
        .padding()
    }
}

struct DetailPage: View {
    let router: RouterProtocol

    var body: some View {
        VStack(spacing: 16) {
            Text("Detail Page")

            Button("关闭当前页面") {
                router.dismissScreen()
            }
        }
        .padding()
    }
}
```

## 推荐接入方式

### 方式一：在根页面显式传入 router

这是当前最直观、也最稳定的方式：

```swift
RouterView { router in
    HomePage(router: router)
}
```

优点：

- 依赖关系清晰
- 页面更容易测试
- 不依赖环境注入的隐式行为

### 方式二：通过环境值读取 router

源码中已经向 `EnvironmentValues` 注入了 `router`。

在视图中可以这样读取：

```swift
import SwiftUI
import SDRouting

struct HomePage: View {
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

更适合：

- 深层子视图不方便一层层传参
- 希望页面代码更简洁

## 导航示例

### Push

```swift
router.navigateTo(.push) { router in
    DetailPage(router: router)
}
```

特点：

- 进入同一个导航栈
- 适合标准页面跳转

### Sheet

```swift
router.navigateTo(.sheet) { router in
    SettingsPage(router: router)
}
```

特点：

- 以系统 sheet 方式展示
- 会自动为新页面创建可继续使用的路由上下文

### FullScreenCover

```swift
router.navigateTo(.fullScreenCover) { router in
    LoginPage(router: router)
}
```

特点：

- 在 iOS 上使用 `fullScreenCover`
- 在当前实现中，macOS 下会自动退化为 `sheet`

这点非常重要：如果你的产品同时支持 iOS 和 macOS，请不要假设两端视觉表现完全一致。

## Alert 与确认框

当前库内部已经具备 alert 与 confirmationDialog 的承载能力，统一由 `showAlert(_:)` 驱动。

使用思路是：

1. 构造一个 `AnyAppAlert`
2. 调用 `router.showAlert(...)`

示例思路：

```swift
router.showAlert(
    AnyAppAlert(
        title: "Delete Item",
        message: "This action cannot be undone."
    )
)
```

确认框的典型意图是：

```swift
router.showAlert(
    AnyAppAlert.confirm(
        title: "Confirm Delete",
        message: "Are you sure?",
        confirmTitle: "Delete"
    ) {
        // do something
    }
)
```

说明：

- 普通提示会走系统 `alert`
- 带确认语义的内容会走 `confirmationDialog`
- 点击按钮时，会先关闭弹窗，再执行按钮动作

注意：

- 按当前源码状态，`AnyAppAlert` 的部分初始化与便捷构造还偏向库内部使用
- 如果你要把它作为对外 SPM 包直接给业务项目依赖，建议先把这些构造器统一补齐 `public`
- 上面的示例主要用于说明推荐使用方式和最终效果

## 自定义 Modal

如果你需要的不是系统 `sheet`，而是带遮罩、自定义动画、自定义内容过渡的模态层，可以使用 `showModal`。

基础示例：

```swift
router.showModal {
    VStack(spacing: 12) {
        Text("Custom Modal")
        Button("Close") {
            router.dismissModal()
        }
    }
    .padding()
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
}
```

带配置示例：

```swift
var config = AppModalConfiguration()
config.tapToDismiss = true
config.maxWidth = 420

router.showModal(configuration: config) {
    YourCustomView()
}
```

当前 `AppModalConfiguration` 负责控制：

- 背景颜色
- 背景透明度
- 点击背景是否关闭
- 背景动画
- 内容动画
- 内容过渡方式
- 最大宽度

注意：

- 按当前源码状态，`AppModalConfiguration` 的具体配置字段访问级别还需要再整理
- 如果你准备正式对外发布，建议把常用配置项补成清晰的 `public` API
- README 中的配置示例表达的是该类型的设计意图

## 关闭页面与返回

当前公开的关闭能力是：

```swift
router.dismissScreen()
```

它会调用 SwiftUI 的 `dismiss()`，适用于：

- 关闭 push 进来的页面
- 关闭 sheet
- 关闭 fullScreenCover

## 一个更完整的示例

```swift
import SwiftUI
import SDRouting

struct DemoRootView: View {
    var body: some View {
        RouterView { router in
            VStack(spacing: 16) {
                Button("Push") {
                    router.navigateTo(.push) { router in
                        ChildView(router: router)
                    }
                }

                Button("Show Alert") {
                    router.showAlert(
                        AnyAppAlert(
                            title: "Hello",
                            message: "This is an alert."
                        )
                    )
                }

                Button("Show Custom Modal") {
                    router.showModal {
                        VStack(spacing: 12) {
                            Text("Custom Modal")
                            Button("Close") {
                                router.dismissModal()
                            }
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
    }
}

struct ChildView: View {
    let router: RouterProtocol

    var body: some View {
        VStack(spacing: 16) {
            Text("Child")

            Button("Open Sheet") {
                router.navigateTo(.sheet) { router in
                    Text("Sheet Page")
                }
            }

            Button("Back") {
                router.dismissScreen()
            }
        }
        .padding()
    }
}
```

## 设计特点

### 1. 跳转入口统一

你不需要在页面里分别维护：

- `NavigationLink`
- `sheet(isPresented:)`
- `fullScreenCover(isPresented:)`
- `alert(isPresented:)`

这些行为都统一通过 `router` 发起。

### 2. 子页面天然继承路由能力

每次通过 `navigateTo` 进入新页面时，内部都会生成新的 `RouterView` 包裹目标页面，因此目标页依旧可以继续：

- push
- 打开 sheet
- 打开 fullScreenCover
- 显示 alert
- 展示自定义 modal

### 3. 适合业务中台式页面组织

如果你的业务页面多、分支多、弹层多，这种“路由对象集中调度”的方式通常比到处散落布尔状态更好维护。

## 注意事项

### 1. 所有路由操作都应当在主线程执行

`RouterProtocol` 当前是 `@MainActor` 协议。

这意味着：

- UI 交互里直接调用是安全的
- 如果你从异步任务或后台线程触发，应该切回主线程上下文

示例：

```swift
Task { @MainActor in
    router.showAlert(
        AnyAppAlert(
            title: "Done",
            message: "Finished on main actor."
        )
    )
}
```

### 2. 当前更适合“页面级容器路由”，不适合 URL Router

这个库现在解决的是 SwiftUI 视图层内部的跳转与弹层管理，不是：

- Deep Link 解析器
- URL 路由表
- Web 风格路径匹配

如果你需要的是应用级 URL 路由，这个库还需要额外抽象。

### 3. `push` 依赖 `NavigationStack`

`RouterView` 会根据当前场景决定是否嵌套导航容器。

一般情况下：

- `.push` 会走当前导航栈
- `.sheet` 和 `.fullScreenCover` 会为新页面提供新的导航容器能力

如果你在外部已经有复杂导航结构，接入前建议先确认页面树层级，避免嵌套策略和你的现有结构冲突。

### 4. macOS 与 iOS 的展示行为并不完全一致

当前实现中：

- iOS 的 `.fullScreenCover` 使用原生 `fullScreenCover`
- macOS 会回退为 `sheet`

如果你依赖“全屏覆盖”的交互语义，需要单独评估 macOS 体验。

### 5. 当前源码仍有一部分 API 的访问级别偏保守

从当前源码状态看，这个包已经具备主要功能，但部分便捷初始化和配置字段还没有完全做成对外公开 API。

这意味着：

- 如果你在包内部开发，使用最自由
- 如果你作为独立 SPM 库给别的 App 直接依赖，可能需要继续补齐若干 `public` 修饰

最常见的是：

- `AnyAppAlert` 的便捷构造能力
- `AppModalConfiguration` 的配置项访问级别

如果你准备正式发布这个库，建议把这部分 API 再统一整理一轮。

### 6. 当前还没有完整的栈控制 API

源码注释里已经说明，后续可能会补：

- pop
- popToRoot
- popLast(_:)

也就是说，当前版本更偏向：

- 前进跳转
- 关闭当前层
- 管理弹层

如果你需要完整导航栈编排，建议继续扩展。

## 适合谁

适合：

- SwiftUI 项目
- 中小型业务路由封装
- 想降低页面状态分散程度的项目

暂时不适合：

- 强依赖 Deep Link / URL Router 的项目
- 强依赖跨平台一致导航语义的复杂桌面端场景
- 已经有完整 coordinator 架构且不想引入第二套路由语义的项目

## 当前项目状态建议

如果你接下来准备继续完善这个库，建议优先做这几件事：

1. 补齐所有对外 API 的 `public` 访问级别。
2. 为 `AnyAppAlert` 和 `AppModalConfiguration` 提供稳定、清晰的公开初始化方式。
3. 补充 README 中每种跳转方式的截图或 GIF。
4. 补齐测试，至少覆盖 `push / sheet / alert / modal` 的基本行为。
5. 增加 `pop`、`popToRoot` 等导航栈能力。

## License

