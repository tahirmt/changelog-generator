//
//  Fetcher.swift
//
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum APIError: Error, Equatable {
    case decodingError(Error)
    case error(Error)
    case invalidUrl
    case badData
    case unknown
    case notFound

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.notFound, .notFound),
             (.unknown, .unknown),
             (.badData, .badData),
             (.invalidUrl, .invalidUrl),
             (.error, .error),
             (.decodingError, .decodingError):
            return true
        default:
            return false
        }
    }
}

/// Fetches any decodable object from the given url
struct Fetcher<Data: Decodable> {
    private let url: URL
    private let session: URLSession
    private let headers: [String: String]
    private let queryItems: [URLQueryItem]

    // MARK: Initialization

    init(url: URL,
         headers: [String: String],
         params: [String: String],
         session: URLSession = .shared) {
        self.init(
            url: url,
            headers: headers,
            queryItems: params.map {
                URLQueryItem(name: $0, value: $1)
            },
            session: session
        )
    }

    init(url: URL,
         headers: [String: String],
         queryItems: [URLQueryItem],
         session: URLSession = .shared) {
        self.url = url
        self.session = session
        self.headers = headers
        self.queryItems = queryItems
    }

    // MARK: Fetcher

    func fetch() async throws -> Data {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidUrl
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIError.invalidUrl
        }

        var request = URLRequest(url: url)
        headers.forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        Logger.log(level: .verbose, "Fetch data from", url)

        let (data, response) = try await session.dataAsync(for: request)

        if let urlResponse = response as? HTTPURLResponse, urlResponse.statusCode == 404 {
            Logger.log(level: .verbose, "404 - not found at", url)
            throw APIError.notFound
        }

        Logger.log(level: .verbose, "received")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.formatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let decodedValue = try decoder.decode(Data.self, from: data)

        if let readableValue = decodedValue as? UserReadable {
            Logger.log(level: .verbose, readableValue.userReadableString)
        }

        return decodedValue
    }
}
