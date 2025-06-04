//
//  MiddlewareExecutor.swift
//  Norai
//
//  Created by Amr on 01/06/2025.
//

import Foundation

public protocol MiddlewareExecutorProtocol {
    func executePreRequestMiddlewares(for request: URLRequest) async throws -> URLRequest
    func executePostResponseMiddlewares(with response: URLResponse, for request: URLRequest) async throws -> URLResponse
}

public class MiddlewareExecutor {
    private var middlewares: [any NoraiMiddleware]

    public init(middlewares: [any NoraiMiddleware] = []) {
        self.middlewares = middlewares
    }
}

extension MiddlewareExecutor: MiddlewareExecutorProtocol {
    public func executePreRequestMiddlewares(for request: URLRequest) async throws -> URLRequest {
        var urlRequest: URLRequest = request
        do {
            for middleware: any NoraiMiddleware in self.middlewares where middleware.type == .PRE {
                urlRequest = try await middleware.processRequest(urlRequest)
            }
            return urlRequest
        } catch {
            throw NoraiNetworkError.mandatoryMiddlewareFailure(underlyingError: error.localizedDescription)
        }
    }

    public func executePostResponseMiddlewares(with response: URLResponse, for request: URLRequest) async throws -> URLResponse {
        var updatedResponse: URLResponse = response
        do {
            for middleware: any NoraiMiddleware in self.middlewares where middleware.type == .POST &&
            middleware.isErrorHandlingMandatory {
                updatedResponse = try await middleware.processResponse(response, for: request)
            }
            return updatedResponse
        } catch {
            throw NoraiNetworkError.mandatoryMiddlewareFailure(underlyingError: error.localizedDescription)
        }
    }
}
