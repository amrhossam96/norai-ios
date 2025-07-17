//
//  NoraiEngineStateManagerTests.swift
//  Norai
//
//  Created by Amr on 17/07/2025.
//

import Foundation
@testable import Norai
import Testing

struct NoraiEngineStateManagerTests {
    
    // MARK: - Initialization Tests
    
    @Test func shouldInitializeWithProvidedState() async {
        let initialState = NoraiEngineState(
            isRunning: false,
            sessionId: UUID(),
            lastScreen: "TestScreen",
            funnelStep: "onboarding",
            userContext: NoraiUserContext(id: "test-user", isLoggedIn: true)
        )
        let sut = NoraiEngineStateManager(state: initialState)
        
        let state = await sut.getState()
        
        #expect(state.isRunning == false)
        #expect(state.sessionId == initialState.sessionId)
        #expect(state.lastScreen == "TestScreen")
        #expect(state.funnelStep == "onboarding")
        #expect(state.userContext?.id == "test-user")
        #expect(state.userContext?.isLoggedIn == true)
    }
    
    @Test func shouldInitializeWithDefaultState() async {
        let defaultState = NoraiEngineState()
        let sut = NoraiEngineStateManager(state: defaultState)
        
        let state = await sut.getState()
        
        #expect(state.isRunning == false)
        #expect(state.sessionId != UUID()) // Should have valid UUID
        #expect(state.lastScreen == nil)
        #expect(state.funnelStep == nil)
        #expect(state.userContext == nil)
    }
    
    // MARK: - Engine State Management Tests
    
    @Test func shouldStartEngineSuccessfully() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        let result = await sut.startEngine()
        let state = await sut.getState()
        
        #expect(result == true)
        #expect(state.isRunning == true)
    }
    
    @Test func shouldPreventDoubleStart() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        let firstStart = await sut.startEngine()
        let secondStart = await sut.startEngine()
        let state = await sut.getState()
        
        #expect(firstStart == true)
        #expect(secondStart == false)
        #expect(state.isRunning == true)
    }
    
    @Test func shouldStartEngineFromAlreadyRunningState() async {
        let initialState = NoraiEngineState(isRunning: true)
        let sut = NoraiEngineStateManager(state: initialState)
        
        let result = await sut.startEngine()
        let state = await sut.getState()
        
        #expect(result == false)
        #expect(state.isRunning == true)
    }
    
    // MARK: - User Context Management Tests
    
    @Test func shouldUpdateUserContext() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        let userContext = NoraiUserContext(
            id: "user123",
            anonymousId: "anon456",
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            isLoggedIn: true
        )
        
        await sut.update(user: userContext)
        let state = await sut.getState()
        
        #expect(state.userContext?.id == "user123")
        #expect(state.userContext?.anonymousId == "anon456")
        #expect(state.userContext?.firstName == "John")
        #expect(state.userContext?.lastName == "Doe")
        #expect(state.userContext?.email == "john@example.com")
        #expect(state.userContext?.isLoggedIn == true)
    }
    
    @Test func shouldReplaceExistingUserContext() async {
        let initialUser = NoraiUserContext(id: "old-user", isLoggedIn: false)
        let initialState = NoraiEngineState(userContext: initialUser)
        let sut = NoraiEngineStateManager(state: initialState)
        
        let newUser = NoraiUserContext(id: "new-user", isLoggedIn: true)
        await sut.update(user: newUser)
        let state = await sut.getState()
        
        #expect(state.userContext?.id == "new-user")
        #expect(state.userContext?.isLoggedIn == true)
    }
    
    @Test func shouldHandlePartialUserContext() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        let partialUser = NoraiUserContext(
            id: nil,
            anonymousId: "anon123",
            firstName: nil,
            lastName: nil,
            email: nil,
            isLoggedIn: false
        )
        
        await sut.update(user: partialUser)
        let state = await sut.getState()
        
        #expect(state.userContext?.id == nil)
        #expect(state.userContext?.anonymousId == "anon123")
        #expect(state.userContext?.firstName == nil)
        #expect(state.userContext?.isLoggedIn == false)
    }
    
    // MARK: - State Preservation Tests
    
    @Test func shouldPreserveOtherStateWhenUpdatingUser() async {
        let sessionId = UUID()
        let initialState = NoraiEngineState(
            isRunning: true,
            sessionId: sessionId,
            lastScreen: "HomeScreen",
            funnelStep: "checkout"
        )
        let sut = NoraiEngineStateManager(state: initialState)
        
        let userContext = NoraiUserContext(id: "user123", isLoggedIn: true)
        await sut.update(user: userContext)
        let state = await sut.getState()
        
        #expect(state.isRunning == true)
        #expect(state.sessionId == sessionId)
        #expect(state.lastScreen == "HomeScreen")
        #expect(state.funnelStep == "checkout")
        #expect(state.userContext?.id == "user123")
    }
    
    @Test func shouldPreserveUserContextWhenStartingEngine() async {
        let userContext = NoraiUserContext(id: "user123", isLoggedIn: true)
        let initialState = NoraiEngineState(userContext: userContext)
        let sut = NoraiEngineStateManager(state: initialState)
        
        _ = await sut.startEngine()
        let state = await sut.getState()
        
        #expect(state.isRunning == true)
        #expect(state.userContext?.id == "user123")
        #expect(state.userContext?.isLoggedIn == true)
    }
    
    // MARK: - Concurrency Tests
    
    @Test func shouldHandleConcurrentStartAttempts() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        let results = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await sut.startEngine()
                }
            }
            
            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        // Exactly one should succeed
        let successCount = results.filter { $0 }.count
        #expect(successCount == 1)
        
        let finalState = await sut.getState()
        #expect(finalState.isRunning == true)
    }
    
    @Test func shouldHandleConcurrentUserUpdates() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let user = NoraiUserContext(id: "user-\(i)", isLoggedIn: i % 2 == 0)
                    await sut.update(user: user)
                }
            }
        }
        
        let finalState = await sut.getState()
        #expect(finalState.userContext != nil)
        // Final user should be one of the concurrent updates
        let userId = finalState.userContext?.id
        #expect(userId?.hasPrefix("user-") == true)
    }
    
    @Test func shouldHandleMixedConcurrentOperations() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        await withTaskGroup(of: Void.self) { group in
            // Multiple start attempts
            for _ in 0..<3 {
                group.addTask {
                    _ = await sut.startEngine()
                }
            }
            
            // Multiple user updates
            for i in 0..<5 {
                group.addTask {
                    let user = NoraiUserContext(id: "concurrent-user-\(i)", isLoggedIn: true)
                    await sut.update(user: user)
                }
            }
            
            // Multiple state reads
            for _ in 0..<5 {
                group.addTask {
                    _ = await sut.getState()
                }
            }
        }
        
        let finalState = await sut.getState()
        #expect(finalState.isRunning == true)
        #expect(finalState.userContext != nil)
    }
    
    // MARK: - State Consistency Tests
    
    @Test func shouldMaintainStateConsistencyDuringUpdates() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        // Start engine
        _ = await sut.startEngine()
        
        // Update user multiple times
        for i in 0..<5 {
            let user = NoraiUserContext(id: "user-\(i)", isLoggedIn: i % 2 == 0)
            await sut.update(user: user)
            
            let state = await sut.getState()
            #expect(state.isRunning == true) // Should remain running
            #expect(state.userContext?.id == "user-\(i)")
        }
    }
    
    @Test func shouldHandleRapidStateAccess() async {
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        // Perform rapid state reads
        let states = await withTaskGroup(of: NoraiEngineState.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    await sut.getState()
                }
            }
            
            var states: [NoraiEngineState] = []
            for await state in group {
                states.append(state)
            }
            return states
        }
        
        // All states should be consistent
        let firstState = states.first!
        for state in states {
            #expect(state.isRunning == firstState.isRunning)
            #expect(state.sessionId == firstState.sessionId)
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func shouldHandleNilUserContext() async {
        let userContext = NoraiUserContext(
            id: nil,
            anonymousId: nil,
            firstName: nil,
            lastName: nil,
            email: nil,
            isLoggedIn: false
        )
        let sut = NoraiEngineStateManager(state: NoraiEngineState())
        
        await sut.update(user: userContext)
        let state = await sut.getState()
        
        #expect(state.userContext != nil)
        #expect(state.userContext?.id == nil)
        #expect(state.userContext?.isLoggedIn == false)
    }
    
    @Test func shouldMaintainSessionIdConsistency() async {
        let sessionId = UUID()
        let initialState = NoraiEngineState(sessionId: sessionId)
        let sut = NoraiEngineStateManager(state: initialState)
        
        _ = await sut.startEngine()
        await sut.update(user: NoraiUserContext(id: "test", isLoggedIn: true))
        
        let finalState = await sut.getState()
        #expect(finalState.sessionId == sessionId)
    }
    
    @Test func shouldPreserveComplexInitialState() async {
        let sessionId = UUID()
        let userContext = NoraiUserContext(
            id: "complex-user",
            anonymousId: "anon-123",
            firstName: "Complex",
            lastName: "User",
            email: "complex@test.com",
            isLoggedIn: true
        )
        let initialState = NoraiEngineState(
            isRunning: false,
            sessionId: sessionId,
            lastScreen: "ComplexScreen",
            funnelStep: "complex-step",
            userContext: userContext
        )
        let sut = NoraiEngineStateManager(state: initialState)
        
        let retrievedState = await sut.getState()
        
        #expect(retrievedState.isRunning == false)
        #expect(retrievedState.sessionId == sessionId)
        #expect(retrievedState.lastScreen == "ComplexScreen")
        #expect(retrievedState.funnelStep == "complex-step")
        #expect(retrievedState.userContext?.id == "complex-user")
        #expect(retrievedState.userContext?.firstName == "Complex")
        #expect(retrievedState.userContext?.email == "complex@test.com")
    }
} 