//
//  NoraiDispatchEventEndPoint.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation


enum NoraiDispatchEventEndPoint: NoraiEndpoint {
    
    case sendEventsInBatch
    
    var method: HTTPMethod {
        switch self {
        case .sendEventsInBatch: .post
        }
    }
    
    var body: Data? { nil }
    
    var parameters: [URLQueryItem]? { nil }
    
    var headers: [String : String]? { 
        ["Content-Type": "application/json"]
    }
    
    var path: String {
        switch self {
        case .sendEventsInBatch:
            return "/"
        }
    }
}
