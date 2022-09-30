import Foundation

enum GeneratorError: Error {
    case milestoneNotFound
    case invalidFormat
}

public struct Generator {
    let repository: String
    let token: String?
    let labels: [String]
    let excludedLabels: [String]
    let filterRegEx: String?
    /// the maximum number of pages to fetch. By default it is nil which means fetch all.
    let maximumNumberOfPages: Int?
    let nextTag: String?
    let includeUntagged: Bool

    // MARK: Initialization

    public init(repository: String,
                token: String?,
                labels: [String],
                excludedLabels: [String],
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
        self.excludedLabels = excludedLabels
        self.filterRegEx = filterRegEx
        self.maximumNumberOfPages = maximumNumberOfPages
        self.nextTag = nextTag
        self.includeUntagged = includeUntagged
    }
    
    // MARK: Methods

    /// Generates the changelog since the latest release.
    ///
    /// Fetches the latest release and fetches the number of pages specified since the last release
    public func generateChangeLogSinceLatestRelease(on branch: String? = nil) async throws -> String {
        // get the latest release
        let release = try await GitHub(repository: repository, token: token)
            .fetchLatestRelease()

        guard let released = release.publishedAt else {
            Logger.log("Not released. No changelog")
            return ""
        }

        if let branch = branch {
            return try await generateChangeLogSince(tag: release.tagName, on: branch)
        }
        else {
            Logger.log("Fetch pull requests since \(released)")
            // fetch all pull requests since the release
            let pullRequests = try await GitHub(repository: repository, token: token)
                .fetchPullRequests(mergedAfter: released, maximumNumberOfPages: maximumNumberOfPages)

            return createChangelog(pulls: pullRequests)
        }
    }

    /// Generate changelog since the given tag.
    /// - Parameters:
    ///   - tag: the tag to look for
    ///   - maximumNumberOfPages: maximum number of pages to load
    ///   - completion: will finish with a changelog string
    public func generateChangeLogSince(tag: String, on branch: String? = nil) async throws -> String {
        Logger.log(level: .verbose, "generating since \(tag) on branch \(branch ?? "nil")")
        let tags = try await GitHub(repository: repository, token: token)
            .fetch(from: .tags, maximumNumberOfPages: maximumNumberOfPages) { (tags: [Tag]) -> Bool in
                tags.contains { $0.name == tag } == false
            }

        guard let tag = tags.first(where: { $0.name == tag }) else {
            return ""
        }
        Logger.log(level: .verbose, "Found tag \(tag)")
        var allTags = tags
        var filteredTags = [Tag]()
        while allTags.isEmpty == false && allTags[0] != tag {
            filteredTags.append(allTags.removeFirst())
        }

        let pullRequests = try await GitHub(repository: repository, token: token, params: ["state": "closed"])
            .fetch(from: .pulls, maximumNumberOfPages: maximumNumberOfPages) { (pulls: [PullRequest]) -> Bool in
                pulls.contains { $0.mergeCommitSha == tag.commit.sha } == false
            }
            .filter { $0.mergedAt != nil }
            .sorted {
                $0.mergedAt! > $1.mergedAt! // we have already filtered out all the ones that have `mergedAt` as nil
            }

        var allPulls = pullRequests
        Logger.log(level: .verbose, "All pulls \(allPulls.userReadableString)")
        var filteredPulls = [PullRequest]()
        while allPulls.isEmpty == false {
            filteredPulls.append(allPulls.removeFirst())

            if allPulls[0].mergeCommitSha == tag.commit.sha {
                // we have reached the merge commit. We no longer need to append more pull requests
                break
            }
        }

        if let branch = branch {
            // fetch the comparison
            let comparison = try await GitHub(repository: repository, token: token)
                .fetchComparison(from: tag.name,
                                 to: branch,
                                 maximumNumberOfPages: maximumNumberOfPages)

            Logger.log(level: .verbose, "comparison commits \(comparison.commits.userReadableString)")
            Logger.log(level: .verbose, "Filtered pulls \(filteredPulls.userReadableString)")

            filteredPulls = filteredPulls.filter { pull in
                comparison.commits.contains { $0.sha == pull.mergeCommitSha }
            }
        }

        return createChangelog(usingTags: filteredTags, pulls: filteredPulls)
    }

    /// Generate the changelog for the given milestone. This will include all the closed pull requests that were merged and belong to the given milestone
    /// - Parameter milestone: the milestone to generate the changelog for.
    /// - Returns: Change log string representing the merged pull requests under a milestone
    public func generateChangeLogFor(milestone: String) async throws -> String {
        // fetch milestone
        let milestone: Milestone? = try await GitHub(repository: repository, token: token, params: ["state": "all", "direction": "desc"])
            .fetch(from: .milestones, maximumNumberOfPages: maximumNumberOfPages) {
                $0.contains { $0.title == milestone } == false
            }
            .first { $0.title == milestone }

        guard let milestone = milestone else {
            throw GeneratorError.milestoneNotFound
        }

        let pulls: [Issue] = try await GitHub(repository: repository,
                                                token: token,
                                                params: [
                                                    "milestone": "\(milestone.number)",
                                                    "state": "closed",
                                                    "sort": "updated",
                                                    "direction": "desc",
                                                ])
            .fetch(from: .issues, maximumNumberOfPages: maximumNumberOfPages)
            .filter { $0.pullRequest.mergedAt != nil }

        return createChangelog(pulls: pulls)
    }

    /// Generates the complete changelog by fetching all pull requests and all tags
    /// - Parameters:
    ///   - completion: will finish with a changelog string
    public func generateCompleteChangeLog() async throws -> String {
        async let tags: [Tag] = GitHub(repository: repository, token: token)
            .fetch(from: .tags, maximumNumberOfPages: maximumNumberOfPages)

        async let pulls: [PullRequest] = GitHub(repository: repository, token: token, params: ["state": "closed"])
            .fetch(from: .pulls, maximumNumberOfPages: maximumNumberOfPages)
            .filter { $0.mergedAt != nil }
            .sorted { $0.mergedAt! > $1.mergedAt! }

        return try await createChangelog(usingTags: tags, pulls: pulls)
    }

    // MARK: Private

    private func createChangelog(usingTags tags: [Tag] = [], pulls: [ChangelogConvertible]) -> String {
        var remainingTags = tags

        let expression = filterRegEx.flatMap {
            try? NSRegularExpression(pattern: $0)
        }

        let excludedLabels = self.excludedLabels

        var changeLogEntries = [ChangelogEntry]()

        var entry = ChangelogEntry(tag: nextTag, pullRequests: [])

        pulls.forEach { pullRequest in
            if let sha = pullRequest.mergeCommitSha, let tagIndex = remainingTags.firstIndex(where: { $0.commit.sha == sha }) {
                let tag = remainingTags.remove(at: tagIndex)

                changeLogEntries.append(entry)
                entry = ChangelogEntry(tag: tag.name, pullRequests: [])
            }

            var shouldFilterOut = expression.map {
                pullRequest.title.matches(regularExpression: $0)
            } ?? false

            shouldFilterOut = shouldFilterOut || pullRequest.labels.contains { excludedLabels.contains($0.name) }

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
                lines.append("\n# \(tag)\n")
            }

            let groups = entry.groups(basedOn: labels)
            let showGroupLabel = groups.count > 1

            groups.forEach { group in
                if showGroupLabel, group.pullRequests.isEmpty == false {
                    lines.append("\n### \(group.name)\n")
                }

                group.pullRequests.forEach {
                    lines.append($0.formattedMessage)
                }
            }
        }

        return lines.joined(separator: "\n").appending("\n")
    }
}

private struct ChangelogEntry {
    struct PullRequestGroup {
        let name: String
        let pullRequests: [ChangelogConvertible]
    }

    let tag: String?
    var pullRequests: [ChangelogConvertible]

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

            groups.append(PullRequestGroup(name: label.firstLetterCapitalized, pullRequests: matching))
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
