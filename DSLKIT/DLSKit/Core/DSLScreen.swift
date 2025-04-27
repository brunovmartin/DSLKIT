import Foundation

struct DSLScreen: Identifiable, Codable, Hashable {
    let id: String
    let navigationBar: NavigationBarConfig?
    let components: [[String: AnyCodable]]
    let onAppearLogic: [String: AnyCodable]?
}

struct NavigationBarConfig: Codable, Hashable {
    let title: String?
    let displayMode: String?
    let trailingButton: NavigationBarButton?
}

struct NavigationBarButton: Codable, Hashable {
    let label: String
    let action: [String: AnyCodable]?
}
