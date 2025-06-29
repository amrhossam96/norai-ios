//
//  MockedMiddlewareExecutor.swift
//  Norai
//
//  Created by Amr on 01/06/2025.
//

import Foundation
import Norai

class MockedMiddlewareExecutor {
    private let middlewares: [any NoraiMiddleware]

    init(middlewares: [any NoraiMiddleware] = []) {
        self.middlewares = middlewares
    }
    
    var isExecutePreRequestMiddlewaresCalled: Bool = false
    var isExecutePostResponseMiddlewaresCalled: Bool = false
}

extension MockedMiddlewareExecutor: MiddlewareExecutorProtocol {
    func executePreRequestMiddlewares(for request: URLRequest) async throws -> URLRequest {
        var newRequest = request
        isExecutePreRequestMiddlewaresCalled = true
        for middleware in self.middlewares where middleware.type == .PRE && middleware.isErrorHandlingMandatory {
            newRequest = try await middleware.processRequest(newRequest)
        }
        return newRequest
    }
    
    func executePostResponseMiddlewares(with response: URLResponse, for request: URLRequest) async throws -> URLResponse {
        isExecutePostResponseMiddlewaresCalled = true
        return response
    }
}
