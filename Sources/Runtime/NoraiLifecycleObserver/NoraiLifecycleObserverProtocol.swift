//
//  NoraiLifecycleObserverProtocol.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation

protocol NoraiLifecycleObserverProtocol: AnyObject {
    func onActive()
    func onBackground()
}
