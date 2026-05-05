import Foundation

public enum LogCategory: CaseIterable, Sendable {
  case emitter
  case session
  case tracker
}

internal final class LogConfiguration: @unchecked Sendable {
  @Locked private var categories: [LogCategory] = LogCategory.allCases
  
  internal var enabledCategories: [LogCategory] {
    get { categories }
    set { categories = newValue }
  }
  
  internal func isEnabled(_ category: LogCategory) -> Bool {
    categories.contains(category)
  }
}
