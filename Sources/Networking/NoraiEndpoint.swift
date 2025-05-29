//
//  NoraiEndpoint.swift
//  Norai
//
//  Created by Amr on 28/05/2025.
//

import Foundation

public protocol NoraiEndpoint {
    var method: HTTPMethod { get }
    var baseURL: URL? { get }
    var body: Data? { get }
    var parameters: [URLQueryItem]? { get }
    var headers: [String: String]? { get }
    var path: String { get }
}

public extension NoraiEndpoint {
    var baseURL: URL? {
        return URL(string: "http://127.0.0.1:3045")
    }
}