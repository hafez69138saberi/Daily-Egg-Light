

import Foundation
import AdServices

struct AdServicesTokenProvider {

    static func fetchBase64Token() -> String? {

        guard #available(iOS 14.3, *) else {
            return nil
        }

        do {
            let token = try AAAttribution.attributionToken()
            guard let data = token.data(using: .utf8) else {
                return nil
            }
            let base64 = data.base64EncodedString()

            return base64
        } catch {
            return nil
        }
    }
}
