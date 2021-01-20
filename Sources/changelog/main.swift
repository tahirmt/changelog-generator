//
//  main.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import Foundation
import ArgumentParser
import ShellOut

struct Changelog: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "ChangeLogGenerator",
        abstract: "A utility for generating git change log",
        subcommands: [
            Generate.self,
        ]
    )
}

Changelog.main()
