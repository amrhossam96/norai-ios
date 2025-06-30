//
//  NoraiCachingLayer.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public actor NoraiCachingLayer {
    
}

extension NoraiCachingLayer: NoraiCachingLayerProtocol {
    public func save(_ events: [NoraiEvent]) async {
        
    }
    
    public func getAll() async -> [NoraiEvent] {
        return []
    }
    
    public func clear() async {
        
    }
}
