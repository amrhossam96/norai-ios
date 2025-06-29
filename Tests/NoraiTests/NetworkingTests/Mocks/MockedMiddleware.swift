//
//  MockedMiddleware.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation
import Norai

class MockedMiddleware {
    
    var isProcessRequestCalled: Bool = false
    var isProcessResponseCalled: Bool = false
    
    var type: MiddlewareType
    
    init(type: MiddlewareType = .PRE) {
        self.type = type
    }
    
    var isErrorHandlingMandatory: Bool {
        true
    }
}

extension MockedMiddleware: NoraiMiddleware {
    func processRequest(_ request: URLRequest) async throws -> URLRequest {
        isProcessRequestCalled = true
        return request
    }
    
    func processResponse(_ response: URLResponse, for request: URLRequest) async throws -> URLResponse {
        isProcessResponseCalled = true
        return response
    }
}
