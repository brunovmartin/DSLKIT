import Foundation

public func logDebug(_ item: Any) {
    #if DEBUG
    Swift.print(item)
    #endif
}
