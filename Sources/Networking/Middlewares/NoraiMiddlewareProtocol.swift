//
//  NoraiMiddlewareProtocol.swift
//  Norai
//
//  Created by Amr on 29/05/2025.
//

import Foundation

public enum MiddlewareType {
    case PRE
    case POST
}

public protocol NoraiMiddleware {
    func processRequest(_ request: URLRequest) async throws -> URLRequest
    func processResponse(_ response: URLResponse, for request: URLRequest) async throws -> URLResponse
    
    var type: MiddlewareType { get }
    var isErrorHandlingMandatory: Bool { get }
}
