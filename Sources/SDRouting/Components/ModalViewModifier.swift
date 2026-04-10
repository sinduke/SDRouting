import SwiftUI

struct ModalSupportView<ModalContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let configuration: AppModalConfiguration

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
          .transition(configuration.contentTransition)
          .zIndex(3)
      }
    }
  }
}

extension View {
  @MainActor
  func modalViewModifier(
    screen: Binding<AnyDestination?>,
    configuration: AppModalConfiguration = .default
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
    @ViewBuilder content: @escaping () -> Modal
  ) -> some View {
    modifier(
      ModalSupportView(
        isPresented: isPresented,
        configuration: configuration,
        modal: content
      )
    )
  }
}
