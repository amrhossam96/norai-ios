//
//  Clock+Extensions.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation

extension Clock {
    public func sleep(for duration: Duration, tolerance: Duration? = nil) async throws {
        try await self.sleep(until: self.now.advanced(by: duration), tolerance: tolerance)
    }
}

