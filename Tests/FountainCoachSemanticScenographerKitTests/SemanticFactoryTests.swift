import XCTest
@testable import FountainCoachSemanticScenographerKit

final class SemanticFactoryTests: XCTestCase {
    private func execution() -> SemanticFactoryExecution {
        SemanticFactoryExecution(
            runID: "run-1", sessionID: "session-1", executionID: "exec-1", correlationID: "corr-1",
            source: SemanticFactorySource(corpusID: "book", sourceDocumentID: "circe",
                                          sourceDigest: "digest", chapterID: "circe", startLine: 1, endLine: 12))
    }

    func testAcceptsOrderedSharedLineageWithReceipt() throws {
        let e = execution()
        let events = SemanticFactoryNode.allCases.enumerated().map {
            SemanticFactoryEvent(execution: e, node: $0.element,
                                 lifecycle: .completed,
                                 sequence: $0.offset, summary: $0.element.rawValue,
                                 storeReceiptID: $0.offset == 4 ? "receipt-1" : nil,
                                 terminal: $0.offset == 4)
        }
        XCTAssertNoThrow(try SemanticFactoryContract.validate(events))
    }

    func testRejectsLineageChangeAndDownstreamAfterFailure() throws {
        let e = execution()
        let failed = SemanticFactoryEvent(execution: e, node: .structureParsing, lifecycle: .failed,
                                          sequence: 1, summary: "parser failed", failureCode: "parse.failed", terminal: true)
        let later = SemanticFactoryEvent(execution: e, node: .semanticReading, lifecycle: .running,
                                         sequence: 2, summary: "must not run")
        XCTAssertThrowsError(try SemanticFactoryContract.validate([failed, later]))
        let other = SemanticFactoryExecution(runID: "other", sessionID: e.sessionID, executionID: e.executionID,
                                             correlationID: e.correlationID, source: e.source)
        let mismatch = SemanticFactoryEvent(execution: other, node: .structureParsing, lifecycle: .running,
                                            sequence: 2, summary: "wrong lineage")
        XCTAssertThrowsError(try SemanticFactoryContract.validate([failed, mismatch]))
    }
}
