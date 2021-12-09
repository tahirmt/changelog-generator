//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetches pages
class ComparisonFetcher {
    let url: URL
    let pageSize: Int
    let session: URLSession
    let headers: [String: String]

    private let maximumNumberOfPages: Int?
    private let queryItems: [URLQueryItem]
    private var currentPage = 1

    fileprivate var intermediateResultHandler: ((Comparison) -> Bool)?

    // MARK: Initialization

    init(url: URL,
         headers: [String: String],
         params: [String: String],
         pageSize: Int = 100,
         maximumNumberOfPages: Int? = nil,
         session: URLSession = .shared) {
        self.url = url
        self.pageSize = pageSize
        self.session = session
        self.headers = headers
        self.queryItems = params.map {
            URLQueryItem(name: $0, value: $1)
        }
        self.maximumNumberOfPages = maximumNumberOfPages
    }

    /// Fetches all pages until no more data is available
    /// - Parameter intermediateResultHandler: When set this will get the result after every page fetch. Return true to fetch next page otherwise the load operation will end immediately
    func fetchAllPages(intermediateResultHandler: ((Comparison) -> Bool)? = nil) async throws -> Comparison {
        var page = 1
        let shouldFetchNextPageValue: (Comparison?, Int) -> Bool = { comparison, currentPage in
            guard let comparison = comparison else {
                // there is no data so we haven't fetched anything yet
                return true
            }

            if comparison.commits.count < self.pageSize || comparison.commits.count == comparison.totalCommits {
                // we have fetched all pages
                return false
            }
            else if let maxPages = self.maximumNumberOfPages, currentPage >= maxPages {
                // the maximum number of pages have been fetched
                return false
            }
            else {
                // check wether we should fetch the next page
                return intermediateResultHandler?(comparison) ?? true
            }
        }

        var finalResult: Comparison?
        var shouldFetch = shouldFetchNextPageValue(finalResult, page)
        while shouldFetch {
            let pageResult = try await fetch(page: page)
            if finalResult == nil {
                finalResult = pageResult
            }
            else {
                finalResult?.commits.append(contentsOf: pageResult.commits)
            }

            shouldFetch = shouldFetchNextPageValue(finalResult, page)
            page += 1
        }

        if let finalResult = finalResult {
            return finalResult
        }

        throw APIError.badData
    }

    /// Fetch the given page
    /// - Parameters:
    ///   - page: page number to fetch
    func fetch(page: Int) async throws -> Comparison {
        let queryItems = [
            URLQueryItem(name: "per_page", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        return try await fetchFromFetcher(additionalParams: queryItems)
    }

    fileprivate func fetchFromFetcher<Data: Decodable>(additionalParams: [URLQueryItem] = []) async throws -> Data {
        let fetcher = Fetcher<Data>(url: url, headers: headers, queryItems: queryItems + additionalParams, session: session)
        return try await fetcher.fetch()
    }
}
