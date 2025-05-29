//
//  NoraiNetworkClient.swift
//  Norai
//
//  Created by Amr on 28/05/2025.
//

import Foundation

public protocol NoraiNetworkClientProtocol {
    func execute<T>(_ endpoint: any NoraiEndpoint) async throws -> T where T: Decodable
}

public class NoraiNetworkClient {
    private let urlSession: URLSessionProtocol

    init(urlSession: URLSessionProtocol) {
        self.urlSession = urlSession
    }

    private func addComponents(to url: URL, from endpoint: any NoraiEndpoint) -> URL? {
        var components: URLComponents? = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.path.append(endpoint.path)
        components?.queryItems = endpoint.parameters
        return components?.url
    }

}

extension NoraiNetworkClient: NoraiNetworkClientProtocol {
    public func execute<T>(_ endpoint: any NoraiEndpoint) async throws -> T where T : Decodable {
        guard let url: URL = endpoint.baseURL,
              let fullURL: URL = addComponents(to: url, from: endpoint)
        else { throw NoraiNetworkError.invalidURL }

        var urlRequest: URLRequest = URLRequest(url: fullURL)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.httpBody = endpoint.body
        urlRequest.allHTTPHeaderFields = endpoint.headers

        let (data, response): (Data, URLResponse)

        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw NoraiNetworkError.networkFailure(underlyingError: error.localizedDescription)
        }

        guard !data.isEmpty else {
            throw NoraiNetworkError.noData
        }

        guard let httpURLResponse: HTTPURLResponse = response as? HTTPURLResponse else {
            throw NoraiNetworkError.invalidResponse
        }

        guard (200...299).contains(httpURLResponse.statusCode) else {
            throw NoraiNetworkError.requestFailed(statusCode: httpURLResponse.statusCode)
        }
        
        do {
            let jsonDecoder: JSONDecoder = JSONDecoder()
            let decodedResult: T = try jsonDecoder.decode(T.self, from: data)
            return decodedResult
        } catch {
            throw NoraiNetworkError.decodingError
        }
    }
}
