//
//  MockedBuffer.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation
import Norai

actor MockedBuffer: NoraiBufferProtocol {
    var isAddCalled: Bool = false
    var isDrainCalled: Bool = false

    func add(_ event: NoraiEvent) async {
        isAddCalled = true
    }
    
    func drain() async -> [NoraiEvent] {
        isDrainCalled = true
        return []
    }
}
