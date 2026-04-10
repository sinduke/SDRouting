import SwiftUI

// Alert & Confirm
extension View {
  @MainActor
  func showCustomAlert(_ alert: Binding<AnyAppAlert?>) -> some View {
    let isAlertPresented = Binding<Bool>(
      get: { alert.wrappedValue?.style == .alert },
      set: { newValue in
        if !newValue {
          alert.wrappedValue = nil
        }
      }
    )
    let isConfirmPresented = Binding<Bool>(
      get: { alert.wrappedValue?.style == .confirm },
      set: { newValue in
        if !newValue {
          alert.wrappedValue = nil
        }
      }
    )

    return
      self
      .alert(alert.wrappedValue?.title ?? "", isPresented: isAlertPresented) {
        if let cusAlert = alert.wrappedValue {
          ForEach(cusAlert.buttons) { btn in
            Button(btn.title, role: btn.role) {
              // 先关弹窗，再执行 action（体验更像系统）
              alert.wrappedValue = nil
              btn.action?()
            }
          }
        }
      } message: {
        if let msg = alert.wrappedValue?.message {
          Text(msg)
        }
      }
      .confirmationDialog(alert.wrappedValue?.title ?? "", isPresented: isConfirmPresented) {
        if let cusAlert = alert.wrappedValue {
          ForEach(cusAlert.buttons) { btn in
            Button(btn.title, role: btn.role) {
              alert.wrappedValue = nil
              btn.action?()
            }
          }
        }
      } message: {
        if let msg = alert.wrappedValue?.message {
          Text(msg)
        }
      }
  }
}
