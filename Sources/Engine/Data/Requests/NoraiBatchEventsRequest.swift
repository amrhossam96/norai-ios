//
//  NoraiBatchEventsRequest.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation

struct NoraiBatchEventsRequest: Encodable {
    let events: [NoraiEvent]
}
