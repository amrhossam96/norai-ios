//
//  NSRecursiveLock.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation

extension NSRecursiveLock {
    @inlinable @discardableResult
    func sync<R>(operation: () -> R) -> R {
        self.lock()
        defer { self.unlock() }
        return operation()
    }
}
