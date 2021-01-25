//
//  GitHub.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

struct GitHub {
    enum Endpoint: String {
        case pulls
        case tags
        case releases
        case search
    }

    // MARK: Properties

    let base = "https://api.github.com"
    let repository: String
    let token: String?
    private(set) var params: [String: String] = [:]
    private(set) var session: URLSession = .shared

    private var headers: [String: String] {
        guard let token = token else { return [:] }

        return ["Authorization": "token \(token)"]
    }

    // MARK: Helper

    private func createBaseUrl(for endpoint: Endpoint) -> String {
        switch endpoint {
        case .pulls, .tags, .releases:
            return [
                base,
                "repos",
                repository,
                endpoint.rawValue,
            ].joined(separator: "/")
        case .search:
            return [
                base,
                endpoint.rawValue,
                "issues"
            ].joined(separator: "/")
        }
    }

    /// Fetches all pages from the given endpoint
    /// - Parameters:
    ///   - endpoint: the endpoint to fetch from
    ///   - maximumNumberOfPages: maximum number of pages to fetch
    ///   - intermediateResultHandler: return true if the next page should be loaded.
    ///   - completionHandler: will be called with the result of all pages once
    func fetch<T: Decodable>(from endpoint: Endpoint, maximumNumberOfPages: Int? = nil,
                             intermediateResultHandler: (([T]) -> Bool)? = nil,
                             completionHandler: @escaping (Result<[T], APIError>) -> Void) {
        guard let url = URL(string: createBaseUrl(for: endpoint)) else {
            completionHandler(.failure(.invalidUrl))
            return
        }

        let fetcher = PaginationFetcher<T>(url: url,
                                           headers: headers,
                                           params: params,
                                           maximumNumberOfPages: maximumNumberOfPages,
                                           session: session)
        fetcher.fetchAllPages(intermediateResultHandler: intermediateResultHandler, completionHandler: completionHandler)
    }

    /// Fetch the data from the given url. The decoding of the type is done internally
    /// - Parameters:
    ///   - url: url to fetch from
    ///   - completionHandler: will be called with the parsed object or error
    func fetch<T: Decodable>(from url: URL,
                             completionHandler: @escaping (Result<T, APIError>) -> Void) {
        let fetcher = Fetcher<T>(url: url,
                                 headers: headers,
                                 params: params,
                                 session: session)
        do {
            try fetcher.fetch(completionHandler: completionHandler)
        }
        catch let error as APIError {
            completionHandler(.failure(error))
        }
        catch  {
            completionHandler(.failure(.error(error)))
        }
    }

    /// Fetch the first item of the first page
    /// - Parameters:
    ///   - endpoint: endpoint to fetch from
    ///   - completionHandler: will be called with an array of one item or empty
    func fetchFirst<T: Decodable>(from endpoint: Endpoint, completionHandler: @escaping (Result<[T], APIError>) -> Void) {
        guard let url = URL(string: createBaseUrl(for: endpoint)) else {
            completionHandler(.failure(.invalidUrl))
            return
        }

        let fetcher = PaginationFetcher<T>(url: url,
                                           headers: headers,
                                           params: params,
                                           pageSize: 1,
                                           session: session)

        fetcher.fetch(page: 1, completionHandler: completionHandler)
    }

    /// Fetches the latest release from github
    func fetchLatestRelease(completionHandler: @escaping (Result<Release, APIError>) -> Void) {
        guard let url = URL(string: createBaseUrl(for: .releases)) else {
            completionHandler(.failure(.invalidUrl))
            return
        }

        fetch(from: url.appendingPathComponent("latest"), completionHandler: completionHandler)
    }

    /// Fetch pull requests merged after the given date
    /// - Parameters:
    ///   - date: date to fetch pull requests after
    ///   - completionHandler: will be called with the result
    func fetchPullRequests(mergedAfter date: Date, maximumNumberOfPages: Int? = nil, completionHandler: @escaping (Result<[PullRequest], APIError>) -> Void) {
        guard let url = URL(string: createBaseUrl(for: .search)) else {
            completionHandler(.failure(.invalidUrl))
            return
        }

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
        fetcher.fetchAllPages(completionHandler: completionHandler)
    }
}
