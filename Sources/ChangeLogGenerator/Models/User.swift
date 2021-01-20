//
//  User.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-23.
//

import Foundation

struct User: Decodable {
    let id: UInt64
    let login: String
    let htmlUrl: URL
}
