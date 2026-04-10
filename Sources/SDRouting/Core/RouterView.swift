import SwiftUI

public struct RouterView<Content: View>: View, RouterProtocol {
  @Environment(\.dismiss) private var dismiss
  @State private var routerID = UUID()
  @StateObject private var coordinator: RouterPresentationCoordinator

  var addNavigationView: Bool
  private let hostsPresentation: Bool
  @ViewBuilder let content: (RouterProtocol) -> Content

  public init(
    addNavigationView: Bool = true,
    @ViewBuilder content: @escaping (RouterProtocol) -> Content
  ) {
    self.init(
      addNavigationView: addNavigationView,
      hostsPresentation: true,
      presentationCoordinator: RouterPresentationCoordinator(),
      content: content
    )
  }

  init(
    addNavigationView: Bool,
    hostsPresentation: Bool,
    presentationCoordinator: RouterPresentationCoordinator,
    @ViewBuilder content: @escaping (RouterProtocol) -> Content
  ) {
    self.addNavigationView = addNavigationView
    self.hostsPresentation = hostsPresentation
    self._coordinator = StateObject(wrappedValue: presentationCoordinator)
    self.content = content
  }

  public var body: some View {
    let routerContent = NavigationStackIfNeeded(
      path: binding(\.path),
      addNavigationView: addNavigationView,
      ownerID: routerID.uuidString
    ) {
      content(self)
    }

    Group {
      if hostsPresentation {
        routerContent
          .sheetViewModifier(screen: binding(\.sheet), ownerID: routerID.uuidString)
          .fullScreenCoverViewModifier(
            screen: binding(\.fullScreenCover),
            ownerID: routerID.uuidString
          )
          .showCustomAlert(binding(\.alert))
          .modalViewModifier(
            screen: binding(\.modal),
            configuration: coordinator.modalConfiguration,
            ownerID: routerID.uuidString
          )
      } else {
        routerContent
      }
    }
    .environment(\.router, self)
    .onAppear {
      logState("router.appear")
    }
    .onDisappear {
      logState("router.disappear")
    }
    .onChange(of: coordinator.path) { _, _ in
      logState("path.changed")
    }
    .onChange(of: coordinator.sheet) { _, newValue in
      logState("sheet.state.changed", extra: ["sheet": debugValue(for: newValue)])
    }
    .onChange(of: coordinator.fullScreenCover) { _, newValue in
      logState("fullScreen.state.changed", extra: ["fullScreen": debugValue(for: newValue)])
    }
    .onChange(of: coordinator.modal) { _, newValue in
      logState("modal.state.changed", extra: ["modal": debugValue(for: newValue)])
    }
    .onChange(of: coordinator.alert?.id) { _, newValue in
      logState("alert.state.changed", extra: ["alert": newValue?.uuidString ?? "nil"])
    }
  }

  public func navigateTo<T: View>(
    _ segue: SegueType,
    @ViewBuilder destination: @escaping (RouterProtocol) -> T
  ) {
    logState("navigate.begin", extra: ["segue": segue.description])

    let destinationCoordinator =
      segue == .push ? coordinator : RouterPresentationCoordinator()

    let destinationView = RouterView<T>(
      addNavigationView: segue.addNavigationView,
      hostsPresentation: segue != .push,
      presentationCoordinator: destinationCoordinator
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
      coordinator.path.append(anyDestination)
    case .sheet:
      coordinator.sheet = anyDestination
    case .fullScreenCover:
      coordinator.fullScreenCover = anyDestination
    }

    logState(
      "navigate.end",
      extra: [
        "segue": segue.description,
        "target": debugDescription(for: anyDestination),
      ]
    )
  }

  public func dismissScreen() {
    logState("dismiss.requested")
    dismiss()
  }

  public func showAlert(_ alert: AnyAppAlert) {
    coordinator.alert = alert
    logState("alert.show", extra: ["title": alert.title])
  }

  public func dismissAlert() {
    coordinator.alert = nil
    logState("alert.dismiss")
  }

  public func showModal<T: View>(
    configuration: AppModalConfiguration,
    @ViewBuilder content: @escaping () -> T
  ) {
    coordinator.modalConfiguration = configuration
    withAnimation(configuration.contentAnimation) {
      coordinator.modal = AnyDestination(
        destination: content(),
        debugLabel: String(describing: T.self)
      )
    }
    logState("modal.show", extra: ["modal": debugValue(for: coordinator.modal)])
  }

  public func dismissModal() {
    withAnimation(coordinator.modalConfiguration.contentAnimation) {
      coordinator.modal = nil
    }
    logState("modal.dismiss")
  }
}

private extension RouterView {
  func binding<Value>(
    _ keyPath: ReferenceWritableKeyPath<RouterPresentationCoordinator, Value>
  ) -> Binding<Value> {
    Binding(
      get: { coordinator[keyPath: keyPath] },
      set: { coordinator[keyPath: keyPath] = $0 }
    )
  }

  func logState(_ event: String, extra: [String: String] = [:]) {
    var details = [
      "routerID": routerID.uuidString,
      "coordinatorID": coordinator.id.uuidString,
      "addNavigationView": addNavigationView.description,
      "hostsPresentation": String(hostsPresentation),
      "path": debugPath(coordinator.path),
      "pathCount": String(coordinator.path.count),
      "sheet": debugValue(for: coordinator.sheet),
      "fullScreen": debugValue(for: coordinator.fullScreenCover),
      "modal": debugValue(for: coordinator.modal),
      "alertTitle": coordinator.alert?.title ?? "nil",
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
