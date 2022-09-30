//
//  GitHub.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct GitHub {
    enum Endpoint {
        case pulls
        case tags
        case releases
        case search
        case compare(String, String)
        case issues
        case milestones

        var path: String {
            switch self {
            case .pulls:
                return "pulls"
            case .tags:
                return "tags"
            case .releases:
                return "releases"
            case .search:
                return "search"
            case .compare:
                return "compare"
            case .issues:
                return "issues"
            case .milestones:
                return "milestones"
            }
        }
    }

    // MARK: Properties

    let base = "https://api.github.com"
    let repository: String
    let token: String?
    private(set) var params: [String: String] = [:]
    private(set) var session: URLSession = .shared

    private var headers: [String: String] {
        guard let token = token else { return [:] }

        return [
            "Authorization": "token \(token)",
            "Accept": "application/vnd.github.v3+json",
        ]
    }
}

// MARK: Helper

extension GitHub {
    private func createBaseUrl(for endpoint: Endpoint) throws -> URL {
        guard let url = URL(string: createBaseUrl(for: endpoint)) else {
            throw APIError.invalidUrl
        }
        return url
    }

    private func createBaseUrl(for endpoint: Endpoint) -> String {
        switch endpoint {
        case .pulls, .tags, .releases, .issues, .milestones:
            return [
                base,
                "repos",
                repository,
                endpoint.path,
            ].joined(separator: "/")
        case .search:
            return [
                base,
                endpoint.path,
                "issues",
            ].joined(separator: "/")
        case .compare(let base, let head):
            return [
                self.base,
                "repos",
                repository,
                endpoint.path,
                "\(base)...\(head)",
            ].joined(separator: "/")
        }
    }
}

// MARK: - Async/Await

extension GitHub {
    /// Fetches all pages from the given endpoint
    /// - Parameters:
    ///   - endpoint: the endpoint to fetch from
    ///   - maximumNumberOfPages: maximum number of pages to fetch
    ///   - intermediateResultHandler: return true if the next page should be loaded.
    func fetch<T: Decodable>(from endpoint: Endpoint,
                             maximumNumberOfPages: Int? = nil,
                             intermediateResultHandler: (([T]) -> Bool)? = nil) async throws -> [T] {
        let url: URL = try createBaseUrl(for: endpoint)
        let fetcher = PaginationFetcher<T>(url: url,
                                           headers: headers,
                                           params: params,
                                           maximumNumberOfPages: maximumNumberOfPages,
                                           session: session)
        return try await fetcher.fetchAllPages(intermediateResultHandler: intermediateResultHandler)
    }

    /// Fetch the data from the given url. The decoding of the type is done internally
    /// - Parameters:
    ///   - url: url to fetch from
    func fetch<T: Decodable>(from url: URL) async throws -> T {
        let fetcher = Fetcher<T>(url: url,
                                 headers: headers,
                                 params: params,
                                 session: session)
        return try await fetcher.fetch()
    }

    /// Fetch the first item of the first page
    /// - Parameters:
    ///   - endpoint: endpoint to fetch from
    func fetchFirst<T: Decodable>(from endpoint: Endpoint) async throws -> [T] {
        let url: URL = try createBaseUrl(for: endpoint)
        let fetcher = PaginationFetcher<T>(url: url,
                                           headers: headers,
                                           params: params,
                                           pageSize: 1,
                                           session: session)

        return try await fetcher.fetch(page: 1)
    }

    /// Fetches the latest release from github
    func fetchLatestRelease() async throws -> Release {
        let url: URL = try createBaseUrl(for: .releases)
        return try await fetch(from: url.appendingPathComponent("latest"))
    }

    /// Fetch pull requests merged after the given date
    /// - Parameters:
    ///   - date: date to fetch pull requests after
    func fetchPullRequests(mergedAfter date: Date, maximumNumberOfPages: Int? = nil) async throws -> [PullRequest] {
        let url: URL = try createBaseUrl(for: .search)
        let query = [
            "repo:\(repository)",
            "is:pr",
            "is:merged",
            "merged:>=\(DateFormatter.formatter.string(from: date))"
        ]
        .joined(separator: "+")

        var params = self.params
        params["q"] = query

        let fetcher = SearchResultsFetcher<PullRequest>(
            url: url,
            headers: headers,
            params: params,
            maximumNumberOfPages: maximumNumberOfPages,
            session: session)
        return try await fetcher.fetchAllPages()
    }

    /// Fetch comparison between two refs
    /// - Parameters:
    ///   - base: the base ref. It can be a branch, tag or sha
    ///   - head: the head ref. It can be a branch, tag or sha
    ///   - maximumNumberOfPages: The maximum number of pages to fetch
    func fetchComparison(from base: String, to head: String, maximumNumberOfPages: Int? = nil) async throws -> Comparison {
        let url: URL = try createBaseUrl(for: .compare(base, head))
        Logger.log(level: .verbose, "Fetching comparison from \(url)")
        let fetcher = ComparisonFetcher(
            url: url,
            headers: headers,
            params: params,
            maximumNumberOfPages: maximumNumberOfPages,
            session: session)

        return try await fetcher.fetchAllPages()
    }
}
