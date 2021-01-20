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

final class GitHubSpec: QuickSpec {
    override func spec() {
        describe("a GitHub") {
            var subject: GitHub!

            beforeEach {
                subject = GitHub(owner: "umbrellacorp", repo: "virus", token: "1234567", params: ["id": "123"])
            }

            it("should fetch all pages") {
                MockURLProtocol.responseJsonFiles = [
                    "pull_requests_1", "pull_requests_2", "pull_requests_3", "pull_requests_4"
                ]

                var result: Result<[PullRequest], APIError>?

                subject.fetch(from: .pulls) { (pullsResult: Result<[PullRequest], APIError>) in
                    result = pullsResult
                }

                expect(result).toEventuallyNot(beNil())
                expect {
                    _ = try result?.get()
                }.toNot(throwError())

                let pulls = try? result?.get()

                expect(pulls?.count) == 315
            }

            it("should fetch first properly") {
                MockURLProtocol.responseJsonFiles = [
                    "pull_requests_1", "pull_requests_2", "pull_requests_3", "pull_requests_4"
                ]

                var result: Result<[PullRequest], APIError>?

                subject.fetchFirst(from: .pulls) { (pullsResult: Result<[PullRequest], APIError>) in
                    result = pullsResult
                }

                expect(result).toEventuallyNot(beNil())
                expect {
                    _ = try result?.get()
                }.toNot(throwError())

                let pulls = try? result?.get()

                expect(MockURLProtocol.requestsCalled.first?.url?.absoluteString.contains("per_page=1")) == true

                // while it requests 1, since our data returns 100 it will have 100
                expect(pulls?.count) == 100
                expect(pulls?.first?.number) == 4654
            }

            it("should fetch release properly") {
                MockURLProtocol.responseJsonFiles = [
                    "release",
                ]

                var result: Result<Release, APIError>?

                subject.fetchLatestRelease { releaseResult in
                    result = releaseResult
                }

                expect(result).toEventuallyNot(beNil())
                expect {
                    _ = try result?.get()
                }.toNot(throwError())

                let release = try? result?.get()

                expect(release?.id) == 25663630
            }

            it("should search pull requests properly") {
                MockURLProtocol.responseJsonFiles = [
                    "pull_request_search_1",
                    "pull_request_search_2",
                ]

                var result: Result<[PullRequest], APIError>?

                subject.fetchPullRequests(mergedAfter: Date()) {
                    result = $0
                }

                expect(result).toEventuallyNot(beNil())
                expect {
                    _ = try result?.get()
                }.toNot(throwError())

                let pulls = try? result?.get()

                expect(pulls?.count) == 188
            }
        }
    }
}
