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
class PaginationFetcher<T: Decodable> {
    let url: URL
    let pageSize: Int
    let session: URLSession
    let headers: [String: String]

    private let maximumNumberOfPages: Int?
    private let queryItems: [URLQueryItem]

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

    // MARK: Async/Await

    func fetchAllPages(intermediateResultHandler: (([T]) -> Bool)? = nil) async throws -> [T] {
        var page = 1
        let shouldFetchNextPageValue: ([T], [T]?, Int) -> Bool = { allData, pageData, currentPage in
            guard let data = pageData else {
                // there is no data so we haven't fetched anything yet
                return true
            }

            if data.count < self.pageSize {
                // received data is less than page size. Reached the end
                return false
            }
            else if let maxPages = self.maximumNumberOfPages, currentPage >= maxPages {
                // the maximum number of pages have been fetched
                return false
            }
            else {
                // check wether we should fetch the next page
                return intermediateResultHandler?(allData) ?? true
            }
        }

        var allData = [T]()
        var shouldFetch = shouldFetchNextPageValue(allData, nil, page)
        while shouldFetch {
            let pageResult = try await fetch(page: page)
            allData.append(contentsOf: pageResult)
            shouldFetch = shouldFetchNextPageValue(allData, pageResult, page)
            page += 1
        }

        return allData
    }

    func fetch(page: Int) async throws -> [T] {
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

// MARK: - SearchResultsFetcher

/// A fetcher for search results
final class SearchResultsFetcher<T: Decodable>: PaginationFetcher<T> {
    override func fetch(page: Int) async throws -> [T] {
        let queryItems = [
            URLQueryItem(name: "per_page", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        let result: SearchResult<T> = try await fetchFromFetcher(additionalParams: queryItems)
        return result.items
    }
}
