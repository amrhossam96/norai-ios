//
//  TestClock.swift
//  Norai
//
//  Created by Amr on 03/07/2025.
//

import Foundation

public class TestClock: Clock, @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var scheduled: [(deadline: Instant, continuation: UnsafeContinuation<(), Never>)] = []
    public func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        guard lock.sync(operation: { deadline > now }) 
        else { return }
        await withUnsafeContinuation { continution in
            lock.sync {
                scheduled.append((deadline: deadline, continuation: continution))
            }
        }
    }
    
    public func advance(by duration: Duration) async {
        await self.advance(to: now.advanced(by: duration))
    }
    
    public func advance(to deadline: Instant) async {
        while self.lock.sync(operation: { self.now }) <= deadline {
            await Task.megaYield()
            let `return` = { () -> Bool in
                self.lock.lock()
                self.scheduled.sort { $0.deadline < $1.deadline}
                
                guard let next = self.scheduled.first,
                      deadline >= next.deadline
                else {
                    self.now = deadline
                    self.lock.unlock()
                    return true
                }
                
                self.now = next.deadline
                self.scheduled.removeFirst()
                self.lock.unlock()
                next.continuation.resume()
                return false
            }()
            if `return` {
                return
            }
        }
    }
    
    public var now: Instant = Instant()
    public var minimumResolution: Duration = .zero
    
    public typealias Duration = Swift.Duration
    public struct Instant: InstantProtocol {
        public typealias Duration = Swift.Duration
        private var offset: Duration = .zero
        public func advanced(by duration: Duration) -> Self {
            .init(offset: self.offset + duration)
        }
        
        public func duration(to other: Self) -> Duration {
            other.offset - self.offset
        }
        
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }
    
    
}
