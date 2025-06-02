//
//  MockEndPoint.swift
//  Norai
//
//  Created by Amr on 29/05/2025.
//

import Foundation
@testable import Norai

enum MockEndPoint: NoraiEndpoint {
    
    case mock
    case invalidURLEndPoint
    
    var method: HTTPMethod { .get }
    
    var body: Data? { nil }
    
    var parameters: [URLQueryItem]? { nil }
    
    var headers: [String : String]? { nil }
    
    var path: String { "/" }
    
    static let mockURLResquest = URLRequest(url: URL(string: "https://test.com")!)
    
    static let invalidResponse = URLResponse(url: URL(string: "https://test.com")!,
                                             mimeType: nil,
                                             expectedContentLength: 0,
                                             textEncodingName: nil)
    
    static var validResponse: URLResponse {
        HTTPURLResponse(url: URL(string: "https://www.example.com")!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil)!
    }
    
    static func invalidResponseWithStatus(code: Int) -> URLResponse {
        HTTPURLResponse(url: URL(string: "https://www.example.com")!,
                        statusCode: code,
                        httpVersion: nil,
                        headerFields: nil)!
    }
    
    static var emptyData: Data {
        return Data()
    }
    
    static var someData: Data {
        return """
               {
                   "id": 123,
                   "message": "Success!"
               }
               """.data(using: .utf8)!
    }
    
    static let invalidJSONData = """
    {
        "unexpected_field" "something",
        "another": 123
    }
    """.data(using: .utf8)!

    var baseURL: URL? {
        switch self {
        case .invalidURLEndPoint:
                return URL(string: "http://wwwwwwwwwww  ")
        default: return URL(string: "http://127.0.0.1:3045")
        }
    }
}

struct MockResponse: Decodable {}
