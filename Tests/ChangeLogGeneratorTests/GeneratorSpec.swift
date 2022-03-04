//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-22.
//

import Foundation
import Quick
import Nimble

@testable import ChangeLogGenerator

final class GeneratorSpec: QuickSpec {
    override func spec() {
        describe("a Generator") {
            var subject: Generator!

            context("when fetching all pages") {
                beforeEach {
                    subject = try! Generator(
                        repository: "AFNetworking/AFNetworking",
                        token: nil,
                        labels: [],
                        excludedLabels: [],
                        filterRegEx: nil,
                        maximumNumberOfPages: nil,
                        nextTag: nil,
                        includeUntagged: true)
                }

                it("should generate correct changelog") {
                    MockURLProtocol.responseJsonForURL = [
                        URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=1")!: "pull_requests_1",
                        URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=2")!: "pull_requests_2",
                        URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=3")!: "pull_requests_3",
                        URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=4")!: "pull_requests_4",
                        URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/tags?per_page=100&page=1")!: "tags_1",
                        URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/tags?per_page=100&page=2")!: "tags_2",
                    ]

                    let changelog = try awaitAsync {
                        try await subject.generateCompleteChangeLog()
                    }

                    expect(changelog) == Bundle.module.url(forResource: "CHANGELOG", withExtension: "md").map {
                        try? String(contentsOf: $0)
                    }
                }

                it("should generate changelog since release") {
                    MockURLProtocol.responseJsonFiles = [
                        "release",
                        "pull_request_search_2"
                    ]

                    let changelog = try awaitAsync {
                        try await subject.generateChangeLogSinceLatestRelease()
                    }

                    expect(changelog) == Bundle.module.url(forResource: "CHANGELOG_release", withExtension: "md").map {
                        try? String(contentsOf: $0)
                    }
                }

                it("should generate changelog since given tag") {
                    MockURLProtocol.responseJsonFiles = [
                        "tags_1",
                        "pull_requests_1",
                        "pull_requests_2",
                        "pull_requests_3",
                        "pull_requests_4",
                    ]

                    let changelog = try awaitAsync {
                        try await subject.generateChangeLogSince(tag: "3.2.0")
                    }

                    expect(changelog) == Bundle.module.url(forResource: "CHANGELOG_tag", withExtension: "md").map {
                        try? String(contentsOf: $0)
                    }
                }
            }

            context("when initialized with token") {
                beforeEach {
                    subject = try! Generator(
                        repository: "AFNetworking/AFNetworking",
                        token: "123456789asdfghjkl",
                        labels: [],
                        excludedLabels: [],
                        filterRegEx: nil,
                        maximumNumberOfPages: nil,
                        nextTag: nil,
                        includeUntagged: true)
                }

                context("for complete changelog") {
                    it("should send token in headers") {
                        _ = try awaitAsync {
                            try await subject.generateCompleteChangeLog()
                        }

                        expect(MockURLProtocol.requestsCalled).toNot(beEmpty())

                        expect {
                            MockURLProtocol.requestsCalled
                                .allSatisfy {
                                    $0.allHTTPHeaderFields?["Authorization"] == "token 123456789asdfghjkl"
                                }
                        }.to(beTrue())
                    }
                }

                context("for latest release") {
                    it("should send token in headers") {
                        _ = try? awaitAsync {
                            try await subject.generateChangeLogSinceLatestRelease()
                        }

                        expect(MockURLProtocol.requestsCalled).toNot(beEmpty())

                        expect {
                            MockURLProtocol.requestsCalled
                                .allSatisfy {
                                    $0.allHTTPHeaderFields?["Authorization"] == "token 123456789asdfghjkl"
                                }
                        }.to(beTrue())
                    }
                }

                context("for since tag") {
                    it("should send token in headers") {
                        _ = try awaitAsync {
                            try await subject.generateChangeLogSince(tag: "3.2.0")
                        }

                        expect(MockURLProtocol.requestsCalled).toNot(beEmpty())

                        expect {
                            MockURLProtocol.requestsCalled
                                .allSatisfy {
                                    $0.allHTTPHeaderFields?["Authorization"] == "token 123456789asdfghjkl"
                                }
                        }.to(beTrue())
                    }
                }

                context("when filter regex is provided") {
                    beforeEach {
                        subject = try! Generator(
                            repository: "AFNetworking/AFNetworking",
                            token: nil,
                            labels: [],
                            excludedLabels: [],
                            filterRegEx: "Fixed CLANG_ENABLE_CODE_COVERAGE flag so release can be made",
                            maximumNumberOfPages: nil,
                            nextTag: nil,
                            includeUntagged: true)
                    }

                    it("should not include pull requests matching the regex") {
                        MockURLProtocol.responseJsonForURL = [
                            URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=1")!: "pull_requests_1",
                            URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=2")!: "pull_requests_2",
                            URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=3")!: "pull_requests_3",
                            URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/pulls?state=closed&per_page=100&page=4")!: "pull_requests_4",
                            URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/tags?per_page=100&page=1")!: "tags_1",
                            URL(string: "https://api.github.com/repos/AFNetworking/AFNetworking/tags?per_page=100&page=2")!: "tags_2",
                        ]

                        let changelog = try awaitAsync {
                            try await subject.generateCompleteChangeLog()
                        }

                        expect(changelog.contains("Fixed CLANG_ENABLE_CODE_COVERAGE flag so release can be made")).to(beFalse())
                    }
                }
            }

            it("should not initialize if repository name does not match format") {
                expect {
                    subject = try Generator(
                        repository: "hello",
                        token: nil,
                        labels: [],
                        excludedLabels: [],
                        filterRegEx: nil,
                        maximumNumberOfPages: nil,
                        nextTag: nil,
                        includeUntagged: true)
                }.to(throwError())
            }
        }
    }
}
