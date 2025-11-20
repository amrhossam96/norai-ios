//
//  NoraiEventDispatchedResponse.swift
//  Norai
//
//  Created by Amr Hossam on 19/11/2025.
//

import Foundation

struct NoraiCodableData: Codable {
    let status: String
}

struct NoraiEventDispatchedResponse: Codable {
    let data: NoraiCodableData
}

