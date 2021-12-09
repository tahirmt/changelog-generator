//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-21.
//

import Foundation
import Quick
import Nimble

@testable import ChangeLogGenerator

final class SearchResultsFetcherSpec: QuickSpec {
    override func spec() {
        describe("a SearchResultsFetcher") {
            var subject: SearchResultsFetcher<MockStruct>!

            beforeEach {
                var mockData: [Data] = []

                (0..<8).forEach {
                    mockData.append("""
                        {
                            "total_count": 17,
                            "incomplete_results": true,
                            "items": [
                                {
                                    "value": "Hello \($0)"
                                },
                                {
                                    "value": "World \($0)"
                                }
                            ]
                        }
                        """.data(using: .utf8)!)
                }

                mockData.append("""
                        {
                            "total_count": 17,
                            "incomplete_results": false,
                            "items": [
                                {
                                    "value": "Hello 9"
                                }
                            ]
                        }
                    """.data(using: .utf8)!)

                MockURLProtocol.responseData = mockData
            }

            context("when fetching all pages") {
                beforeEach {
                    subject = SearchResultsFetcher<MockStruct>(url: URL(string: "http://notaurl.com")!, headers: ["k": "v"], params: ["q": "val"], pageSize: 2)
                }

                it("should load all pages") {
                    let data: [MockStruct] = try awaitAsync {
                        try await subject.fetchAllPages()
                    }

                    expect(data.count) == 17
                }

                it("should fail if a page isn't fetched") {
                    MockURLProtocol.responseData = []

                    MockURLProtocol.requestHandler = { _ in
                        (404, Data())
                    }

                    do {
                        let _: [MockStruct] = try awaitAsync {
                            try await subject.fetchAllPages()
                        }
                        fail("expected failure")
                    }
                    catch let error as APIError {
                        expect(error) == .notFound
                    }
                    catch {
                        fail(error.localizedDescription)
                    }
                }
            }

            context("when fetching pages with a limit") {
                beforeEach {
                    subject = SearchResultsFetcher<MockStruct>(url: URL(string: "http://notaurl.com")!, headers: ["k": "v"], params: ["q": "val"], pageSize: 2, maximumNumberOfPages: 2)
                }

                it("should load pages") {
                    let data: [MockStruct] = try awaitAsync {
                        try await subject.fetchAllPages()
                    }

                    expect(data.count) == 4
                }
            }

            context("when intermediate result handler is used") {
                beforeEach {
                    subject = SearchResultsFetcher<MockStruct>(url: URL(string: "http://notaurl.com")!, headers: ["k": "v"], params: ["q": "val"], pageSize: 2)
                }

                it("should load all pages") {
                    let data: [MockStruct] = try awaitAsync {
                        try await subject.fetchAllPages { $0.count < 6 }
                    }

                    expect(data.count) == 6
                }
            }
        }
    }
}

