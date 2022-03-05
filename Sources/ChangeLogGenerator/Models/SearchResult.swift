//
//  SearchResult.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation

struct SearchResult<T: Decodable>: Decodable {
    let totalCount: Int
    let incompleteResults: Bool
    let items: [T]
}
