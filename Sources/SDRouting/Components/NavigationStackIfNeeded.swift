import SwiftUI

struct NavigationStackIfNeeded<Content: View>: View {
  @Binding var path: [AnyDestination]
  var addNavigationView: Bool
  var ownerID: String?
  @ViewBuilder let content: Content

  var body: some View {
    if addNavigationView {
      NavigationStack(path: $path) {
        content
          .navigationDestination(
            for: AnyDestination.self,
            destination: { destination in
              let presentedDestination = destination.destination
              let details = [
                "ownerID": ownerID ?? "nil",
                "destination": debugDescription(for: destination),
                "pathCount": String(path.count),
              ]

              return presentedDestination
                .onAppear {
                  SDRoutingDebug.log("navigationDestination.appear", details: details)
                }
                .onDisappear {
                  SDRoutingDebug.log("navigationDestination.disappear", details: details)
                }
            })
          .onAppear {
            SDRoutingDebug.log(
              "navigationStack.appear",
              details: [
                "ownerID": ownerID ?? "nil",
                "pathCount": String(path.count),
              ]
            )
          }
          .onChange(of: path) { _, newValue in
            SDRoutingDebug.log(
              "navigationStack.path.changed",
              details: [
                "ownerID": ownerID ?? "nil",
                "path": debugPath(newValue),
                "pathCount": String(newValue.count),
              ]
            )
          }
      }
    } else {
      content
    }
  }
}

private func debugPath(_ destinations: [AnyDestination]) -> String {
  if destinations.isEmpty { return "[]" }
  return "[" + destinations.map { debugDescription(for: $0) }.joined(separator: ",") + "]"
}
