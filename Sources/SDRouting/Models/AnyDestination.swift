import SwiftUI

public struct AnyDestination: Hashable {
  public let id = UUID()
  public let destination: AnyView

  public init<T: View>(destination: T) {
    self.destination = AnyView(destination)
  }

  public static func == (lhs: AnyDestination, rhs: AnyDestination) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
