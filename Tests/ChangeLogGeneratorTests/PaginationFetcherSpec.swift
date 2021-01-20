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

final class PaginationFetcherSpec: QuickSpec {
    override func spec() {
        describe("a PaginationFetcher") {
            var subject: PaginationFetcher<MockStruct>!

            beforeEach {
                var mockData: [Data] = []

                (0..<8).forEach {
                    mockData.append("""
                        [
                            {
                                "value": "Hello \($0)"
                            },
                            {
                                "value": "World \($0)"
                            }
                        ]
                        """.data(using: .utf8)!)
                }

                mockData.append("""
                    [
                        {
                            "value": "Hello 9"
                        }
                    ]
                    """.data(using: .utf8)!)

                MockURLProtocol.responseData = mockData
            }

            context("when fetching all pages") {
                beforeEach {
                    subject = PaginationFetcher<MockStruct>(url: URL(string: "http://notaurl.com")!, headers: ["k": "v"], params: ["q": "val"], pageSize: 2)
                }

                it("should load all pages") {
                    var pageResult: Result<[MockStruct], APIError>?

                    subject.fetchAllPages { result in
                        pageResult = result
                    }

                    expect(pageResult).toEventuallyNot(beNil())

                    let data = try? pageResult?.get()

                    expect(data).toNot(beNil())
                    expect(data?.count) == 17
                }

                it("should fail if a page isn't fetched") {
                    MockURLProtocol.responseData = []

                    MockURLProtocol.requestHandler = { _ in
                        (404, Data())
                    }

                    var pageResult: Result<[MockStruct], APIError>?

                    subject.fetchAllPages { result in
                        pageResult = result
                    }

                    expect(pageResult).toEventuallyNot(beNil())

                    switch pageResult! {
                    case .success:
                        fail("expected failure")
                    case .failure(let error):
                        expect(error) == .notFound
                    }
                }
            }

            context("when fetching pages with a limit") {
                beforeEach {
                    subject = PaginationFetcher<MockStruct>(url: URL(string: "http://notaurl.com")!, headers: ["k": "v"], params: ["q": "val"], pageSize: 2, maximumNumberOfPages: 2)
                }

                it("should load pages") {
                    var pageResult: Result<[MockStruct], APIError>?

                    subject.fetchAllPages { result in
                        pageResult = result
                    }

                    expect(pageResult).toEventuallyNot(beNil())

                    let data = try? pageResult?.get()

                    expect(data).toNot(beNil())
                    expect(data?.count) == 4
                }
            }

            context("when intermediate result handler is used") {
                beforeEach {
                    subject = PaginationFetcher<MockStruct>(url: URL(string: "http://notaurl.com")!, headers: ["k": "v"], params: ["q": "val"], pageSize: 2)
                }

                it("should load all pages") {
                    var pageResult: Result<[MockStruct], APIError>?

                    subject.fetchAllPages { (result) -> Bool in
                        result.count < 6
                    } completionHandler: { result in
                        pageResult = result
                    }

                    expect(pageResult).toEventuallyNot(beNil())

                    let data = try? pageResult?.get()

                    expect(data).toNot(beNil())
                    expect(data?.count) == 6
                }
            }
        }
    }
}
