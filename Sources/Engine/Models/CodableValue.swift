//
//  CodableValue.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation

public enum CodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    indirect case array([CodableValue])
    indirect case dictionary([String: CodableValue])
    case null
}
