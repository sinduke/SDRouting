import SwiftUI

public struct RouterView<Content: View>: View, RouterProtocol {
  @Environment(\.dismiss) private var dismiss
  @State private var routerID = UUID()
  @State private var localPath: [AnyDestination] = []
  @State private var localSheet: AnyDestination? = nil
  @State private var localFullScreenCover: AnyDestination? = nil
  @State private var localAlert: AnyAppAlert?
  @State private var localModal: AnyDestination?
  @State private var localModalConfiguration: AppModalConfiguration = .default

  private let externalPath: Binding<[AnyDestination]>?
  private let externalSheet: Binding<AnyDestination?>?
  private let externalFullScreenCover: Binding<AnyDestination?>?
  private let externalAlert: Binding<AnyAppAlert?>?
  private let externalModal: Binding<AnyDestination?>?
  private let externalModalConfiguration: Binding<AppModalConfiguration>?

  var addNavigationView: Bool
  @ViewBuilder let content: (RouterProtocol) -> Content

  public init(
    addNavigationView: Bool = true,
    path: Binding<[AnyDestination]>? = nil,
    sheet: Binding<AnyDestination?>? = nil,
    fullScreenCover: Binding<AnyDestination?>? = nil,
    alert: Binding<AnyAppAlert?>? = nil,
    modal: Binding<AnyDestination?>? = nil,
    modalConfiguration: Binding<AppModalConfiguration>? = nil,
    @ViewBuilder content: @escaping (RouterProtocol) -> Content
  ) {
    self.addNavigationView = addNavigationView
    self.externalPath = path
    self.externalSheet = sheet
    self.externalFullScreenCover = fullScreenCover
    self.externalAlert = alert
    self.externalModal = modal
    self.externalModalConfiguration = modalConfiguration
    self.content = content
  }

  public var body: some View {
    NavigationStackIfNeeded(path: pathBinding, addNavigationView: addNavigationView, ownerID: routerID.uuidString) {
      content(self)
        .sheetViewModifier(screen: sheetBinding, ownerID: routerID.uuidString)
        .fullScreenCoverViewModifier(screen: fullScreenCoverBinding, ownerID: routerID.uuidString)
        .showCustomAlert(alertBinding)
    }
    .modalViewModifier(
      screen: modalBinding,
      configuration: modalConfigurationBinding.wrappedValue,
      ownerID: routerID.uuidString
    )
    .environment(\.router, self)
    .onAppear {
      logState("router.appear")
    }
    .onDisappear {
      logState("router.disappear")
    }
    .onChange(of: pathBinding.wrappedValue) { _, _ in
      logState("path.changed")
    }
    .onChange(of: sheetBinding.wrappedValue) { _, newValue in
      logState(
        "sheet.state.changed",
        extra: ["sheet": debugValue(for: newValue)]
      )
    }
    .onChange(of: fullScreenCoverBinding.wrappedValue) { _, newValue in
      logState(
        "fullScreen.state.changed",
        extra: ["fullScreen": debugValue(for: newValue)]
      )
    }
    .onChange(of: modalBinding.wrappedValue) { _, newValue in
      logState(
        "modal.state.changed",
        extra: ["modal": debugValue(for: newValue)]
      )
    }
    .onChange(of: alertBinding.wrappedValue?.id) { _, newValue in
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

    let sharesPresentationHost = segue == .push
    let destinationView = RouterView<T>(
      addNavigationView: segue.addNavigationView,
      path: sharesPresentationHost ? pathBinding : nil,
      sheet: sharesPresentationHost ? sheetBinding : nil,
      fullScreenCover: sharesPresentationHost ? fullScreenCoverBinding : nil,
      alert: sharesPresentationHost ? alertBinding : nil,
      modal: sharesPresentationHost ? modalBinding : nil,
      modalConfiguration: sharesPresentationHost ? modalConfigurationBinding : nil,
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
      pathBinding.wrappedValue.append(anyDestination)
    case .sheet:
      sheetBinding.wrappedValue = anyDestination
    case .fullScreenCover:
      fullScreenCoverBinding.wrappedValue = anyDestination
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
    alertBinding.wrappedValue = alert
    logState("alert.show", extra: ["title": alert.title])
  }

  public func dismissAlert() {
    alertBinding.wrappedValue = nil
    logState("alert.dismiss")
  }

  public func showModal<T: View>(
    configuration: AppModalConfiguration,
    @ViewBuilder content: @escaping () -> T
  ) {
    modalConfigurationBinding.wrappedValue = configuration
    withAnimation(configuration.contentAnimation) {
      modalBinding.wrappedValue = AnyDestination(
        destination: content(),
        debugLabel: String(describing: T.self)
      )
    }
    logState("modal.show", extra: ["modal": debugValue(for: modalBinding.wrappedValue)])
  }

  public func dismissModal() {
    withAnimation(modalConfigurationBinding.wrappedValue.contentAnimation) {
      modalBinding.wrappedValue = nil
    }
    logState("modal.dismiss")
  }
}

private extension RouterView {
  var pathBinding: Binding<[AnyDestination]> {
    externalPath ?? $localPath
  }

  var sheetBinding: Binding<AnyDestination?> {
    externalSheet ?? $localSheet
  }

  var fullScreenCoverBinding: Binding<AnyDestination?> {
    externalFullScreenCover ?? $localFullScreenCover
  }

  var alertBinding: Binding<AnyAppAlert?> {
    externalAlert ?? $localAlert
  }

  var modalBinding: Binding<AnyDestination?> {
    externalModal ?? $localModal
  }

  var modalConfigurationBinding: Binding<AppModalConfiguration> {
    externalModalConfiguration ?? $localModalConfiguration
  }

  func logState(_ event: String, extra: [String: String] = [:]) {
    var details = [
      "routerID": routerID.uuidString,
      "addNavigationView": addNavigationView.description,
      "usesExternalHost": String(externalSheet != nil),
      "path": debugPath(pathBinding.wrappedValue),
      "pathCount": String(pathBinding.wrappedValue.count),
      "localPath": debugPath(localPath),
      "localPathCount": String(localPath.count),
      "sheet": debugValue(for: sheetBinding.wrappedValue),
      "fullScreen": debugValue(for: fullScreenCoverBinding.wrappedValue),
      "modal": debugValue(for: modalBinding.wrappedValue),
      "alertTitle": alertBinding.wrappedValue?.title ?? "nil",
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
