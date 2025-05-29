//
//  NoraiNetworkError.swift
//  Norai
//
//  Created by Amr on 28/05/2025.
//

public enum NoraiNetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case invalidResponse
    case decodingError
    case networkFailure(underlyingError: String)
    case noData
}
