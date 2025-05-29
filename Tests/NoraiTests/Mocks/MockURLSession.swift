//
//  MockURLSession.swift
//  Norai
//
//  Created by Amr on 29/05/2025.
//

import Foundation
@testable import Norai

class MockURLSession: URLSessionProtocol {
    
    private let mockData: Data
    private let mockURLResponse: URLResponse
    
    var didCallDataForURLRequest: Bool = false
    
    init(mockData: Data, mockURLResponse: URLResponse) {
        self.mockData = mockData
        self.mockURLResponse = mockURLResponse
    }
    
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        didCallDataForURLRequest = true
        return (mockData, mockURLResponse)
    }
}
