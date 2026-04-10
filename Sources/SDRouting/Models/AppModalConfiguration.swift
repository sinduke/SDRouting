import SwiftUI

public struct AppModalConfiguration {
  var backgroundColor: Color = .black
  var backgroundOpacity: CGFloat = 0.40
  var tapToDismiss: Bool = true
  var backgroundAnimation: Animation = .easeOut(duration: 0.20)
  var contentAnimation: Animation = .bouncy(duration: 0.45, extraBounce: 0.10)
  var contentTransition: AnyTransition = .slide
  var maxWidth: CGFloat = 520

    @MainActor static let `default` = Self()
}
