//
//  MockedFailableMiddleware.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation
import Norai

class MockedFailableMiddleware: NoraiMiddleware {
    func processRequest(_ request: URLRequest) async throws -> URLRequest {
        throw NoraiNetworkError.mandatoryMiddlewareFailure(underlyingError: "Failure")
    }
    
    func processResponse(_ response: URLResponse, for request: URLRequest) async throws -> URLResponse {
        throw NoraiNetworkError.mandatoryMiddlewareFailure(underlyingError: "Failure")
    }
    
    init(type: MiddlewareType = .PRE) {
        self.type = type
    }
    
    var type: MiddlewareType
    
    var isErrorHandlingMandatory: Bool = true
}
