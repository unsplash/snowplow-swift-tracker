import Foundation

public enum LogCategory: CaseIterable, Sendable {
  case emitter
  case session
  case tracker
}

final class LogConfiguration: @unchecked Sendable {
  @Locked private var categories: [LogCategory] = LogCategory.allCases
  
  var enabledCategories: [LogCategory] {
    get { categories }
    set { categories = newValue }
  }
  
  func isEnabled(_ category: LogCategory) -> Bool {
    categories.contains(category)
  }
}
