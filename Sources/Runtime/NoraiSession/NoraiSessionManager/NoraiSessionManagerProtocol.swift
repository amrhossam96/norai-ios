//
//  NoraiSessionManagerProtocol.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

protocol NoraiSessionManagerProtocol: Sendable {
    var currentSessionID: UUID { get async }
    func notifyActivity() async
    func appDidBecomeActive() async
    func appDidEnterBackground() async
    func rotateSession(reason: SessionRotationReason) async
}
