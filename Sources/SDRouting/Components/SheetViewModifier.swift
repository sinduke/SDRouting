import SwiftUI

extension View {
  @MainActor
  func sheetViewModifier(screen: Binding<AnyDestination?>, ownerID: String) -> some View {
    let isPresented = Binding<Bool>(
      get: { screen.wrappedValue != nil },
      set: { newValue in
        if !newValue {
          screen.wrappedValue = nil
        }
      }
    )

    return sheet(isPresented: isPresented) {
      ZStack {
        if let showSheet = screen.wrappedValue {
          showSheet.destination
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
      }
    }
    .onChange(of: isPresented.wrappedValue) { _, newValue in
      SDRoutingDebug.log(
        "sheet.presentation.changed",
        details: [
          "ownerID": ownerID,
          "isPresented": String(newValue),
          "screen": debugDescription(for: screen.wrappedValue),
        ]
      )
    }
  }

  @MainActor
  func fullScreenCoverViewModifier(screen: Binding<AnyDestination?>, ownerID: String) -> some View {
    let isPresented = Binding<Bool>(
      get: { screen.wrappedValue != nil },
      set: { newValue in
        if !newValue {
          screen.wrappedValue = nil
        }
      }
    )

    #if os(iOS)
      return fullScreenCover(isPresented: isPresented) {
        ZStack {
          if let showFullScreenCover = screen.wrappedValue {
            showFullScreenCover.destination
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
        }
      }
      .onChange(of: isPresented.wrappedValue) { _, newValue in
        SDRoutingDebug.log(
          "fullScreen.presentation.changed",
          details: [
            "ownerID": ownerID,
            "isPresented": String(newValue),
            "screen": debugDescription(for: screen.wrappedValue),
          ]
        )
      }
    #else
      return sheet(isPresented: isPresented) {
        ZStack {
          if let showFullScreenCover = screen.wrappedValue {
            showFullScreenCover.destination
          }
        }
      }
    #endif
  }
}
