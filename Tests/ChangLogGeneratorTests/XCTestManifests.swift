import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ChangLogGeneratorTests.allTests),
    ]
}
#endif
