import SwiftUI

@MainActor
public final class RouterPresentationCoordinator: ObservableObject {
  public let id = UUID()

  @Published public var path: [AnyDestination] = []
  @Published public var sheet: AnyDestination?
  @Published public var fullScreenCover: AnyDestination?
  @Published public var alert: AnyAppAlert?
  @Published public var modal: AnyDestination?
  @Published public var modalConfiguration: AppModalConfiguration = .default

  public init() {}
}
