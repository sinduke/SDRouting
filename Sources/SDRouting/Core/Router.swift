import SwiftUI

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

public extension RouterProtocol {
    @MainActor
  func showModal<T: View>(
    configuration: AppModalConfiguration = .default,
    @ViewBuilder content: @escaping () -> T
  ) {
    showModal(configuration: configuration, content: content)
  }
}

 public extension EnvironmentValues {
  @Entry var router: RouterProtocol = MockRouter()
}

struct MockRouter: RouterProtocol {
  func navigateTo<T: View>(
    _ segue: SegueType, @ViewBuilder destination: @escaping (RouterProtocol) -> T
  ) {
    // Mock implementation for testing
    print("Navigating to new screen")
  }

  func dismissScreen() {
    // Mock implementation for testing
    print("Dismissing current screen")
  }

  func showAlert(_ alert: AnyAppAlert) {
    // Mock implementation for testing
    print("Showing alert: \(alert.title)")
  }

  func dismissAlert() {

  }

  func showModal<T: View>(
    configuration: AppModalConfiguration,
    @ViewBuilder content: @escaping () -> T
  ) {
    print("Showing modal")
  }

  func dismissModal() {
    print("Dismissing modal")
  }
}
