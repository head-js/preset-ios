import Foundation
import os.log

private let httpClientLog = OSLog(subsystem: "com.lisitede.preset.app", category: "HttpClient")

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    var headers: [String: String] = [:]
    var body: Data? = nil

    static func json(_ path: String, method: HTTPMethod, body: [String: String]) -> Endpoint {
        let data = try? JSONSerialization.data(withJSONObject: body)
        return Endpoint(
            path: path,
            method: method,
            headers: ["Content-Type": "application/json"],
            body: data
        )
    }
}

class HttpClient {

    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, configuration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: configuration)
    }

    func execute<T: Decodable>(
        _ endpoint: Endpoint,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            os_log("✗ invalid url", log: httpClientLog, type: .error)
            completion(.failure(HttpClientError.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = endpoint.body

        os_log("→ %{public}@ %{public}@", log: httpClientLog, type: .info,
               endpoint.method.rawValue, url.absoluteString)
        if let body = endpoint.body {
            os_log("  body %{public}@", log: httpClientLog, type: .debug,
                   String(data: body, encoding: .utf8) ?? "")
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                os_log("✗ network %{public}@", log: httpClientLog, type: .error,
                       error.localizedDescription)
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data else {
                os_log("✗ empty response", log: httpClientLog, type: .error)
                DispatchQueue.main.async { completion(.failure(HttpClientError.emptyResponse)) }
                return
            }
            os_log("← %{public}@", log: httpClientLog, type: .debug,
                   String(data: data, encoding: .utf8) ?? "")
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                os_log("✗ decode %{public}@", log: httpClientLog, type: .error,
                       error.localizedDescription)
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
        task.resume()
    }
}

enum HttpClientError: Error, LocalizedError {
    case invalidURL
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "invalid url"
        case .emptyResponse: return "empty response"
        }
    }
}
