//
//  NoraiDispatchEventEndPoint.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation


enum NoraiDispatchEventEndPoint: NoraiEndpoint {
    
    case sendEventsInBatch
    case sendEventIndividually(NoraiEvent)
    
    var method: HTTPMethod {
        switch self {
        case .sendEventsInBatch, .sendEventIndividually: .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .sendEventsInBatch:
            return nil
        case .sendEventIndividually(let noraiEvent):
            return noraiEvent
        }
    }
    
    var parameters: [URLQueryItem]? { nil }
    
    var headers: [String : String]? { 
        ["Content-Type": "application/json"]
    }
    
    var path: String {
        switch self {
        case .sendEventsInBatch:
            return "/"
        case .sendEventIndividually:
            return "/events"
        }
    }
}

