import Foundation

struct Victory: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var minutes: Int
    var categoryId: UUID
    var actionId: UUID

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        minutes: Int,
        categoryId: UUID,
        actionId: UUID
    ) {
        self.id = id
        self.date = date
        self.minutes = minutes
        self.categoryId = categoryId
        self.actionId = actionId
    }
}



