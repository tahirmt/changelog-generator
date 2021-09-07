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
    private var currentPage = 1

    fileprivate var allObjects: [T] = []
    fileprivate var resultHandler: ((Result<[T], APIError>) -> Void)?
    fileprivate var intermediateResultHandler: (([T]) -> Bool)?

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
    /// - Parameter completionHandler: will be called with all the pages or error if any of the requests fail
    /// - Parameter intermediateResultHandler: When set this will get the result after every page fetch. Return true to fetch next page otherwise the load operation will end immediately
    func fetchAllPages(intermediateResultHandler: (([T]) -> Bool)? = nil, completionHandler: @escaping (Result<[T], APIError>) -> Void) {
        resultHandler = completionHandler
        self.intermediateResultHandler = intermediateResultHandler

        fetchNextPage()
    }

    /// Fetch the given page
    /// - Parameters:
    ///   - page: page number to fetch
    ///   - completionHandler: will be called with an array of result
    func fetch(page: Int, completionHandler: @escaping (Result<[T], APIError>) -> Void) {
        let queryItems = [
            URLQueryItem(name: "per_page", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        fetchFromFetcher(additionalParams: queryItems, completionHandler: completionHandler)
    }

    // MARK: - Private

    private func fetchNextPage() {
        fetch(page: currentPage) { result in
            switch result {
            case .failure(let error):
                Logger.log("got failure \(error)")
                self.finish(error: error)
            case .success(let data):
                self.allObjects.append(contentsOf: data)

                if data.count < self.pageSize {
                    self.finish()
                }
                else if let maxPages = self.maximumNumberOfPages, self.currentPage >= maxPages {
                    self.finish()
                }
                else {
                    if self.intermediateResultHandler?(self.allObjects) ?? true {
                        self.currentPage += 1
                        self.fetchNextPage()
                    }
                    else {
                        self.finish()
                    }
                }
            }
        }
    }

    private func finish(error: APIError? = nil) {
        if let error = error {
            resultHandler?(.failure(error))
        }
        else {
            resultHandler?(.success(allObjects))
        }

        currentPage = 1
        allObjects = []
        resultHandler = nil
    }

    fileprivate func fetchFromFetcher<Data: Decodable>(additionalParams: [URLQueryItem] = [], completionHandler: @escaping (Result<Data, APIError>) -> Void) {
        let fetcher = Fetcher<Data>(url: url, headers: headers, queryItems: queryItems + additionalParams, session: session)

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
}

// MARK: - SearchResultsFetcher

/// A fetcher for search results
final class SearchResultsFetcher<T: Decodable>: PaginationFetcher<T> {
    override func fetch(page: Int, completionHandler: @escaping (Result<[T], APIError>) -> Void) {
        let queryItems = [
            URLQueryItem(name: "per_page", value: "\(pageSize)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        fetchFromFetcher(additionalParams: queryItems) { (result: Result<SearchResult<T>, APIError>) in
            completionHandler(result.map { $0.items })
        }
    }
}
