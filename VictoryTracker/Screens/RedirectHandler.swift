
import Foundation


final class RedirectHandler: NSObject, URLSessionDelegate, URLSessionTaskDelegate {

    private var redirectChain: [URL] = []
    private let completion: (String) -> Void

    init(completion: @escaping (String) -> Void) {
        self.completion = completion
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {

        if let url = request.url {
            redirectChain.append(url)
        }
        completionHandler(request)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {

        let finalURL = redirectChain.last?.absoluteString ??
                       task.originalRequest?.url?.absoluteString ?? ""

        if let error = error {
            print("\(error.localizedDescription)")
        }

        completion(finalURL)
    }
}
