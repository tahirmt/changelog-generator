//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-05-19.
//

import Foundation

public final class Logger {
    public static var verbose = false

    public enum Level {
        case `default`
        case verbose
    }

    public static func log(level: Level = .default, _ items: Any...) {
        if level == .verbose && verbose == false { return }

        print("")
        items.forEach {
            print($0, terminator: " ")
        }
        print("")
    }
}
