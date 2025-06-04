//
//  File.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public protocol NoraiBufferProtocol {
    func add(_ event: NoraiEvent) async
    func flush() async
    func drain() async -> [NoraiEvent]
    func needsToFlush() async -> Bool
}
