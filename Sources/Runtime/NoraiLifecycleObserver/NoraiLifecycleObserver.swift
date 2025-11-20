//
//  NoraiLifecycleObserver.swift
//  Norai
//
//  Created by Amr Hossam on 20/11/2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

class NoraiLifecycleObserver {
    private let sessionManager: NoraiSessionManagerProtocol
    
    @discardableResult
    init(sessionManager: NoraiSessionManagerProtocol) {
        self.sessionManager = sessionManager
        subscribe()
    }
    
    private func subscribe() {
    #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    #endif
    }
}

extension NoraiLifecycleObserver: NoraiLifecycleObserverProtocol {
    @objc func onActive() {
        Task {
            await sessionManager.appDidBecomeActive()
        }
    }
    
    @objc func onBackground() {
        Task {
            await sessionManager.appDidEnterBackground()            
        }
    }
}
