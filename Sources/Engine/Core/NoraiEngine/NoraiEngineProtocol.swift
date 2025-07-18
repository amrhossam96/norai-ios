//
//  NoraiEngineProtocol.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation

protocol NoraiEngineProtocol {
    func track(event: NoraiEvent) async
    func identify(user: NoraiUserContext) async
    func start() async throws
}
