//
//  MockFailingURLProtocol.swift
//  Norai
//
//  Created by Amr on 29/05/2025.
//

import Foundation

class MockFailingURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let error = NSError(domain: "TestDomain", code: 1234, userInfo: nil)
        client?.urlProtocol(self, didFailWithError: error)
    }
    
    override func stopLoading() {}
}
