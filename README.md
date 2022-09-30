# Change Log Generator

A swift package to generate change log for github repositories. The change log can be automatically stored into a file.

#### Usage:

You can use the precompiled executable `changelog` or ues `make` to create a new release. You can also use `swift run changelog` to run the script.

```
./changelog generate --repository AFNetworking/AFNetworking --type=complete --output=./CHANGELOG.md
```

It procuces an output similar to below

# 4.0.1

- [#4555](https://github.com/AFNetworking/AFNetworking/pull/4555): Prepare 4.0.1 Release by [jshier](https://github.com/jshier)
- [#4553](https://github.com/AFNetworking/AFNetworking/pull/4553): Fix ServerTrustError crash. by [jshier](https://github.com/jshier)
- [#4554](https://github.com/AFNetworking/AFNetworking/pull/4554): Fix SPM Usage by [jshier](https://github.com/jshier)
- [#4550](https://github.com/AFNetworking/AFNetworking/pull/4550): Replace instead of appending to the default header by [ElfSundae](https://github.com/ElfSundae)


# 4.0.0

- [#4527](https://github.com/AFNetworking/AFNetworking/pull/4527): Prepare 4.0.0. by [jshier](https://github.com/jshier)
- [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523): AFNetworking 4 by [jshier](https://github.com/jshier)
- [#4526](https://github.com/AFNetworking/AFNetworking/pull/4526): Remove unnecessary __block by [kinarobin](https://github.com/kinarobin)


### Action

When using the github action these are the inputs and outputs for the tool

#### Inputs

| Input | Default | Description |
--- | --- | ---
| token | github.token | The token used for github API |
| outputFile | * | The file to output to. If not provided only the action output is generated |
| since | * | The tag to generate the changelog since |
| sinceLatestRelease | * | `true`/`false` whether to generate since the latest release |
| complete | * | `true`/`false` whether to generate the complete changelog |
| nextTag | * | The next tag to bundle all the untagged pull requests into |
| filter | * | Filter regular expression to ignore all matching pull requests from the changelog |
| labels | * | Labels to group pull requests by |
| excludedLabels | * | Labels to exclude from the changelog |
| branch | * | The target branch for the changelog. When provided only pull requests merged into the branch are included |
| includeUntagged | `true` | `true`/`false` whether to include untagged pull requests in the changelog |
| verbose | * | `true`/`false` Whether to enable verbose logging. The verbose logs also become part of the outputs |
| use-compiled | `true` | `true`/`false` Whether to use the precompiled executable or not. This is never used for linux. |

#### Outputs

| Output | Description |
| --- | --- |
| changelog | The changelog generated during the run |

#### Environment Variables

`CHANGELOG_GENERATED_VALUE` : Contains the changelog generated during run
