//
//  NoraiDispatchEventEndPoint.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation


enum NoraiDispatchEventEndPoint: NoraiEndpoint {
    
    case sendEventsInBatch(NoraiBatchEventsRequest)
    
    var method: HTTPMethod {
        switch self {
        case .sendEventsInBatch: .post
        }
    }
    
    var body: Data? {
        let encoder = JSONEncoder()
        do {
            switch self {
            case .sendEventsInBatch(let noraiBatchEventsRequest):
                let data = try encoder.encode(noraiBatchEventsRequest)
                return data
            }
        } catch {
            return nil
        }
    }
    
    var parameters: [URLQueryItem]? { nil }
    
    var headers: [String : String]? { nil }
    
    var path: String {
        switch self {
        case .sendEventsInBatch:
            return "/"
        }
    }
}
