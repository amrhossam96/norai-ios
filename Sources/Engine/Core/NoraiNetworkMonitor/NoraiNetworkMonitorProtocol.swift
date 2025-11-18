//
//  NoraiNetworkMonitorProtocol.swift
//  Norai
//
//  Created by Amr on 02/07/2025.
//

import Foundation

public protocol NoraiNetworkMonitorProtocol: Sendable {
    func startMonitoring() async
    func isNetworkAvailable() async -> Bool
    func connectionType() async -> String?
}
