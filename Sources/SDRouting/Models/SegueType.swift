import SwiftUI

 public enum SegueType {
  case push, sheet, fullScreenCover

  var addNavigationView: Bool {
    switch self {
    case .push:
      return false
    case .sheet, .fullScreenCover:
      return true
    }
  }
}
