//
//  UserReadable.swift
//  
//
//  Created by Mahmood Tahir on 2022-09-29.
//

import Foundation

protocol UserReadable {
    var userReadableString: String { get }
}

extension Array: UserReadable where Element: UserReadable {
    var userReadableString: String {
        [
            "[\n",
            reduce(into: "") { $0 += $1.userReadableString + ",\n"},
            "]",
        ]
            .joined()
    }
}
