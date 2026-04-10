import SwiftUI

public struct RouterView<Content: View>: View, RouterProtocol {
  @Environment(\.dismiss) private var dismiss
  @State private var routerID = UUID()
  @State private var path: [AnyDestination] = []
  @State private var showSheet: AnyDestination? = nil
  @State private var showFullScreenCover: AnyDestination? = nil
  @State private var alert: AnyAppAlert?
  @State private var modal: AnyDestination?
  @State private var modalConfiguration: AppModalConfiguration = .default
  // 从上一视图绑定到堆栈视图
  @Binding var screenStack: [AnyDestination]
  var addNavigationView: Bool
  @ViewBuilder let content: (RouterProtocol) -> Content

   public init(
    addNavigationView: Bool = true,
    screenStack: (Binding<[AnyDestination]>)? = nil,
    @ViewBuilder content: @escaping (RouterProtocol) -> Content
  ) {
    self.addNavigationView = addNavigationView
    self._screenStack = screenStack ?? .constant([])
    self.content = content
  }

  public var body: some View {
    /// 如果 screenStack 绑定了外部状态，则使用它，否则使用内部 path 状态
    /// 如果content有单独的modifier 也不需要写两次
    NavigationStackIfNeeded(path: $path, addNavigationView: addNavigationView, ownerID: routerID.uuidString) {
      content(self)
        .sheetViewModifier(screen: $showSheet, ownerID: routerID.uuidString)
        .fullScreenCoverViewModifier(screen: $showFullScreenCover, ownerID: routerID.uuidString)
        .showCustomAlert($alert)
    }
    .modalViewModifier(screen: $modal, configuration: modalConfiguration, ownerID: routerID.uuidString)
    .environment(\.router, self)
    .onAppear {
      logState("router.appear")
    }
    .onDisappear {
      logState("router.disappear")
    }
    .onChange(of: path) { _, _ in
      logState("path.changed")
    }
    .onChange(of: screenStack) { _, _ in
      logState("screenStack.changed")
    }
    .onChange(of: showSheet) { _, newValue in
      logState(
        "sheet.state.changed",
        extra: ["sheet": debugValue(for: newValue)]
      )
    }
    .onChange(of: showFullScreenCover) { _, newValue in
      logState(
        "fullScreen.state.changed",
        extra: ["fullScreen": debugValue(for: newValue)]
      )
    }
    .onChange(of: modal) { _, newValue in
      logState(
        "modal.state.changed",
        extra: ["modal": debugValue(for: newValue)]
      )
    }
    .onChange(of: alert?.id) { _, newValue in
      logState(
        "alert.state.changed",
        extra: ["alert": newValue?.uuidString ?? "nil"]
      )
    }
  }

   public func navigateTo<T: View>(
    _ segue: SegueType,
    @ViewBuilder destination: @escaping (RouterProtocol) -> T
  ) {
    logState("navigate.begin", extra: ["segue": segue.description])

    let destinationView = RouterView<T>(
      addNavigationView: segue.addNavigationView,
      screenStack: segue.addNavigationView ? nil : (screenStack.isEmpty ? $path : $screenStack),
    ) { newRouter in
      destination(newRouter)
    }
    let anyDestination = AnyDestination(
      destination: destinationView,
      debugLabel: String(describing: T.self),
      sourceSegue: segue
    )
    switch segue {
    case .push:
      if screenStack.isEmpty {
        path.append(anyDestination)
      } else {
        screenStack.append(anyDestination)
      }
    case .sheet:
      showSheet = anyDestination
    case .fullScreenCover:
      showFullScreenCover = anyDestination
    }

    logState(
      "navigate.end",
      extra: [
        "segue": segue.description,
        "target": debugDescription(for: anyDestination),
      ]
    )
  }

  // 后续在写 pop/popToRoot/popLast(3) 等功能
  public func dismissScreen() {
    logState("dismiss.requested")
    dismiss()
  }

  public func showAlert(_ alert: AnyAppAlert) {
    self.alert = alert
    logState("alert.show", extra: ["title": alert.title])
  }

  public func dismissAlert() {
    self.alert = nil
    logState("alert.dismiss")
  }

  public func showModal<T: View>(
    configuration: AppModalConfiguration,
    @ViewBuilder content: @escaping () -> T
  ) {
    modalConfiguration = configuration
    withAnimation(configuration.contentAnimation) {
      self.modal = AnyDestination(
        destination: content(),
        debugLabel: String(describing: T.self)
      )
    }
    logState("modal.show", extra: ["modal": debugValue(for: modal)])
  }

  public func dismissModal() {
    withAnimation(modalConfiguration.contentAnimation) {
      self.modal = nil
    }
    logState("modal.dismiss")
  }
}

private extension RouterView {
  func logState(_ event: String, extra: [String: String] = [:]) {
    var details = [
      "routerID": routerID.uuidString,
      "addNavigationView": addNavigationView.description,
      "path": debugPath(path),
      "pathCount": String(path.count),
      "screenStack": debugPath(screenStack),
      "screenStackCount": String(screenStack.count),
      "sheet": debugValue(for: showSheet),
      "fullScreen": debugValue(for: showFullScreenCover),
      "modal": debugValue(for: modal),
      "alertTitle": alert?.title ?? "nil",
    ]

    for (key, value) in extra {
      details[key] = value
    }

    SDRoutingDebug.log(event, details: details)
  }

  func debugPath(_ destinations: [AnyDestination]) -> String {
    if destinations.isEmpty { return "[]" }
    return "[" + destinations.map { debugDescription(for: $0) }.joined(separator: ",") + "]"
  }

  func debugValue(for destination: AnyDestination?) -> String {
    debugDescription(for: destination)
  }
}
