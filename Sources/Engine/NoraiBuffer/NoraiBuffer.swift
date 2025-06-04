//
//  NoraiBuffer.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public actor NoraiBuffer {
    private var cache: [NoraiEvent] = []
    private let maxSize: Int
    
    public init(maxSize: Int = 10) {
        self.maxSize = maxSize
    }
}

extension NoraiBuffer: NoraiBufferProtocol {

    public func add(_ event: NoraiEvent) {
        cache.append(event)
    }
    
    public func flush() {
        cache.removeAll()
    }
    
    public func drain() -> [NoraiEvent] {
        defer { cache.removeAll() }
        return cache
    }
    
    public func needsToFlush() -> Bool {
        return cache.count >= maxSize
    }
}
