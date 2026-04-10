import SwiftUI

@MainActor
final class RouterPresentationCoordinator: ObservableObject {
  let id = UUID()

  @Published var path: [AnyDestination] = []
  @Published var sheet: AnyDestination?
  @Published var fullScreenCover: AnyDestination?
  @Published var alert: AnyAppAlert?
  @Published var modal: AnyDestination?
  @Published var modalConfiguration: AppModalConfiguration = .default

  init() {}
}
