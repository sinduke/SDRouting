import Foundation

public enum SDRoutingDebug {
  @MainActor
  public static var isEnabled = false

  @MainActor
  public static var printer: @Sendable (String) -> Void = { message in
    print(message)
  }

  @MainActor
  static func log(
    _ event: String,
    details: [String: String] = [:],
    function: String = #function
  ) {
    guard isEnabled else { return }

    let timestamp = ISO8601DateFormatter().string(from: Date())
    let metadata =
      details
      .sorted { $0.key < $1.key }
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: " ")

    if metadata.isEmpty {
      printer("[SDRouting][\(timestamp)][\(event)] \(function)")
    } else {
      printer("[SDRouting][\(timestamp)][\(event)] \(function) \(metadata)")
    }
  }
}

func debugDescription(for destination: AnyDestination?) -> String {
  guard let destination else { return "nil" }
  let segue = destination.sourceSegue?.description ?? "modal"
  return "\(destination.debugLabel)#\(destination.id.uuidString.prefix(8))<\(segue)>"
}
