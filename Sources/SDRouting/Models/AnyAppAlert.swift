import SwiftUI

public struct AnyAppAlert: Identifiable {
  enum Style { case alert, confirm }

  struct AppButton: Identifiable {
    let id = UUID()
    var title: String
    var role: ButtonRole?
      var action: (() -> Void)?

    static func ok(_ title: String = "OK", action: (() -> Void)? = nil) -> Self {
      .init(title: title, role: .cancel, action: action)
    }

    static func cancel(_ title: String = "Cancel", action: (() -> Void)? = nil) -> Self {
      .init(title: title, role: .cancel, action: action)
    }

    static func destructive(_ title: String, action: (() -> Void)? = nil) -> Self {
      .init(title: title, role: .destructive, action: action)
    }
  }

  public let id = UUID()
  var style: Style = .alert
  var title: String
  var message: String
  var buttons: [AppButton] = []

  init(style: Style = .alert, title: String, message: String, buttons: [AppButton] = []) {
    self.style = style
    self.title = title
    self.message = message
    self.buttons = buttons.isEmpty ? [.ok()] : buttons
  }

  init(error: Error) {
    self.init(style: .alert, title: "Error", message: error.localizedDescription, buttons: [.ok()])
  }

  static func ok(title: String = "Alert", message: String) -> AnyAppAlert {
    .init(style: .alert, title: title, message: message, buttons: [.ok()])
  }

  static func confirm(
    title: String = "Confirm",
    message: String,
    confirmTitle: String = "OK",
    confirmRole: ButtonRole? = .destructive,
    onConfirm: @escaping () -> Void
  ) -> AnyAppAlert {
    .init(
      style: .confirm,
      title: title,
      message: message,
      buttons: [
        .init(title: "Cancel", role: .cancel, action: nil),
        .init(title: confirmTitle, role: confirmRole, action: onConfirm),
      ]
    )
  }
}
