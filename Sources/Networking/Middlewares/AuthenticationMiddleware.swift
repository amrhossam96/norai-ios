//
//  AuthenticationMiddleware.swift
//  Norai
//
//  Created by Amr Hossam on 19/11/2025.
//

import Foundation

struct AuthenticationMiddleware: NoraiMiddleware {
    let projectAPIKey: String
    
    func processRequest(_ request: URLRequest) async throws -> URLRequest {
        var mutableRequest = request
        mutableRequest.setValue(projectAPIKey, forHTTPHeaderField: "x-norai-api-key")
        return mutableRequest
    }
    
    func processResponse(_ response: URLResponse, for request: URLRequest) async throws -> URLResponse {
        return response
    }
    
    var type: MiddlewareType { .PRE }
    
    var isErrorHandlingMandatory: Bool { false }
}
