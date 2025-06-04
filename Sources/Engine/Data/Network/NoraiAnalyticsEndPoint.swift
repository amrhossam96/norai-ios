//
//  NoraiAnalyticsEndPoint.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

enum NoraiAnalyticsEndPoint: NoraiEndpoint {
    
    case track(events: [NoraiEvent])
    
    var method: HTTPMethod { .post }
    
    var body: Data? {
        switch self {
        case .track(let events):
            return try? TrackEventRequest(tracks: events).encoded()
        }
    }
    
    var parameters: [URLQueryItem]? { nil }
    
    var headers: [String : String]? { nil }
    
    var path: String {
        switch self {
        case .track:
            "/v1/analytics/track"
        }
    }
}
