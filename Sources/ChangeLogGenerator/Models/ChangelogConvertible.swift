//
//  ChangelogConvertible.swift
//  
//
//  Created by Mahmood Tahir on 2022-03-04.
//

import Foundation

protocol ChangelogConvertible {
    var mergeCommitSha: String? { get }
    var title: String { get }
    var body: String? { get }
    var number: UInt64 { get }
    var labels: [Label] { get }
    var user: User { get }
    var htmlUrl: String { get }
}

extension ChangelogConvertible {
    var formattedMessage: String {
        "- [#\(number)](\(htmlUrl)): \(title) by [\(user.login)](\(user.htmlUrl))"
    }
}
