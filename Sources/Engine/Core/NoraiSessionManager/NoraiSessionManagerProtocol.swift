//
//  NoraiSessionManagerProtocol.swift
//  Norai
//
//  Created by Amr on 30/06/2025.
//

import Foundation

public protocol NoraiSessionManagerProtocol: Sendable {
    func startSession() async
    func endSession() async
    func getCurrentSession() async -> NoraiSession
}