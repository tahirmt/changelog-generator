//
//  Release.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

struct Release: Decodable {
    let url: URL
    let id: UInt64
    let tagName: String
    let name: String
    let createdAt: Date
    let publishedAt: Date?
    let draft: Bool
}

extension Release: UserReadable {
    var userReadableString: String {
        "Release: \(name)"
    }
}
