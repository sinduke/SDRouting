import SwiftUI

extension View {
  @MainActor
  func sheetViewModifier(screen: Binding<AnyDestination?>) -> some View {
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
        }
      }
    }
  }

  @MainActor
  func fullScreenCoverViewModifier(screen: Binding<AnyDestination?>) -> some View {
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
          }
        }
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
