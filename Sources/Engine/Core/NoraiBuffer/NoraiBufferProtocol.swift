//
//  NoraiBufferProtocol.swift
//  Norai
//
//  Created by Amr on 29/06/2025.
//

import Foundation

public protocol NoraiBufferProtocol: Sendable {
    func add(_ event: NoraiEvent) async
    func drain() async -> [NoraiEvent]
    func shouldFlush() async -> Bool
}
