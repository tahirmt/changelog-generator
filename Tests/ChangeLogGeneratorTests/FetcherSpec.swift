//
//  FetcherSpec.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-20.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Quick
import Nimble

@testable import ChangeLogGenerator

final class FetcherSpec: QuickSpec {
    override func spec() {
        describe("a Fetcher") {
            let placeholderError = NSError(domain: "", code: 0, userInfo: nil)
            var subject: Fetcher<MockStruct>!

            beforeEach {
                subject = Fetcher<MockStruct>(
                    url: URL(string: "http://notaurl.com")!,
                    headers: ["headerkey": "value"],
                    queryItems: [URLQueryItem(name: "q", value: "v")])
            }

            it("should have correct url") {
                _ = try? awaitAsync {
                    try await subject.fetch()
                }

                expect(MockURLProtocol.requestsCalled).toEventuallyNot(beEmpty())

                let request = MockURLProtocol.requestsCalled.first

                expect(request?.url?.absoluteString) == "http://notaurl.com?q=v"
                expect(request?.allHTTPHeaderFields) == [
                    "headerkey": "value"
                ]
            }

            it("should initialize correctly with params dictionary") {
                subject = Fetcher<MockStruct>(
                    url: URL(string: "http://notaurl.com")!,
                    headers: ["headerkey": "value"],
                    params: ["q": "v"])

                _ = try? awaitAsync {
                    try await subject.fetch()
                }

                expect(MockURLProtocol.requestsCalled).toEventuallyNot(beEmpty())

                let request = MockURLProtocol.requestsCalled.first

                expect(request?.url?.absoluteString) == "http://notaurl.com?q=v"
                expect(request?.allHTTPHeaderFields) == [
                    "headerkey": "value"
                ]
            }

            func expectResultEqual(_ expectedResult: Result<MockStruct, APIError>, file: FileString = #file, line: UInt = #line) throws {
                let result: Result<MockStruct, APIError>

                do {
                    let data = try awaitAsync {
                        try await subject.fetch()
                    }

                    result = .success(data)
                }
                catch let error as APIError {
                    result = .failure(error)
                }
                catch {
                    throw error
                }

                switch (result, expectedResult) {
                case (.failure(let lhs), .failure(let rhs)):
                    expect(lhs) == rhs
                case (.success(let lhs), .success(let rhs)):
                    expect(lhs) == rhs
                default:
                    fail("result is not equal")
                }
            }

            it("should parse data properly") {
                MockURLProtocol.responseData = [
                    """
                {
                    "value": "Hello"
                }
                """.data(using: .utf8)!
                ]

                try expectResultEqual(.success(MockStruct(value: "Hello")))
            }

            it("should return parsing error if invalid data") {
                MockURLProtocol.responseData = [
                    """
                {
                    "somethingelse": "Hello"
                }
                """.data(using: .utf8)!
                ]

                do {
                    try expectResultEqual(.failure(.decodingError(placeholderError)))
                    fail("expected failure")
                }
                catch let DecodingError.keyNotFound(key, _) {
                    expect(key.stringValue) == "value"
                }
                catch {
                    throw error
                }
            }

            it("should return correct error if not found") {
                MockURLProtocol.requestHandler = { _ in
                    (404, Data())
                }

                try expectResultEqual(.failure(.notFound))
            }
        }
    }
}

struct MockStruct: Decodable, Equatable {
    let value: String
}
