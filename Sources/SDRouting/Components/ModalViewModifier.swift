import SwiftUI

struct ModalSupportView<ModalContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let configuration: AppModalConfiguration
  let ownerID: String?

  @ViewBuilder let modal: () -> ModalContent

  func body(content: Content) -> some View {
    ZStack {
      content
        .zIndex(1)

      if isPresented {
        configuration.backgroundColor
          .opacity(configuration.backgroundOpacity)
          .ignoresSafeArea()
          .animation(configuration.backgroundAnimation, value: isPresented)
          .ifStatement(configuration.tapToDismiss) { view in
            view.onTapGesture {
              withAnimation(configuration.contentAnimation) { isPresented = false }
            }
          }
          .transition(.opacity)
          .zIndex(2)

        modal()
          .frame(maxWidth: configuration.maxWidth)
          .padding(.horizontal, 24)
          .padding(.bottom, 24)
          .onAppear {
            SDRoutingDebug.log(
              "modal.content.appear",
              details: [
                "ownerID": ownerID ?? "nil",
                "isPresented": String(isPresented),
              ]
            )
          }
          .onDisappear {
            SDRoutingDebug.log(
              "modal.content.disappear",
              details: [
                "ownerID": ownerID ?? "nil",
                "isPresented": String(isPresented),
              ]
            )
          }
          .transition(configuration.contentTransition)
          .zIndex(3)
      }
    }
    .onChange(of: isPresented) { _, newValue in
      SDRoutingDebug.log(
        "modal.presentation.changed",
        details: [
          "ownerID": ownerID ?? "nil",
          "isPresented": String(newValue),
        ]
      )
    }
  }
}

extension View {
  @MainActor
  func modalViewModifier(
    screen: Binding<AnyDestination?>,
    configuration: AppModalConfiguration = .default,
    ownerID: String? = nil
  ) -> some View {
    let isPresented = Binding<Bool>(
      get: { screen.wrappedValue != nil },
      set: { newValue in
        if !newValue {
          screen.wrappedValue = nil
        }
      }
    )

    return self.appModal(
      isPresented: isPresented,
      configuration: configuration,
      ownerID: ownerID,
      content: {
        ZStack {
          if let destination = screen.wrappedValue {
            destination.destination
          }
        }
      })
  }

  func appModal<Modal: View>(
    isPresented: Binding<Bool>,
    configuration: AppModalConfiguration = .default,
    ownerID: String? = nil,
    @ViewBuilder content: @escaping () -> Modal
  ) -> some View {
    modifier(
      ModalSupportView(
        isPresented: isPresented,
        configuration: configuration,
        ownerID: ownerID,
        modal: content
      )
    )
  }
}
