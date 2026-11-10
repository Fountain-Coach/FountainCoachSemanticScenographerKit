import Foundation
import XCTest
@testable import FountainCoachSemanticScenographerKit

final class SemanticScoreMIDIInstrumentTests: XCTestCase {
    private let revision = String(repeating: "a", count: 40)
    private let sha = String(repeating: "b", count: 64)
    private let lineSHA = String(repeating: "c", count: 64)

    private func mapping(_ cueID: String = "sd-6", _ parameter: String = "wind_mix",
                         _ cc: Int = 70, _ value: Double = 0.58) -> [String: Any] {
        ["sourceCueID": cueID, "parameter": parameter, "controller": cc,
         "value": value, "mappingStatus": "non-authorial-sonification-proposal",
         "group": 0, "channel": 0]
    }

    private func event(_ ordinal: Int, state: String, page: Int, line: Int,
                       cues: [String], mappings: [[String: Any]] = [],
                       speaker: String? = nil) -> [String: Any] {
        var value: [String: Any] = [
            "id": "synthetic-score.page-\(page).line-\(line)-\(line)",
            "ordinal": ordinal, "stateID": state,
            "kind": cues.isEmpty ? (speaker == nil ? "instruction-or-text" : "voice") : "cue",
            "originalSourceBlock": "synthetic-score.page-\(page).line-\(line)-\(line)",
            "sourceAddress": ["page": page, "lineStart": line, "lineEnd": line],
            "sourceLineSHA256": lineSHA,
            "cueIDs": cues, "compoundCue": cues.count > 1,
            "authoredTiming": cues.contains("sd-6") ? ["sd-6": ["durationSeconds": 12]] : [:],
            "sonification": mappings,
            "sourceMeaningStatus": "authored-structural-identity",
            "audioRecordingAvailable": false,
            "originalText": "PRIVATE SCRIPT TEXT MUST NEVER CROSS THE KIT PROJECTION"
        ]
        if let speaker {value["speaker"] = speaker}
        return value
    }

    private func fixture(eventCount: Int = 4) -> [String: Any] {
        precondition(eventCount >= 4)
        var events: [[String: Any]] = [
            event(0, state: "preset", page: 1, line: 3, cues: ["sc-1", "lx-2"]),
            event(1, state: "state-i", page: 2, line: 3,
                  cues: ["sc-3", "lx-6", "sd-6"], mappings: [mapping()]),
            event(2, state: "state-i", page: 2, line: 4, cues: [], speaker: "BEE"),
            event(3, state: "state-i", page: 2, line: 5, cues: ["sd-9"],
                  mappings: [mapping("sd-9", "wind_mix", 70, 0),
                             mapping("sd-9", "turbulence_mix", 71, 0)])
        ]
        if eventCount > 4 {
            for i in 4..<eventCount {
                events.append(event(i, state: "state-i", page: 2, line: i + 2, cues: []))
            }
        }
        return [
            "schema": SemanticScoreMIDIIdentity.sourceSchema,
            "status": "candidate-not-FCIS-KIT-admitted",
            "sourceWork": "synthetic-score", "sourceOwner": "Fountain-Coach/TestFixture",
            "sourceRevision": revision, "sourcePDFSHA256": sha,
            "sourceEditionID": "score--synthetic", "sourceLines": eventCount + 2,
            "cueCount": 6, "cuePassageCount": 3,
            "controlChangesPlanned": 3,
            "recordedVoiceAvailable": false, "publishedProduction": false,
            "states": [
                ["id": "preset", "kind": "performance", "address": ["page": 1, "line": 2]],
                ["id": "state-i", "kind": "performance", "address": ["page": 2, "line": 2]]
            ],
            "events": events
        ]
    }

    private func data(_ document: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: document, options: [.sortedKeys])
    }

    private func project(_ document: [String: Any], maxDocumentBytes: Int = 60_000) throws -> SemanticScoreMIDIProjection {
        try SemanticScoreMIDIInstrument.project(
            pressJSON: data(document), expectedRevision: revision,
            expectedSourcePDFSHA256: sha, maxDocumentBytes: maxDocumentBytes)
    }

    func testReusesExistingIDLTopicsRatherThanInventingOperation() {
        XCTAssertEqual(SemanticScoreMIDIIdentity.storeOperation, "fountainstore/document.put")
        XCTAssertEqual(SemanticScoreMIDIIdentity.midiOperation, "stage/midi.events.put")
        XCTAssertEqual(SemanticScoreMIDIIdentity.extensionSchema, "fountaincoach.semantic-score-midi.v1")
    }

    func testProjectsAllSourcePassagesButOnlySonifiableCuesAsMIDI2() throws {
        let projection = try project(fixture())
        XCTAssertEqual(projection.totalSourceEvents, 4)
        XCTAssertEqual(projection.totalOriginalCues, 6)
        XCTAssertEqual(projection.totalCuePassages, 3)
        XCTAssertEqual(projection.totalSourceLines, 6)
        XCTAssertEqual(projection.proposedControlChanges, 3)
        XCTAssertEqual(projection.sourceIndex.count, 1)
        XCTAssertEqual(projection.proposedMIDI.count, 1)
        XCTAssertFalse(projection.observedMIDI)
        XCTAssertNil(projection.storeReceiptID)
        XCTAssertFalse(projection.completedOperation)
        let index = try JSONDecoder().decode(ScoreMIDISourceIndexChunk.self, from: projection.sourceIndex[0].data)
        XCTAssertEqual(index.entries.map(\.ordinal), [0, 1, 2, 3])
        XCTAssertEqual(index.entries[1].cueIDs, ["sc-3", "lx-6", "sd-6"])
        XCTAssertEqual(index.entries[1].sourceLineSHA256, lineSHA)
        XCTAssertEqual(index.entries[2].speaker, "BEE")
        XCTAssertEqual(index.entries[1].authoredTiming["sd-6"]?["durationSeconds"], 12)
        XCTAssertFalse(String(decoding: projection.sourceIndex[0].data, as: UTF8.self).contains("PRIVATE SCRIPT TEXT"))
        let ums = try JSONDecoder().decode([ScoreMIDICandidateUMPEvent].self,
                                           from: projection.proposedMIDI[0].eventsJSON)
        XCTAssertEqual(ums.count, 3)
        XCTAssertEqual(ums[0].sourceCueID, "sd-6")
        XCTAssertEqual(ums[0].sourceEventID, "synthetic-score.page-2.line-3-3")
        XCTAssertEqual(ums[0].words, [0x40B0_4600, 2_491_081_031])
        XCTAssertTrue(ums.allSatisfy { $0.words.count == 2 && ($0.words[0] >> 28) == 4 })
        XCTAssertFalse(ums.contains { $0.sourceCueID == "lx-6" || $0.sourceCueID == "sc-3" })
        XCTAssertTrue(ums.allSatisfy { $0.executionState == "not-dispatched" })
    }

    func testReplayProducesExactSameIndicesAndPacketsWithoutSideEffects() throws {
        let one = try project(fixture()), two = try project(fixture())
        XCTAssertEqual(one.sourceIndexDigest, two.sourceIndexDigest)
        XCTAssertEqual(one.sourceIndex, two.sourceIndex)
        XCTAssertEqual(one.proposedMIDI, two.proposedMIDI)
        XCTAssertFalse(one.observedMIDI)
        XCTAssertNil(two.storeReceiptID)
    }

    func testChunksLargeIndexUnderNativeStorePayloadBudget() throws {
        let result = try project(fixture(eventCount: 83), maxDocumentBytes: 4_096)
        XCTAssertEqual(result.totalSourceEvents, 83)
        XCTAssertGreaterThan(result.sourceIndex.count, 1)
        XCTAssertEqual(result.sourceIndex.flatMap {
            (try? JSONDecoder().decode(ScoreMIDISourceIndexChunk.self, from: $0.data).entries) ?? []
        }.map(\.ordinal), Array(0..<83))
        for (index, chunk) in result.sourceIndex.enumerated() {
            XCTAssertLessThanOrEqual(chunk.data.count, 4_096)
            XCTAssertEqual(chunk.partIndex, index)
            XCTAssertEqual(chunk.partCount, result.sourceIndex.count)
        }
    }

    func testRejectsStaleSourceOrAlteredDigest() throws {
        XCTAssertThrowsError(try SemanticScoreMIDIInstrument.project(
            pressJSON: data(fixture()), expectedRevision: "stale", expectedSourcePDFSHA256: sha))
        XCTAssertThrowsError(try SemanticScoreMIDIInstrument.project(
            pressJSON: data(fixture()), expectedRevision: revision, expectedSourcePDFSHA256: String(repeating: "0", count: 64)))
    }

    func testRejectsDuplicateCueOrMismatchedCompoundIdentity() throws {
        var document = fixture()
        var events = document["events"] as! [[String: Any]]
        events[3]["cueIDs"] = ["sd-6"]
        document["events"] = events
        XCTAssertThrowsError(try project(document))
        events[3]["cueIDs"] = ["sd-9"]
        events[1]["compoundCue"] = false
        document["events"] = events
        XCTAssertThrowsError(try project(document))
    }

    func testRejectsInventedSoundForNonSonicCueAndWrongController() throws {
        var document = fixture()
        var events = document["events"] as! [[String: Any]]
        events[0]["sonification"] = [mapping("lx-2")]
        document["events"] = events
        XCTAssertThrowsError(try project(document))
        events[0]["sonification"] = [] as [[String: Any]]
        events[1]["sonification"] = [mapping("sd-6", "wind_mix", 70, 0.58),
                                     mapping("sd-6", "head_mix", 124, 0.7)]
        document["events"] = events
        XCTAssertThrowsError(try project(document))
    }

    func testRejectsNonAuthorialRecordingClaimAndExcessivePayloadBudget() throws {
        var document = fixture()
        document["recordedVoiceAvailable"] = true
        XCTAssertThrowsError(try project(document))
        document["recordedVoiceAvailable"] = false
        XCTAssertThrowsError(try project(document, maxDocumentBytes: 2_000))
    }

    func testPrivateOriginalSourceFixtureIfAvailable() throws {
        guard let file = ProcessInfo.processInfo.environment["FCIS_SCORE_MIDI_SOURCE_JSON"], !file.isEmpty else {
            return // normal public CI must not embed or search for private works
        }
        let input = try Data(contentsOf: URL(fileURLWithPath: file))
        let actual = try SemanticScoreMIDIInstrument.project(
            pressJSON: input,
            expectedRevision: "70b8ddc9699d503be75864cbc1e33a9892f6ed3d",
            expectedSourcePDFSHA256: "a3c072d3c4d6863555a24c635abbe95f4e804625f7277740afa86e71c7b4b21b")
        XCTAssertEqual(actual.totalSourceEvents, 327)
        XCTAssertEqual(actual.totalStates, 10)
        XCTAssertEqual(actual.totalOriginalCues, 32)
        XCTAssertEqual(actual.totalCuePassages, 29)
        XCTAssertEqual(actual.totalSourceLines, 536)
        XCTAssertEqual(actual.proposedControlChanges, 16)
        XCTAssertFalse(actual.sourceIndex.isEmpty)
        XCTAssertEqual(actual.proposedMIDI.reduce(0) { $0 + $1.eventCount }, 16)
        for part in actual.sourceIndex {
            XCTAssertLessThanOrEqual(part.data.count, SemanticScoreMIDIIdentity.storePayloadBudget)
            XCTAssertFalse(String(decoding: part.data, as: UTF8.self).contains("A white exterior field appears"))
        }
        XCTAssertFalse(actual.observedMIDI)
        XCTAssertNil(actual.storeReceiptID)
    }
}
