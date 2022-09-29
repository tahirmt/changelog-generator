//
//  Commit.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

struct Commit: Decodable, Equatable {
    let sha: String
    let url: URL
}

struct FullCommit: Decodable {
    struct User: Decodable {
        let name: String
        let email: String
        let date: Date
    }

    struct Details: Decodable {
        let message: String
        let author: User
        let committer: User
    }

    let sha: String
    let commit: Details
}

extension FullCommit: UserReadable {
    var userReadableString: String {
        "FullCommit: \(sha) \(commit.message)"
    }
}

extension Commit: UserReadable {
    var userReadableString: String {
        "Commit: \(sha)"
    }
}
