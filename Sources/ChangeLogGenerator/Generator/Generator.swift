import Foundation

enum GeneratorError: Error {
    case invalidFormat
}

public struct Generator {
    let repository: String
    let token: String?
    let labels: [String]
    let filterRegEx: String?
    /// the maximum number of pages to fetch. By default it is nil which means fetch all.
    let maximumNumberOfPages: Int?
    let nextTag: String?
    let includeUntagged: Bool

    // MARK: Initialization

    public init(repository: String,
                token: String?,
                labels: [String],
                filterRegEx: String?,
                maximumNumberOfPages: Int?,
                nextTag: String?,
                includeUntagged: Bool) throws {
        let regex = try NSRegularExpression(pattern: "(([a-zA-Z]{1,})/([a-zA-Z]{1,}))")
        guard repository.matches(regularExpression: regex) else {
            throw GeneratorError.invalidFormat
        }

        self.repository = repository
        self.token = token
        self.labels = labels
        self.filterRegEx = filterRegEx
        self.maximumNumberOfPages = maximumNumberOfPages
        self.nextTag = nextTag
        self.includeUntagged = includeUntagged
    }
    
    // MARK: Methods

    /// Generates the changelog since the latest release.
    ///
    /// Fetches the latest release and fetches the number of pages specified since the last release
    public func generateChangeLogSinceLatestRelease(completion: @escaping (Result<String, Error>) -> Void) {

        // get the latest release
        GitHub(repository: repository, token: token)
            .fetchLatestRelease { (result: Result<Release, APIError>) in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let release):
                    guard let released = release.publishedAt else {
                        completion(.success(""))
                        return
                    }

                    // fetch pull requests since the release
                    GitHub(repository: self.repository, token: self.token)
                        .fetchPullRequests(mergedAfter: released, maximumNumberOfPages: maximumNumberOfPages) { pullRequestResult in
                            switch pullRequestResult {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success(let pulls):
                                completion(.success(self.createChangelog(pulls: pulls)))
                            }
                        }
                }
            }
    }


    /// Generate changelog since the given tag.
    /// - Parameters:
    ///   - tag: the tag to look for
    ///   - maximumNumberOfPages: maximum number of pages to load
    ///   - completion: will finish with a changelog string
    public func generateChangeLogSince(tag: String, completion: @escaping (Result<String, Error>) -> Void) {
        GitHub(repository: repository, token: token)
            .fetch(from: .tags, maximumNumberOfPages: maximumNumberOfPages) { (tags: [Tag]) -> Bool in
                tags.contains(where: { $0.name == tag })
            } completionHandler: { (result: Result<[Tag], APIError>) in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let tags):
                    guard let tag = tags.first(where: { $0.name == tag }) else {
                        completion(.success(""))
                        return
                    }

                    var allTags = tags
                    var filteredTags = [Tag]()
                    while allTags.isEmpty == false && allTags[0] != tag {
                        filteredTags.append(allTags.removeFirst())
                    }

                    GitHub(repository: repository, token: token, params: ["state": "closed"])
                        .fetch(from: .pulls, maximumNumberOfPages: maximumNumberOfPages) { (pulls: [PullRequest]) -> Bool in
                            pulls.contains { $0.mergeCommitSha == tag.commit.sha } == false
                        } completionHandler: { (result: Result<[PullRequest], APIError>) in
                            switch result {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success(let pulls):
                                var allPulls = pulls
                                var filteredPulls = [PullRequest]()
                                while allPulls.isEmpty == false && allPulls[0].mergeCommitSha != tag.commit.sha {
                                    filteredPulls.append(allPulls.removeFirst())
                                }

                                completion(.success(self.createChangelog(usingTags: filteredTags, pulls: filteredPulls)))
                            }
                        }
                }
            }
    }

    /// Generates the complete changelog by fetching all pull requests and all tags
    /// - Parameters:
    ///   - completion: will finish with a changelog string
    public func generateCompleteChangeLog(completion: @escaping (Result<String, Error>) -> Void) {
        let loadQueue = DispatchQueue(label: "loadqueue")
        let group = DispatchGroup()

        var allTags: [Tag]?
        var allPulls: [PullRequest]?

        var anyError: Error?

        group.enter()
        GitHub(repository: repository, token: token)
            .fetch(from: .tags, maximumNumberOfPages: maximumNumberOfPages) { (result: Result<[Tag], APIError>) in
                switch result {
                case .success(let tags):
                    allTags = tags
                case .failure(let error):
                    anyError = error
                }
                group.leave()
        }

        group.enter()
        GitHub(repository: repository, token: token, params: ["state": "closed"])
            .fetch(from: .pulls, maximumNumberOfPages: maximumNumberOfPages) { (result: Result<[PullRequest], APIError>) in
                switch result {
                case .success(let pulls):
                    allPulls = pulls
                case .failure(let error):
                    anyError = error
                }
                group.leave()
        }

        group.notify(queue: loadQueue) {
            guard let tags = allTags, let pulls = allPulls else {
                completion(.failure(anyError ?? APIError.unknown))
                return
            }

            let pullRequests = pulls.filter {
                $0.mergedAt != nil
            }
            .sorted {
                $0.mergedAt! > $1.mergedAt!
            }
            completion(.success(createChangelog(usingTags: tags, pulls: pullRequests)))
        }
    }

    // MARK: Private

    private func createChangelog(usingTags tags: [Tag] = [], pulls: [PullRequest]) -> String {
        var remainingTags = tags

        let expression = filterRegEx.map {
            try? NSRegularExpression(pattern: $0)
        } as? NSRegularExpression

        var changeLogEntries = [ChangelogEntry]()

        var entry = ChangelogEntry(tag: nextTag, pullRequests: [])

        pulls.forEach { pullRequest in
            if let sha = pullRequest.mergeCommitSha, let tagIndex = remainingTags.firstIndex(where: { $0.commit.sha == sha }) {
                let tag = remainingTags.remove(at: tagIndex)

                changeLogEntries.append(entry)
                entry = ChangelogEntry(tag: tag.name, pullRequests: [])
            }

            let shouldFilterOut = expression.map {
                pullRequest.simpleMessage.matches(regularExpression: $0)
            } ?? false

            if shouldFilterOut == false {
                entry.pullRequests.append(pullRequest)
            }
        }
        changeLogEntries.append(entry)

        var lines: [String] = []

        if includeUntagged == false {
            // the first entry contains all the untagged PRs. The entry always exists.
            changeLogEntries.removeFirst()
        }

        changeLogEntries.forEach { entry in
            if let tag = entry.tag, entry.pullRequests.isEmpty == false {
                lines.append("\n#\(tag)")
                lines.append("------\n")
            }

            let groups = entry.groups(basedOn: labels)
            let showGroupLabel = groups.count > 1

            groups.forEach { group in
                if showGroupLabel, group.pullRequests.isEmpty == false {
                    lines.append("\n###\(group.name)\n")
                }

                group.pullRequests.forEach {
                    lines.append($0.simpleMessage)
                }
            }
        }

        return lines.joined(separator: "\n").appending("\n")
    }
}

private struct ChangelogEntry {
    struct PullRequestGroup {
        let name: String
        let pullRequests: [PullRequest]
    }

    let tag: String?
    var pullRequests: [PullRequest]

    func groups(basedOn labels: [String]) -> [PullRequestGroup] {
        var pulls = pullRequests
        var labels = labels

        var groups: [PullRequestGroup] = []

        while labels.isEmpty == false && pulls.isEmpty == false {
            let label = labels.removeFirst()

            let (matching, remaining) = pulls.filterSplit { pull in
                pull.labels.contains { $0.name == label }
            }

            pulls = remaining

            groups.append(PullRequestGroup(name: label.capitalized, pullRequests: matching))
        }

        if pulls.isEmpty == false {
            groups.append(PullRequestGroup(name: "Other", pullRequests: pulls))
        }

        return groups
    }
}

// MARK: - Helpers

private extension String {
    func matches(regularExpression: NSRegularExpression) -> Bool {
        regularExpression.firstMatch(
            in: self,
            options: [],
            range: NSRange(location: 0, length: count)) != nil

    }
}

private extension Array {
    /// Filter the array and return both the included and the excluded elements.
    ///
    /// - Parameter isIncluded: if true it will be included in the result
    /// - Returns: a tuple of arrays of included and excluded elements `(included, excluded)`
    func filterSplit(_ isIncluded: (Element) -> Bool) -> (included: [Element], excluded: [Element]) {
        reduce(([Element](), [Element]())) { result, element in
            if isIncluded(element) {
                return (result.0 + [element], result.1)
            }
            else {
                return (result.0, result.1 + [element])
            }
        }
    }
}
