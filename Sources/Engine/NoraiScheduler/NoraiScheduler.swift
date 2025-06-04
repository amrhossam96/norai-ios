//
//  NoraiScheduler.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public protocol NoraiSchedulerDelegate: AnyObject {
    func shouldFlush() async
}

public class NoraiScheduler {
    weak public var delegate: NoraiSchedulerDelegate?
    private let buffer: any NoraiBufferProtocol
    private let maxSize: Int
    private let flushInterval: TimeInterval
    private let clock: any Clock
    private var lastFlushTime: Date
    
    public init(
        buffer: any NoraiBufferProtocol,
        maxSize: Int,
        flushInterval: TimeInterval,
        clock: any Clock) {
            self.buffer = buffer
            self.maxSize = maxSize
            self.flushInterval = flushInterval
            self.clock = clock
            self.lastFlushTime = .now
        }
}

extension NoraiScheduler: NoraiSchedulerProtocol {
    public func start() {
        
    }
    
    public func stop() {
        
    }
    
    public func eventAdded() {
        
    }
}
