//
//  NoraiEngineTests.swift
//  Norai
//
//  Created by Amr on 28/06/2025.
//

import Foundation
import Norai
import Testing

struct NoraiEngineTests {
    private let configuration: NoraiConfiguration
    private let mockedLogger: MockedNoraiLogger
    init() {
        self.configuration = NoraiConfiguration(apiKey: "", environment: .sandbox)
        self.mockedLogger = MockedNoraiLogger()
    }
    
    @Test func trackShouldCallLog() {
        
    }
}
