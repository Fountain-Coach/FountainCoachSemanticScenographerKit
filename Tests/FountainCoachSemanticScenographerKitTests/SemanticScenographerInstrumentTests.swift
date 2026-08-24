import XCTest
@testable import FountainCoachSemanticScenographerKit

final class SemanticScenographerInstrumentTests: XCTestCase {
    private func request() -> SemanticScenographerRequest {
        let source = "screenplay:fixture:source"
        let range = SemanticSourceRange(startLine: 11, endLine: 42)
        let address = SemanticAddress(sourceDocumentID: source, sourceRange: SemanticSourceRange(startLine: 11, endLine: 14), beatID: "beat-1", movementID: "movement-1", laneID: "questions", noteID: "q-1")
        return SemanticScenographerRequest(
            sourceDocumentID: source,
            sourceDigest: "source-digest",
            sourceRange: range,
            context: [address],
            relations: [
                .init(id: "threshold-04", address: address, role: .threshold, label: "unresolved distance"),
                .init(id: "figure-a", address: address, role: .figure, label: "advancing figure")
            ])
    }

    func testIdentityIsSemverReady() {
        XCTAssertEqual(SemanticScenographerInstrumentIdentity.version, "0.1.0")
        XCTAssertTrue(SemanticScenographerInstrumentIdentity.id.hasSuffix("@0.1.0"))
        XCTAssertEqual(SemanticScenographerInstrumentIdentity.operation, "reframe/capability.invoke")
    }

    func testCreatesAddressPreservingStructuredScoreAndDeterministicSVG() throws {
        let first = try SemanticScenographerInstrument.execute(request())
        let second = try SemanticScenographerInstrument.execute(request())
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.composition.objects.map(\.id), ["figure-a", "threshold-04"])
        XCTAssertEqual(first.composition.objects.first?.address.sourceRange.startLine, 11)
        XCTAssertEqual(first.composition.renderer, "teatro-svg-boundary.v1")
        XCTAssertFalse(first.renderDigest.isEmpty)
    }

    func testRejectsOutOfRangeRelationAndDuplicateIdentity() {
        var invalid = request()
        invalid = SemanticScenographerRequest(
            sourceDocumentID: invalid.sourceDocumentID,
            sourceDigest: invalid.sourceDigest,
            sourceRange: invalid.sourceRange,
            context: invalid.context,
            relations: [.init(id: "bad", address: .init(sourceDocumentID: invalid.sourceDocumentID, sourceRange: .init(startLine: 10, endLine: 12)), role: .object, label: "bad")])
        XCTAssertThrowsError(try SemanticScenographerInstrument.execute(invalid))

        let base = request()
        let duplicate = SemanticScenographerRequest(
            sourceDocumentID: base.sourceDocumentID,
            sourceDigest: base.sourceDigest,
            sourceRange: base.sourceRange,
            context: base.context,
            relations: [base.relations[0], base.relations[0]])
        XCTAssertThrowsError(try SemanticScenographerInstrument.execute(duplicate)) { error in
            XCTAssertEqual(error as? SemanticScenographerInstrumentError, .duplicateRelationID("threshold-04"))
        }
    }

    func testRejectsMissingSemanticContextAndUnsupportedMode() {
        let base = request()
        let emptyContext = SemanticScenographerRequest(sourceDocumentID: base.sourceDocumentID, sourceDigest: base.sourceDigest, sourceRange: base.sourceRange, context: [], relations: base.relations)
        XCTAssertThrowsError(try SemanticScenographerInstrument.execute(emptyContext))
        let invalidMode = SemanticScenographerRequest(sourceDocumentID: base.sourceDocumentID, sourceDigest: base.sourceDigest, sourceRange: base.sourceRange, context: base.context, relations: base.relations, mode: "freeform-image")
        XCTAssertThrowsError(try SemanticScenographerInstrument.execute(invalidMode))
    }
}
