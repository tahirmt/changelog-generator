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
                subject = GitHub(repository: "umbrellacorp/virus", token: "1234567", params: ["id": "123"])
            }

            it("should fetch all pages") {
                MockURLProtocol.responseJsonFiles = [
                    "pull_requests_1", "pull_requests_2", "pull_requests_3", "pull_requests_4"
                ]

                let pulls: [PullRequest] = try awaitAsync {
                    try await subject.fetch(from: .pulls)
                }

                expect(pulls.count) == 315
            }

            it("should fetch first properly") {
                MockURLProtocol.responseJsonFiles = [
                    "pull_requests_1", "pull_requests_2", "pull_requests_3", "pull_requests_4"
                ]

                let pulls: [PullRequest] = try awaitAsync {
                    try await subject.fetchFirst(from: .pulls)
                }

                expect(MockURLProtocol.requestsCalled.first?.url?.absoluteString.contains("per_page=1")) == true

                // while it requests 1, since our data returns 100 it will have 100
                expect(pulls.count) == 100
                expect(pulls.first?.number) == 4654
            }

            it("should fetch release properly") {
                MockURLProtocol.responseJsonFiles = [
                    "release",
                ]

                let release: Release = try awaitAsync {
                    try await subject.fetchLatestRelease()
                }

                expect(release.id) == 25663630
            }

            it("should search pull requests properly") {
                MockURLProtocol.responseJsonFiles = [
                    "pull_request_search_1",
                    "pull_request_search_2",
                ]

                let pulls: [PullRequest] = try awaitAsync {
                    try await subject.fetchPullRequests(mergedAfter: Date())
                }

                expect(pulls.count) == 188
            }
        }
    }
}
