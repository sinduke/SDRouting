import SwiftUI

public struct AnyAppAlert: Identifiable {
  public enum Style { case alert, confirm }

  public struct AppButton: Identifiable {
    public let id = UUID()
    public var title: String
    public var role: ButtonRole?
    public var action: (() -> Void)?

    public static func ok(_ title: String = "OK", action: (() -> Void)? = nil) -> Self {
      .init(title: title, role: .cancel, action: action)
    }

    public static func cancel(_ title: String = "Cancel", action: (() -> Void)? = nil) -> Self {
      .init(title: title, role: .cancel, action: action)
    }

    public static func destructive(_ title: String, action: (() -> Void)? = nil) -> Self {
      .init(title: title, role: .destructive, action: action)
    }
  }

  public let id = UUID()
  public var style: Style = .alert
  public var title: String
  public var message: String
  public var buttons: [AppButton] = []

  public init(style: Style = .alert, title: String, message: String, buttons: [AppButton] = []) {
    self.style = style
    self.title = title
    self.message = message
    self.buttons = buttons.isEmpty ? [.ok()] : buttons
  }

  public init(error: Error) {
    self.init(style: .alert, title: "Error", message: error.localizedDescription, buttons: [.ok()])
  }

  public static func ok(title: String = "Alert", message: String) -> AnyAppAlert {
    .init(style: .alert, title: title, message: message, buttons: [.ok()])
  }

  public static func confirm(
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
