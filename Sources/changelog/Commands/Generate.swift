//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2021-01-19.
//

import ArgumentParser
import Foundation
import ShellOut
import ChangeLogGenerator

private enum GenerateError: Error {
    case missingTag
    case invalid
    case encodingError
}
// MARK: - Generate

struct Generate: ParsableCommand {
    enum LogType: String, ExpressibleByArgument {
        case complete
        case sinceLatestRelease
        case sinceTag
    }

    // MARK: - Properties

    static var configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a changelog"
    )

    @Option(help: "The repository in the format of owner/repository")
    var repository: String

    @Option(help: "The Github token to access the repo. It is a personal access token required for private repositories.")
    var token: String?

    @Option(help: "Whether to generate full changelog since first pull request")
    var type: LogType = .sinceLatestRelease

    @Option(help: "The tag to use when sinceTag type is used")
    var tag: String?

    @Option(help: "Maximum number of pages to fetch. By default it fetches all pages")
    var maxPages: Int?

    @Option(help: "The path of the file to write the output to. If not provided, the output is logged to the console")
    var output: String?

    @Option(help:"The regular expression for pull request title filter. Any pull requests whose title matches the expression will be excluded from the log")
    var filterRegEx: String?

    @Option(help: "The labels to group by. By default no grouping is applied. Comma separated.")
    var labels: String = ""

    @Option(help: "When provided, this tag is used for all the PRs that are not under a tag. Do this before a release is created.")
    var nextTag: String?

    @Option(help: "Whether or not to include untagged PRs that were merged")
    var includeUntagged: String = "true"

    @Option(help: "When this is true, the output will be logged to the console even when writing to file.")
    var logConsole: String = "false"

    // MARK: - ParsableCommand

    func run() throws {
        let generator = try Generator(
            repository: repository,
            token: token,
            labels: labels.isEmpty ? [] : labels.components(separatedBy: ","),
            filterRegEx: filterRegEx,
            maximumNumberOfPages: maxPages,
            nextTag: nextTag,
            includeUntagged: includeUntagged == "true")

        let semaphore = DispatchSemaphore(value: 0)
        var generatorResult: Result<String, Error>?

        switch type {
        case .complete:
            generator.generateCompleteChangeLog { result in
                generatorResult = result
                semaphore.signal()
            }
        case .sinceLatestRelease:
            generator.generateChangeLogSinceLatestRelease { result in
                generatorResult = result
                semaphore.signal()
            }
        case .sinceTag:
            guard let tag = tag else {
                throw GenerateError.missingTag
            }

            generator.generateChangeLogSince(tag: tag) { result in
                generatorResult = result
                semaphore.signal()
            }
        }

        semaphore.wait()

        guard let result = generatorResult else {
            throw GenerateError.invalid
        }

        switch result {
        case .failure(let error):
            throw error
        case .success(let changelog):
            try process(changelog: changelog)
        }
    }

    private func process(changelog: String) throws {
        guard let filePath = output else {
            print(changelog)
            return
        }

        if logConsole == "true" {
            print(changelog)
        }

        let url = URL(fileURLWithPath: filePath)

        guard let data = changelog.data(using: .utf8) else {
            throw GenerateError.encodingError
        }

        guard let fileHandle = try? FileHandle(forUpdating: url) else {
            try data.write(to: url)
            return
        }

        var dataToWrite = data
        if let currentContents = try? Data(contentsOf: url) {
            dataToWrite.append(currentContents)
        }

        fileHandle.write(dataToWrite)

        try fileHandle.close()
    }
}
