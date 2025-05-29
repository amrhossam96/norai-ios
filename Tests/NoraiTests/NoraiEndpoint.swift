//
//  NoraiEndpoint.swift
//  Norai
//
//  Created by Amr on 29/05/2025.
//

import Foundation
import Testing
@testable import Norai

struct TestEndpoint: NoraiEndpoint {
    var method: HTTPMethod { .get }
    var body: Data? { nil }
    var parameters: [URLQueryItem]? { nil }
    var headers: [String: String]? { nil }
    var path: String { "/test" }
}

struct NoraiEndpointTests {
    @Test func baseURLDefaultImplementation() {
        let endpoint = TestEndpoint()
        
        let baseURL = endpoint.baseURL
        
        #expect(baseURL != nil)
        #expect(baseURL?.absoluteString == "http://127.0.0.1:3045")
    }
    
    @Test func pathForEndpoint() {
        let endPoint = TestEndpoint()
        let path = endPoint.path
        #expect(path == "/test")
    }
    
    @Test func defaulMethodisGET() {
        let endPoint = TestEndpoint()
        let method = endPoint.method
        #expect(method.rawValue == "GET")
    }
    
    @Test func defaultBodyIsNil() {
        let endPoint = TestEndpoint()
        let body = endPoint.body
        #expect(body == nil)
    }
    
    @Test func defaultParametersIsNil() {
        let endPoint = TestEndpoint()
        let parameters = endPoint.parameters
        #expect(parameters == nil)
    }
    
    @Test func defaultHeadersIsNil() {
        let endPoint = TestEndpoint()
        let headers = endPoint.headers
        #expect(headers == nil)
    }
}

