import SwiftUI

extension View {
  func any() -> AnyView {
    AnyView(self)
  }
}

extension View {
  @ViewBuilder
  func ifStatement<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
