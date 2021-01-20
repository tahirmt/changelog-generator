//
//  PullRequest.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

struct PullRequest: Decodable {
    enum State: String, Decodable {
        case closed
        case open
    }

    let url: String
    let htmlUrl: String
    let id: UInt64
    let body: String?
    let mergedAt: Date?
    let title: String
    let state: State
    let number: UInt64
    let mergeCommitSha: String?
    let labels: [Label]
    let user: User

    var simpleMessage: String {
        "- [#\(number)](\(htmlUrl)): \(title) by [\(user.login)](\(user.htmlUrl))"
    }
}
