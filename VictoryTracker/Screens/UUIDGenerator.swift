
import Foundation


struct UUIDGenerator {

    static func v4Lowercased() -> String {
        let uuid = UUID().uuidString.lowercased()
        return uuid
    }

    
    static func v7Lowercased() -> String {
        let uuid = UUID().uuidString.lowercased()
        return uuid
    }
}
