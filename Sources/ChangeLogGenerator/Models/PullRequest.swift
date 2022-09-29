//
//  PullRequest.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

enum State: String, Decodable {
    case closed
    case open
}

struct PullRequest: Decodable {
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
}

extension PullRequest: ChangelogConvertible {}

extension PullRequest: UserReadable {
    var userReadableString: String {
        "Pull: \(title) (\(url)) \(mergeCommitSha ?? "")"
    }
}
