import Foundation

final class UserDefaultsStorage {
    static let shared = UserDefaultsStorage()
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    enum Key: String {
        case achievements
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save<T: Encodable>(_ value: T, forKey key: String) {
        do {
            let data = try encoder.encode(value)
            defaults.set(data, forKey: key)
        } catch {
            
        }
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    func save<T: Encodable>(_ value: T, for key: Key) {
        save(value, forKey: key.rawValue)
    }

    func load<T: Decodable>(_ type: T.Type, for key: Key) -> T? {
        load(type, forKey: key.rawValue)
    }
}


