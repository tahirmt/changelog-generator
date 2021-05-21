//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-05-19.
//

import Foundation

public final class Logger {
    public static var verbose = false

    public static func log(_ items: Any...) {
        guard verbose else { return }

        print("")
        items.forEach {
            print($0, terminator: " ")
        }
        print("")
    }
}
