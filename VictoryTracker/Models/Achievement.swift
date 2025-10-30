import Foundation

struct Achievement: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String
    var isUnlocked: Bool
}



