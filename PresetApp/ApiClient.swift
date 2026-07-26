import Foundation

struct HttpBinResponse: Codable {
    let url: String?
    let data: String?
    let json: [String: String]?
}

class APIClient {

    static let shared = APIClient()

    private let client: HttpClient

    private init() {
        client = HttpClient(baseURL: URL(string: "https://httpbin.org/")!)
    }

    func postTest(body: [String: String], completion: @escaping (Result<HttpBinResponse, Error>) -> Void) {
        let endpoint = Endpoint.json("/post", method: .post, body: body)
        client.execute(endpoint, completion: completion)
    }
}
