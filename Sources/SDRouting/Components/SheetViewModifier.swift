import SwiftUI

extension View {
  @MainActor
  func sheetViewModifier(screen: Binding<AnyDestination?>, ownerID: String) -> some View {
    return sheet(item: screen) { showSheet in
      showSheet.destination
        .id(showSheet.id)
        .onAppear {
          SDRoutingDebug.log(
            "sheet.content.appear",
            details: [
              "ownerID": ownerID,
              "screen": debugDescription(for: showSheet),
            ]
          )
        }
        .onDisappear {
          SDRoutingDebug.log(
            "sheet.content.disappear",
            details: [
              "ownerID": ownerID,
              "screen": debugDescription(for: showSheet),
            ]
          )
        }
    }
    .onChange(of: screen.wrappedValue?.id) { _, newValue in
      SDRoutingDebug.log(
        "sheet.presentation.changed",
        details: [
          "ownerID": ownerID,
          "isPresented": String(newValue != nil),
          "screen": debugDescription(for: screen.wrappedValue),
        ]
      )
    }
  }

  @MainActor
  func fullScreenCoverViewModifier(screen: Binding<AnyDestination?>, ownerID: String) -> some View {
    #if os(iOS)
      return fullScreenCover(item: screen) { showFullScreenCover in
        showFullScreenCover.destination
          .id(showFullScreenCover.id)
          .onAppear {
            SDRoutingDebug.log(
              "fullScreen.content.appear",
              details: [
                "ownerID": ownerID,
                "screen": debugDescription(for: showFullScreenCover),
              ]
            )
          }
          .onDisappear {
            SDRoutingDebug.log(
              "fullScreen.content.disappear",
              details: [
                "ownerID": ownerID,
                "screen": debugDescription(for: showFullScreenCover),
              ]
            )
          }
      }
      .onChange(of: screen.wrappedValue?.id) { _, newValue in
        SDRoutingDebug.log(
          "fullScreen.presentation.changed",
          details: [
            "ownerID": ownerID,
            "isPresented": String(newValue != nil),
            "screen": debugDescription(for: screen.wrappedValue),
          ]
        )
      }
    #else
      return sheet(item: screen) { showFullScreenCover in
        showFullScreenCover.destination
          .id(showFullScreenCover.id)
      }
    #endif
  }
}
