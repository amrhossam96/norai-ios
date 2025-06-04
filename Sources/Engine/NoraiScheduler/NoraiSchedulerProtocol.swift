//
//  File.swift
//  Norai
//
//  Created by Amr on 04/06/2025.
//

import Foundation

public protocol NoraiSchedulerProtocol {
    func start()
    func stop()
    func eventAdded() async
    var delegate: NoraiSchedulerDelegate? { get set }
}
