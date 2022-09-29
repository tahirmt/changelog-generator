//
//  Tag.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

struct Tag: Decodable, Equatable {
    let name: String
    let commit: Commit
}

extension Tag: UserReadable {
    var userReadableString: String {
        "Tag: \(name) \(commit.sha)"
    }
}
