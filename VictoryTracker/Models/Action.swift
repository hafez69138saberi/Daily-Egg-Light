import Foundation

struct Action: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var categoryId: UUID

    init(id: UUID = UUID(), title: String, categoryId: UUID) {
        self.id = id
        self.title = title
        self.categoryId = categoryId
    }
}


