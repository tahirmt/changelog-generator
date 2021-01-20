//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-20.
//

import Foundation
import Quick

enum MockURLProtocolError: Error {
    case noUrl
    case notSet
}

class MockURLProtocol: URLProtocol {

    /// Handler will be called for every request
    static var requestHandler: ((URLRequest) throws -> (Int, Data) )?

    /// If `requestHandler` is not to be used, use this array
    static var responseData: [Data] = []
    static var responseJsonFiles: [String] = [] {
        didSet {
            responseData = responseJsonFiles.compactMap { (fileName: String) -> Data? in
                Bundle.module.url(forResource: fileName, withExtension: "json")
                    .map {
                        try? Data(contentsOf: $0)
                    } as? Data
            }
        }
    }

    /// When set the response will be taken based on the url
    static var responseJsonForURL: [URL: String] = [:]

    static var requestsCalled: [URLRequest] = []

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func stopLoading() {}

    override func startLoading() {
        Self.requestsCalled.append(request)

        guard let requestUrl = request.url else {
            client?.urlProtocol(self, didFailWithError: MockURLProtocolError.noUrl)
            return
        }

        if Self.responseJsonForURL.isEmpty == false,
           let json = Self.responseJsonForURL[requestUrl],
           let fileUrl = Bundle.module.url(forResource: json, withExtension: "json"),
           let jsonData = try? Data(contentsOf: fileUrl),
           let response = HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: nil, headerFields: nil) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: jsonData)
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        if Self.responseData.isEmpty == false, let response = HTTPURLResponse(url: requestUrl, statusCode: 200, httpVersion: nil, headerFields: nil) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Self.responseData.removeFirst())
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: MockURLProtocolError.notSet)
            return
        }

        do {
            let (code, data)  = try handler(request)
            let response = HTTPURLResponse(url: requestUrl, statusCode: code, httpVersion: nil, headerFields: nil)!

            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch  {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

final class URLProtocolConfig: QuickConfiguration {
    override class func configure(_ configuration: Configuration) {
        configuration.beforeSuite {
            // We need to register the custom URLProtocol so the URL
            // loading system knows about it.
            URLProtocol.registerClass(MockURLProtocol.self)
        }

        configuration.afterEach {
            MockURLProtocol.requestHandler = nil
            MockURLProtocol.responseData = []
            MockURLProtocol.requestsCalled = []
        }
    }
}
