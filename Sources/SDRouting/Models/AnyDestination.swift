import SwiftUI

public struct AnyDestination: Hashable, Identifiable {
  public let id: UUID
  public let destination: AnyView
  public let debugLabel: String
  public let sourceSegue: SegueType?

  public init<T: View>(
    id: UUID = UUID(),
    destination: T,
    debugLabel: String? = nil,
    sourceSegue: SegueType? = nil
  ) {
    self.id = id
    self.destination = AnyView(destination)
    self.debugLabel = debugLabel ?? String(describing: T.self)
    self.sourceSegue = sourceSegue
  }

  public static func == (lhs: AnyDestination, rhs: AnyDestination) -> Bool {
    return lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
