//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-05-20.
//

import Foundation

struct Comparison: Decodable {
    let url: URL
    let status: String
    let aheadBy: Int
    let behindBy: Int
    let totalCommits: Int
    var commits: [FullCommit]
    let baseCommit: FullCommit
    let mergeBaseCommit: FullCommit
}
