//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2022-03-04.
//

import Foundation

struct Milestone: Decodable {
    let id: UInt64
    let number: UInt64
    let url: String
    let htmlUrl: String
    let title: String
    let description: String?
    let openIssues: UInt
    let closedIssues: UInt
    let state: State
}
