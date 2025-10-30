import Foundation

struct Category: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var colorHex: String

    init(id: UUID = UUID(), title: String, colorHex: String) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
    }
}



