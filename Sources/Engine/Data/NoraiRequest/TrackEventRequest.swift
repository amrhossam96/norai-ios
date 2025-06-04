//
//  TrackEventRequest.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

struct TrackEventRequest: Encodable {
    let tracks: [NoraiEvent]
}

extension TrackEventRequest {
    func encoded() throws -> Data {
        do {
            let jsonEncoder = JSONEncoder()
            return try jsonEncoder.encode(self)
        } catch {
            throw NoraiError.eventsEncodingFailure
        }
    }
}
