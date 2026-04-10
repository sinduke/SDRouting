import SwiftUI

struct NavigationStackIfNeeded<Content: View>: View {
  @Binding var path: [AnyDestination]
  var addNavigationView: Bool
  @ViewBuilder let content: Content

  var body: some View {
    if addNavigationView {
      NavigationStack(path: $path) {
        content
          .navigationDestination(
            for: AnyDestination.self,
            destination: { $0.destination })
      }
    } else {
      content
    }
  }
}
