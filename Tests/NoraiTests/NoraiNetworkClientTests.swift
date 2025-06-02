//
//  NoraiNetworkClientTests.swift
//  Norai
//
//  Created by Amr on 29/05/2025.
//

import Foundation
import Testing
@testable import Norai

struct NoraiNetworkClientTests {

    @Test func executeCallsDataForTask() async throws {
        let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.someData,
                                            mockURLResponse: MockEndPoint.validResponse)
        let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                         middlewareExecutor: MockedMiddlewareExecutor())
        let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        #expect(mockURLSession.didCallDataForURLRequest == true)
    }
    
    @Test func executeThrowsErrorOnInvalidURL() async throws {
        await #expect(throws: NoraiNetworkError.invalidURL) {
            let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.someData,
                                                                mockURLResponse: MockEndPoint.validResponse)
            let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                             middlewareExecutor: MockedMiddlewareExecutor())
            let _: MockResponse = try await sut.execute(MockEndPoint.invalidURLEndPoint)
        }
    }
    
    @Test func executeThrowsNetworkFailure() async throws {
        await #expect(throws: NoraiNetworkError.networkFailure(
            underlyingError: "The operation couldn’t be completed. (TestDomain error 1234.)")) {
                let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: makeMockFailingSession(),
                                                                 middlewareExecutor: MockedMiddlewareExecutor())
            let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        }
    }
    
    @Test func executeThrowsNoDataErrorOnNoDataResponse() async throws {
        await #expect(throws: NoraiNetworkError.noData.self) {
            let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.emptyData,
                                                                mockURLResponse: MockEndPoint.validResponse)
            let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                             middlewareExecutor: MockedMiddlewareExecutor())
            let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        }
    }
    
    @Test func executeThrowsInvalidResponseErrorOnReceivingInvalidResponse() async throws {
        await #expect(throws: NoraiNetworkError.invalidResponse.self) {
            let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.someData,
                                                                mockURLResponse: MockEndPoint.invalidResponse)
            let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                             middlewareExecutor: MockedMiddlewareExecutor())
            let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        }
    }
    
    @Test func executeThrowsRequestFailedErrorOnReceivingNon2xxStatusCode() async throws {
        await #expect(throws: NoraiNetworkError.requestFailed(statusCode: 304).self) {
            let mockURLSession: MockURLSession = MockURLSession(
                mockData: MockEndPoint.someData,
                mockURLResponse: MockEndPoint.invalidResponseWithStatus(code: 304)
            )
            let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                             middlewareExecutor: MockedMiddlewareExecutor())
            let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        }
    }
    
    @Test func executeThrowsDecodingErrorOnInvalidData() async throws {
        await #expect(throws: NoraiNetworkError.decodingError.self) {
            let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.invalidJSONData,
                                                                mockURLResponse: MockEndPoint.validResponse)
            let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                             middlewareExecutor: MockedMiddlewareExecutor())
            let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        }
    }
    
    @Test func executeCallsPreRequestsMiddlewares() async throws {
        let mockedMiddlewareExecutor = MockedMiddlewareExecutor()
        let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.someData,
                                            mockURLResponse: MockEndPoint.validResponse)
        let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                         middlewareExecutor: mockedMiddlewareExecutor)
        let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        #expect(mockedMiddlewareExecutor.isExecutePreRequestMiddlewaresCalled == true)
    }

    @Test func executeCallsPOSTResponseMiddlewares() async throws {
        let mockedMiddlewareExecutor = MockedMiddlewareExecutor()
        let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.someData,
                                            mockURLResponse: MockEndPoint.validResponse)
        let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                         middlewareExecutor: mockedMiddlewareExecutor)
        let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        #expect(mockedMiddlewareExecutor.isExecutePostResponseMiddlewaresCalled == true)
    }
    
    @Test func executeThrowsMandatoryMiddlewareFailure() async throws {
        await #expect(throws: NoraiNetworkError.mandatoryMiddlewareFailure(underlyingError: "The operation couldn’t be completed. (Norai.NoraiNetworkError error 2.)").self) {
            let mockedMiddlewareExecutor = MockedMiddlewareExecutor(middlewares: [MockedFailableMiddleware()])
            let mockURLSession: MockURLSession = MockURLSession(mockData: MockEndPoint.someData,
                                                mockURLResponse: MockEndPoint.validResponse)
            let sut: NoraiNetworkClient = NoraiNetworkClient(urlSession: mockURLSession,
                                                             middlewareExecutor: mockedMiddlewareExecutor)
            let _: MockResponse = try await sut.execute(MockEndPoint.mock)
        }
    }
}

extension NoraiNetworkClientTests {
    func makeMockFailingSession() -> URLSession {
        let config: URLSessionConfiguration = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockFailingURLProtocol.self]
        return URLSession(configuration: config)
    }
}
