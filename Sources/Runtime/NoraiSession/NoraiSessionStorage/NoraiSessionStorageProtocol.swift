//
//  NoraiSessionStorageProtocol.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

protocol NoraiSessionStorageProtocol {
    func loadSessionID() async -> String?
    func loadSessionStart() async -> Date?
    func loadLastActivity() async -> Date?
    
    func saveSessionID(_ id: String) async
    func saveSessionStart(_ date: Date) async
    func saveLastActivity(_ date: Date) async
    
    func clear() async
}
