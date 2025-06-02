//
//  MiddlewareExecutorTests.swift
//  Norai
//
//  Created by Amr on 02/06/2025.
//

import Foundation
import Testing
import Norai

struct MiddlewareExecutorTests {

    @Test func executePreRequestMiddlewaresCallsProcessRequests() async throws {
        let mockedMiddleware = MockedMiddleware()
        let sut = MiddlewareExecutor(middlewares: [mockedMiddleware])
        _ = try await sut.executePreRequestMiddlewares(for: MockEndPoint.mockURLResquest)
        #expect(mockedMiddleware.isProcessRequestCalled == true)
    }
    
    @Test func executePostResponseMiddlewaresCallsProcessResponse() async throws {
        let mockedMiddleware = MockedMiddleware(type: .POST)
        let sut = MiddlewareExecutor(middlewares: [mockedMiddleware])
        _ = try await sut.executePostResponseMiddlewares(with: MockEndPoint.validResponse,
                                                         for: MockEndPoint.mockURLResquest)
        #expect(mockedMiddleware.isProcessResponseCalled == true)
    }
    
    @Test func executePreRequestMiddlewaresThrowsMandatoryMiddlewareFailure() async {
        await #expect(
            throws: NoraiNetworkError.mandatoryMiddlewareFailure(
                underlyingError: "The operation couldn’t be completed. (Norai.NoraiNetworkError error 2.)")
        ) {
            let mockedMiddleware = MockedFailableMiddleware()
            let sut = MiddlewareExecutor(middlewares: [mockedMiddleware])
            _ = try await sut.executePreRequestMiddlewares(for: MockEndPoint.mockURLResquest)
        }
    }

    @Test func executePostResponseMiddlewaresThrowsMandatoryMiddlewareFailure() async {
        await #expect(
            throws: NoraiNetworkError.mandatoryMiddlewareFailure(
                underlyingError: "The operation couldn’t be completed. (Norai.NoraiNetworkError error 2.)")
        ) {
            let mockedMiddleware = MockedFailableMiddleware(type: .POST)
            let sut = MiddlewareExecutor(middlewares: [mockedMiddleware])
            _ = try await sut.executePostResponseMiddlewares(with: MockEndPoint.validResponse,
                                                             for: MockEndPoint.mockURLResquest)
        }
    }
}
