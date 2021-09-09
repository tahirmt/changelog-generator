//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-09-08.
//

import Foundation

extension String {
    /// Returns a new array by capitalizing the first letter of every word
    var firstLetterCapitalized: String {
        split(separator: " ")
            .map { word -> String in
                var copy = word
                return copy.removeFirst().uppercased() + copy
            }
            .joined(separator: " ")
    }
}
