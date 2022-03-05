//
//  URL+Equivalent.swift
//  
//
//  Created by Mahmood Tahir on 2022-03-05.
//

import Foundation

extension URL {
    /// Compare the two urls factoring in the query parameters having different orders
    func isEquivalent(to other: URL) -> Bool {
        let components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let otherComponents = URLComponents(url: other, resolvingAgainstBaseURL: false)
        return components.isEquivalent(to: otherComponents)
    }
}

extension Optional where Wrapped == URL {
    func isEquivalent(to other: URL?) -> Bool {
        switch (self, other) {
        case (.none, .none): return true
        case (.some, .none), (.none, .some): return false
        case (.some(let lhs), .some(let rhs)):
                return lhs.isEquivalent(to: rhs)
        }
    }
}

private extension URLComponents {
    func isEquivalent(to other: URLComponents) -> Bool {
        scheme == other.scheme
        && host == other.host
        && path == other.path
        && queryItems?.sorted(by: { $0.name < $1.name }) == other.queryItems?.sorted(by: { $0.name < $1.name })
    }
}

private extension Optional where Wrapped == URLComponents {
    func isEquivalent(to other: URLComponents?) -> Bool {
        switch (self, other) {
        case (.none, .none): return true
        case (.some, .none), (.none, .some): return false
        case (.some(let lhs), .some(let rhs)):
                return lhs.isEquivalent(to: rhs)
        }
    }
}
