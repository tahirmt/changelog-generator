# Change Log Generator

A swift package to generate change log for github repositories. The change log can be automatically stored into a file.

#### Usage:

You can use the precompiled executable `changelog` or ues `make` to create a new release. You can also use `swift run changelog` to run the script.

```
./changelog generate --owner=AFNetworking --repo=AFNetworking --type=complete --output=./CHANGELOG.md
```

It procuces an output similar to below

# 4.0.1
------

- [#4555](https://github.com/AFNetworking/AFNetworking/pull/4555): Prepare 4.0.1 Release by [jshier](https://github.com/jshier)
- [#4553](https://github.com/AFNetworking/AFNetworking/pull/4553): Fix ServerTrustError crash. by [jshier](https://github.com/jshier)
- [#4554](https://github.com/AFNetworking/AFNetworking/pull/4554): Fix SPM Usage by [jshier](https://github.com/jshier)
- [#4550](https://github.com/AFNetworking/AFNetworking/pull/4550): Replace instead of appending to the default header by [ElfSundae](https://github.com/ElfSundae)


# 4.0.0
------

- [#4527](https://github.com/AFNetworking/AFNetworking/pull/4527): Prepare 4.0.0. by [jshier](https://github.com/jshier)
- [#4523](https://github.com/AFNetworking/AFNetworking/pull/4523): AFNetworking 4 by [jshier](https://github.com/jshier)
- [#4526](https://github.com/AFNetworking/AFNetworking/pull/4526): Remove unnecessary __block by [kinarobin](https://github.com/kinarobin)


