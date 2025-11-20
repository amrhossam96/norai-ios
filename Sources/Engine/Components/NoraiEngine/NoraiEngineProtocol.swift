//
//  NoraiEngineProtocol.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

protocol NoraiEngineProtocol {
    func start() async
    func identify(userID: String) async
    func trackEvent(name: String, properties: [String: JSONValue]) async
}
