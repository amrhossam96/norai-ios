//
//  NoraiIdentitySyncingEndPoint.swift
//  Norai
//
//  Created by Amr Hossam on 18/11/2025.
//

import Foundation

enum NoraiIdentitySyncingEndPoint: NoraiEndpoint {
    case identify(NoraiUserIdentity)
    
    var method: HTTPMethod { .put }
    
    var body: Encodable? {
        switch self {
        case .identify(let noraiUserIdentity):
            return noraiUserIdentity
        }
    }
    
    var path: String {
        switch self {
        case .identify:
            return "/identify"
        }
    }
    
    
}




