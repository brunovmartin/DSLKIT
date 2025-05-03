import Foundation

public func logDebug(_ item: Any) {
    #if DEBUG
    if let stringItem = item as? String, stringItem.contains("CURRENT_PRINT") {
        Swift.print(item)
    }
    #endif
}
