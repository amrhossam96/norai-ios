//
//  NoraiURLSessionProtocol.swift
//  Norai
//
//  Created by Amr on 28/05/2025.
//

import Foundation

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
    /// Conforming to URLSessionProtocol is neccessary for mocking the data(for: request) method
    /// so it can add it to unit testing
}