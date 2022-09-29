//
//  Issue.swift
//  
//
//  Created by Mahmood Tahir on 2022-03-04.
//

import Foundation

struct Issue: Decodable {
    struct PullRequest: Decodable {
        let url: String
        let htmlUrl: String
        let mergedAt: Date?
    }

    let url: String
    let htmlUrl: String
    let id: UInt64
    let title: String
    let state: State
    let user: User
    let pullRequest: PullRequest
    let labels: [Label]
    let number: UInt64
    let body: String?
}

extension Issue: ChangelogConvertible {
    // this information is not exposed through issues
    var mergeCommitSha: String? { nil }
}

extension Issue: UserReadable {
    var userReadableString: String {
        "Issue#\(id), (\(url))"
    }
}
