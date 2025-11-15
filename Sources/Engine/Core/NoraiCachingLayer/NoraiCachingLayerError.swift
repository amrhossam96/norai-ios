//
//  File.swift
//  Norai
//
//  Created by Amr Hossam on 14/11/2025.
//

import Foundation

enum NoraiCachingLayerError: Error {
    case filePathDoesntExist
    case encodingError
    case decodingError
    case fileWriteError
    case fileSizeExceeded
    case directoryCreationFailed
}
