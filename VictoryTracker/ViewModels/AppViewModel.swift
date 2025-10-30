import Foundation
import Combine
import UserNotifications

final class AppViewModel: ObservableObject {
    @Published var categories: [Category] = [] { didSet { saveCategories(); updateAchievements() } }
    @Published var actions: [Action] = [] { didSet { saveActions() } }
    @Published var victories: [Victory] = [] { didSet { saveVictories(); updateAchievements() } }
    @Published var achievements: [Achievement] = [] { didSet { saveAchievements() } }
    @Published var toastMessage: String? = nil

    private let storage: UserDefaultsStorage

    init(storage: UserDefaultsStorage = .shared) {
        self.storage = storage
        loadAll()
        ensureInitialAchievements()
        updateAchievements()
    }

    func loadAll() {
        categories = storage.load([Category].self, forKey: "categories") ?? []
        actions = storage.load([Action].self, forKey: "actions") ?? []
        victories = storage.load([Victory].self, forKey: "victories") ?? []
        achievements = storage.load([Achievement].self, forKey: "achievements") ?? []
    }

    func saveAll() {
        saveCategories(); saveActions(); saveVictories(); saveAchievements()
    }

    func addCategory(title: String, colorHex: String) -> Category {
        let new = Category(title: title, colorHex: colorHex)
        categories.append(new)
        return new
    }

    func removeCategory(id: UUID) {
        categories.removeAll { $0.id == id }
        actions.removeAll { $0.categoryId == id }
        victories.removeAll { $0.categoryId == id }
        saveAll()
    }

    func addAction(title: String, categoryId: UUID) -> Action {
        let new = Action(title: title, categoryId: categoryId)
        actions.append(new)
        return new
    }

    func removeAction(id: UUID) {
        actions.removeAll { $0.id == id }
        victories.removeAll { $0.actionId == id }
        saveAll()
    }

    func addVictory(minutes: Int, categoryId: UUID, actionId: UUID, date: Date = Date()) -> Victory {
        let new = Victory(date: date, minutes: minutes, categoryId: categoryId, actionId: actionId)
        victories.append(new)
        return new
    }

    func removeVictory(id: UUID) {
        victories.removeAll { $0.id == id }
    }

    private func ensureInitialAchievements() {
        let base: [Achievement] = [
            Achievement(id: "first_victory", title: "First Victory", description: "Add your first victory", isUnlocked: false),
            Achievement(id: "streak_7", title: "7 Day Streak", description: "7 consecutive days with victories", isUnlocked: false),
            Achievement(id: "unique_20", title: "20 Actions", description: "20 unique actions", isUnlocked: false),
            Achievement(id: "minutes_1000", title: "1000 Minutes", description: "Total of 1000 minutes", isUnlocked: false),
            Achievement(id: "categories_5", title: "Category Creator", description: "Create 5 categories", isUnlocked: false),
            Achievement(id: "victories_50", title: "Victory Collector", description: "Collect 50 victories total", isUnlocked: false),
            Achievement(id: "daily_120", title: "Power Day", description: "Log 120+ minutes in a single day", isUnlocked: false),
            Achievement(id: "week_7", title: "Week Warrior", description: "7 victories in one week", isUnlocked: false)
        ]

        if achievements.isEmpty {
            achievements = base
            storage.save(achievements, for: .achievements)
            return
        }

        var map = Dictionary(uniqueKeysWithValues: achievements.map { ($0.id, $0) })
        for a in base where map[a.id] == nil { map[a.id] = a }
        let merged = Array(map.values).sorted { $0.id < $1.id }
        if merged != achievements {
            achievements = merged
            storage.save(achievements, for: .achievements)
        }
    }

    func updateAchievements() {
        let old = achievements
        var updated = achievements

        if let idx = updated.firstIndex(where: { $0.id == "first_victory" }) {
            updated[idx].isUnlocked = victories.isEmpty == false
        }

        let totalMinutes = victories.reduce(0) { $0 + $1.minutes }
        if let idx = updated.firstIndex(where: { $0.id == "minutes_1000" }) {
            updated[idx].isUnlocked = totalMinutes >= 1000
        }

        let uniqueActionsCount = Set(victories.map { $0.actionId }).count
        if let idx = updated.firstIndex(where: { $0.id == "unique_20" }) {
            updated[idx].isUnlocked = uniqueActionsCount >= 20
        }

        if let idx = updated.firstIndex(where: { $0.id == "streak_7" }) {
            updated[idx].isUnlocked = longestDailyStreak() >= 7
        }

        if let idx = updated.firstIndex(where: { $0.id == "categories_5" }) {
            updated[idx].isUnlocked = categories.count >= 5
        }

        if let idx = updated.firstIndex(where: { $0.id == "victories_50" }) {
            updated[idx].isUnlocked = victories.count >= 50
        }

        if let idx = updated.firstIndex(where: { $0.id == "daily_120" }) {
            let calendar = Calendar.current
            let dayToMinutes = Dictionary(grouping: victories, by: { calendar.startOfDay(for: $0.date) })
                .mapValues { $0.reduce(0) { $0 + $1.minutes } }
            updated[idx].isUnlocked = dayToMinutes.values.contains { $0 >= 120 }
        }

        if let idx = updated.firstIndex(where: { $0.id == "week_7" }) {
            let calendar = Calendar.current
            let weekToCount = Dictionary(grouping: victories) { victory in
                calendar.dateInterval(of: .weekOfYear, for: victory.date)?.start ?? calendar.startOfDay(for: victory.date)
            }
            .mapValues { Set($0.map { $0.id }).count }
            updated[idx].isUnlocked = weekToCount.values.contains { $0 >= 7 }
        }

        if updated != achievements {
            achievements = updated
            notifyForNewlyUnlocked(from: old, to: updated)
        }
    }

    private func longestDailyStreak() -> Int {
        if victories.isEmpty { return 0 }
        let calendar = Calendar.current
        let uniqueDays = Set(victories.map { calendar.startOfDay(for: $0.date) })
        let sortedDays = uniqueDays.sorted()
        var maxStreak = 1
        var currentStreak = 1
        for i in 1..<sortedDays.count {
            if let prev = calendar.date(byAdding: .day, value: 1, to: sortedDays[i-1]), prev == sortedDays[i] {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
        }
        maxStreak = max(maxStreak, currentStreak)
        return maxStreak
    }

    private func notifyForNewlyUnlocked(from old: [Achievement], to new: [Achievement]) {
        let oldMap = Dictionary(uniqueKeysWithValues: old.map { ($0.id, $0.isUnlocked) })
        for a in new {
            let was = oldMap[a.id] ?? false
            if a.isUnlocked && was == false {

            }
        }
    }

    func showToast(_ message: String, duration: TimeInterval = 2.0) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.toastMessage == message { self?.toastMessage = nil }
        }
    }
    
    @discardableResult
    func addVictory(categoryId: UUID, actionId: UUID, minutes: Int) -> Victory {
        addVictory(minutes: minutes, categoryId: categoryId, actionId: actionId, date: Date())
    }

    private func saveCategories() { storage.save(categories, forKey: "categories") }
    private func saveActions() { storage.save(actions, forKey: "actions") }
    private func saveVictories() { storage.save(victories, forKey: "victories") }
    private func saveAchievements() { storage.save(achievements, forKey: "achievements") }
}


