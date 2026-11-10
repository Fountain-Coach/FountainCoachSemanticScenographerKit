import CryptoKit
import Foundation

/// The score's semantic graph belongs to the source. MIDI 2.0 only carries
/// source-linked, explicitly proposed 64-bit UMP control changes where sound
/// is warranted. These topic strings are declared in the existing IDL.
public enum SemanticScoreMIDIIdentity {
    public static let id = "fountaincoach.semantic-score-midi@0.1.0"
    public static let version = "0.1.0"
    public static let extensionSchema = "fountaincoach.semantic-score-midi.v1"
    public static let sourceSchema = "fountain.press.semantic-midi-event-projection.v1"
    public static let storeOperation = "fountainstore/document.put"
    public static let midiOperation = "stage/midi.events.put"
    public static let storePayloadBudget = 65_536
    public static let midiPayloadBudget = 262_144
}

public enum SemanticScoreMIDIError: Error, Equatable, Sendable {
    case sourceIdentityMismatch
    case invalidSourceIdentity
    case invalidState
    case invalidSourceAddress
    case eventOrderOrIdentity
    case duplicateCue(String)
    case cueCoverageMismatch
    case invalidSourceCoverage
    case invalidSonification
    case unverifiedAudioClaim
    case payloadBudgetExceeded
}

/// Page/line positions are exact source addresses; these are not wall-clock
/// positions, MIDI clock positions, performance instructions or beat numbers.
public struct ScoreMIDISourceAddress: Codable, Equatable, Hashable, Sendable {
    public let page: Int
    public let lineStart: Int
    public let lineEnd: Int
}

public struct ScoreMIDIStateAddress: Codable, Equatable, Hashable, Sendable {
    public let page: Int
    public let line: Int
}

public struct ScoreMIDIState: Decodable, Equatable, Sendable {
    public let id: String
    public let kind: String
    public let address: ScoreMIDIStateAddress?
    // Intentionally no original title or prose in the kit-owned model.
}

public struct ScoreMIDISonification: Codable, Equatable, Sendable {
    public let sourceCueID: String
    public let parameter: String
    public let controller: Int
    public let value: Double
    public let mappingStatus: String
    public let group: Int
    public let channel: Int
}

public struct ScoreMIDIOriginalEvent: Decodable, Sendable {
    public let id: String
    public let ordinal: Int
    public let stateID: String
    public let kind: String
    public let originalSourceBlock: String
    public let sourceAddress: ScoreMIDISourceAddress
    public let sourceLineSHA256: String
    public let speaker: String?
    public let cueIDs: [String]
    public let compoundCue: Bool
    public let authoredTiming: [String: [String: Int]]
    public let sonification: [ScoreMIDISonification]
    public let sourceMeaningStatus: String
    public let audioRecordingAvailable: Bool
    // JSONDecoder drops originalText and every other unknown field. The public
    // kit never serializes manuscript words into Store or MIDI requests.
}

public struct ScoreMIDIOriginalProjection: Decodable, Sendable {
    public let schema: String
    public let status: String
    public let sourceWork: String
    public let sourceOwner: String
    public let sourceRevision: String
    public let sourcePDFSHA256: String
    public let sourceEditionID: String
    public let sourceLines: Int
    public let cueCount: Int
    public let cuePassageCount: Int
    public let controlChangesPlanned: Int
    public let recordedVoiceAvailable: Bool
    public let publishedProduction: Bool
    public let states: [ScoreMIDIState]
    public let events: [ScoreMIDIOriginalEvent]
}

/// A deterministic, text-free source index record for the host-selected
/// FountainStore. This does not create or choose a Store session.
public struct ScoreMIDISourceIndexEvent: Codable, Equatable, Sendable {
    public let id: String
    public let ordinal: Int
    public let stateID: String
    public let kind: String
    public let address: ScoreMIDISourceAddress
    public let sourceLineSHA256: String
    public let speaker: String?
    public let cueIDs: [String]
    public let compoundCue: Bool
    public let authoredTiming: [String: [String: Int]]
}

public struct ScoreMIDISourceIndexChunk: Codable, Equatable, Sendable {
    public let schema: String
    public let sourceWork: String
    public let sourceOwner: String
    public let sourceRevision: String
    public let sourcePDFSHA256: String
    public let projectionDigest: String
    public let totalSourceEvents: Int
    public let totalOriginalCues: Int
    public let totalSourceLines: Int
    public let partIndex: Int
    public let partCount: Int
    public let entries: [ScoreMIDISourceIndexEvent]
}

/// Candidate for the IDL's `fountainstore/document.put` data object.
/// The Reframe host supplies corpusID and executes/receipts the actual operation.
public struct ScoreMIDIStoreDocumentCandidate: Equatable, Sendable {
    public let documentID: String
    public let partIndex: Int
    public let partCount: Int
    public let data: Data
    public let sha256: String
}

/// A real MIDI 2.0 64-bit UMP Control Change word pair, but NOT an observed
/// transport exchange. The two UInt32 words are only a *proposal* until an
/// admitted host/peer dispatches the packet and the Monitor witnesses it.
public struct ScoreMIDICandidateUMPEvent: Codable, Equatable, Sendable {
    public let schema: String
    public let sourceEventID: String
    public let sourceCueID: String
    public let sourceAddress: ScoreMIDISourceAddress
    public let stateID: String
    public let group: Int
    public let channel: Int
    public let controller: Int
    public let parameter: String
    public let value: Double
    public let words: [UInt32]
    public let mappingStatus: String
    public let executionState: String
}

/// Candidate for the existing `stage/midi.events.put` events: bytes IDL field.
/// Host owns sceneID, corpus, consent, request dispatch, and ack/Store proof.
public struct ScoreMIDIMIDIRequestCandidate: Equatable, Sendable {
    public let source: String
    public let partIndex: Int
    public let partCount: Int
    public let eventsJSON: Data
    public let sha256: String
    public let eventCount: Int
}

public struct SemanticScoreMIDIProjection: Sendable {
    public let sourceWork: String
    public let sourceOwner: String
    public let sourceRevision: String
    public let sourcePDFSHA256: String
    public let totalStates: Int
    public let totalSourceEvents: Int
    public let totalOriginalCues: Int
    public let totalSourceLines: Int
    public let totalCuePassages: Int
    public let sourceIndexDigest: String
    public let sourceIndex: [ScoreMIDIStoreDocumentCandidate]
    public let proposedMIDI: [ScoreMIDIMIDIRequestCandidate]
    public let proposedControlChanges: Int
    public let observedMIDI: Bool
    public let storeReceiptID: String?
    public let completedOperation: Bool
}

/// The kit is a pure compiler/validator. It does not open a Store, emit MIDI,
/// start Csound, subscribe to hardware, access the network, or self-admit.
public enum SemanticScoreMIDIInstrument {
    private static let parameters = [
        "wind_mix": 70, "turbulence_mix": 71, "head_mix": 72, "voice_mix": 73
    ]
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }()

    public static func project(
        pressJSON: Data,
        expectedRevision: String,
        expectedSourcePDFSHA256: String,
        maxDocumentBytes: Int = 60_000,
        maxMIDIBytes: Int = 245_000
    ) throws -> SemanticScoreMIDIProjection {
        guard maxDocumentBytes >= 4_096,
              maxDocumentBytes <= SemanticScoreMIDIIdentity.storePayloadBudget,
              maxMIDIBytes >= 4_096,
              maxMIDIBytes <= SemanticScoreMIDIIdentity.midiPayloadBudget else {
            throw SemanticScoreMIDIError.payloadBudgetExceeded
        }
        let source = try JSONDecoder().decode(ScoreMIDIOriginalProjection.self, from: pressJSON)
        try validate(source, expectedRevision: expectedRevision, expectedSHA256: expectedSourcePDFSHA256)

        let records: [ScoreMIDISourceIndexEvent] = source.events.map { event in
            ScoreMIDISourceIndexEvent(
                id: event.id, ordinal: event.ordinal, stateID: event.stateID,
                kind: event.kind, address: event.sourceAddress,
                sourceLineSHA256: event.sourceLineSHA256,
                speaker: event.speaker, cueIDs: event.cueIDs,
                compoundCue: event.compoundCue,
                authoredTiming: event.authoredTiming)
        }
        let digest = sha256(try encoder.encode(records))
        let sourceIdentity = "\(source.sourceWork)@\(source.sourceRevision):\(source.sourcePDFSHA256)"
        let documents = try makeIndexChunks(records: records, source: source,
                                            digest: digest, maxBytes: maxDocumentBytes)
        let packets = source.events.flatMap { event in
            event.sonification.map { mapping in
                ScoreMIDICandidateUMPEvent(
                    schema: SemanticScoreMIDIIdentity.extensionSchema,
                    sourceEventID: event.id, sourceCueID: mapping.sourceCueID,
                    sourceAddress: event.sourceAddress, stateID: event.stateID,
                    group: mapping.group, channel: mapping.channel,
                    controller: mapping.controller, parameter: mapping.parameter,
                    value: mapping.value,
                    words: umpCC(mapping.controller, value: mapping.value),
                    mappingStatus: mapping.mappingStatus,
                    executionState: "not-dispatched")
            }
        }
        let midi = try makeMIDIChunks(packets, sourceIdentity: sourceIdentity, maxBytes: maxMIDIBytes)
        return SemanticScoreMIDIProjection(
            sourceWork: source.sourceWork, sourceOwner: source.sourceOwner,
            sourceRevision: source.sourceRevision, sourcePDFSHA256: source.sourcePDFSHA256,
            totalStates: source.states.count, totalSourceEvents: source.events.count,
            totalOriginalCues: source.cueCount, totalSourceLines: source.sourceLines,
            totalCuePassages: source.cuePassageCount, sourceIndexDigest: digest,
            sourceIndex: documents, proposedMIDI: midi,
            proposedControlChanges: packets.count,
            observedMIDI: false, storeReceiptID: nil, completedOperation: false)
    }

    private static func validate(_ source: ScoreMIDIOriginalProjection,
                                 expectedRevision: String, expectedSHA256: String) throws {
        guard source.schema == SemanticScoreMIDIIdentity.sourceSchema,
              source.status == "candidate-not-FCIS-KIT-admitted",
              source.sourceRevision == expectedRevision,
              source.sourcePDFSHA256 == expectedSHA256,
              isHex64(source.sourcePDFSHA256),
              !source.sourceOwner.isEmpty, !source.sourceEditionID.isEmpty,
              !source.sourceWork.isEmpty,
              source.sourceWork.unicodeScalars.allSatisfy({
                  CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_").contains($0)
              }) else { throw SemanticScoreMIDIError.sourceIdentityMismatch }
        guard !source.recordedVoiceAvailable, !source.publishedProduction,
              source.events.allSatisfy({ !$0.audioRecordingAvailable }) else {
            throw SemanticScoreMIDIError.unverifiedAudioClaim
        }
        guard !source.events.isEmpty, !source.states.isEmpty,
              source.sourceLines > 0, source.cueCount > 0,
              source.cuePassageCount > 0, source.controlChangesPlanned >= 0 else {
            throw SemanticScoreMIDIError.invalidSourceIdentity
        }
        let stateIDs = source.states.map(\.id)
        guard Set(stateIDs).count == stateIDs.count,
              source.states.allSatisfy({ !$0.id.isEmpty && !$0.kind.isEmpty &&
                  ($0.address == nil || ($0.address!.page >= 1 && $0.address!.line >= 1)) }) else {
            throw SemanticScoreMIDIError.invalidState
        }
        let knownStates = Set(stateIDs)
        var seenEvents = Set<String>()
        var seenCues = Set<String>()
        var cuePassages = 0
        var mappings = 0
        var countedLines = source.states.compactMap(\.address).count
        for (expectedOrdinal, event) in source.events.enumerated() {
            let range = event.sourceAddress
            let requiredID = "\(source.sourceWork).page-\(range.page).line-\(range.lineStart)-\(range.lineEnd)"
            guard range.page >= 1, range.lineStart >= 1, range.lineEnd >= range.lineStart,
                  isHex64(event.sourceLineSHA256) else {
                throw SemanticScoreMIDIError.invalidSourceAddress
            }
            guard event.ordinal == expectedOrdinal, event.id == requiredID,
                  event.originalSourceBlock == event.id,
                  seenEvents.insert(event.id).inserted,
                  knownStates.contains(event.stateID),
                  event.sourceMeaningStatus == "authored-structural-identity" else {
                throw SemanticScoreMIDIError.eventOrderOrIdentity
            }
            countedLines += range.lineEnd - range.lineStart + 1
            guard event.compoundCue == (event.cueIDs.count > 1) else {
                throw SemanticScoreMIDIError.cueCoverageMismatch
            }
            if !event.cueIDs.isEmpty { cuePassages += 1 }
            for cue in event.cueIDs {
                let components = cue.split(separator: "-")
                guard components.count == 2,
                      ["sc", "lx", "sd", "b"].contains(String(components[0])),
                      Int(components[1]).map({ $0 >= 0 }) == true else {
                    throw SemanticScoreMIDIError.cueCoverageMismatch
                }
                guard seenCues.insert(cue).inserted else {
                    throw SemanticScoreMIDIError.duplicateCue(cue)
                }
            }
            for (cue, timing) in event.authoredTiming {
                guard event.cueIDs.contains(cue), !timing.isEmpty,
                      timing.allSatisfy({ !$0.key.isEmpty && $0.value >= 0 }) else {
                    throw SemanticScoreMIDIError.invalidSourceCoverage
                }
            }
            for mapping in event.sonification {
                guard event.cueIDs.contains(mapping.sourceCueID),
                      mapping.sourceCueID.hasPrefix("sd-"),
                      parameters[mapping.parameter] == mapping.controller,
                      (0...1).contains(mapping.value),
                      mapping.value.isFinite,
                      mapping.group == 0, mapping.channel == 0,
                      mapping.mappingStatus == "non-authorial-sonification-proposal" else {
                    throw SemanticScoreMIDIError.invalidSonification
                }
                mappings += 1
            }
        }
        guard seenCues.count == source.cueCount,
              cuePassages == source.cuePassageCount,
              mappings == source.controlChangesPlanned else {
            throw SemanticScoreMIDIError.cueCoverageMismatch
        }
        guard countedLines == source.sourceLines else {
            throw SemanticScoreMIDIError.invalidSourceCoverage
        }
    }

    private static func makeIndexChunks(
        records: [ScoreMIDISourceIndexEvent], source: ScoreMIDIOriginalProjection,
        digest: String, maxBytes: Int
    ) throws -> [ScoreMIDIStoreDocumentCandidate] {
        let sourceDigest = source.sourcePDFSHA256
        func payload(_ events: [ScoreMIDISourceIndexEvent], partIndex: Int, count: Int) throws -> Data {
            try encoder.encode(ScoreMIDISourceIndexChunk(
                schema: SemanticScoreMIDIIdentity.extensionSchema + ".source-index",
                sourceWork: source.sourceWork, sourceOwner: source.sourceOwner,
                sourceRevision: source.sourceRevision, sourcePDFSHA256: sourceDigest,
                projectionDigest: digest, totalSourceEvents: records.count,
                totalOriginalCues: source.cueCount, totalSourceLines: source.sourceLines,
                partIndex: partIndex, partCount: count, entries: events))
        }
        var chunks: [[ScoreMIDISourceIndexEvent]] = []
        var current: [ScoreMIDISourceIndexEvent] = []
        for record in records {
            let next = current + [record]
            if try payload(next, partIndex: chunks.count, count: records.count).count > maxBytes {
                guard !current.isEmpty else { throw SemanticScoreMIDIError.payloadBudgetExceeded }
                chunks.append(current);current=[record]
            } else { current=next }
        }
        if !current.isEmpty {chunks.append(current)}
        return try chunks.enumerated().map { index, chunk in
            let data = try payload(chunk, partIndex: index, count: chunks.count)
            guard data.count <= maxBytes else {throw SemanticScoreMIDIError.payloadBudgetExceeded}
            return ScoreMIDIStoreDocumentCandidate(
                documentID: "score-midi:\(source.sourceWork):\(digest.prefix(24)):part-\(index)",
                partIndex: index, partCount: chunks.count,
                data: data, sha256: sha256(data))
        }
    }

    private static func makeMIDIChunks(
        _ packets: [ScoreMIDICandidateUMPEvent], sourceIdentity: String,
        maxBytes: Int
    ) throws -> [ScoreMIDIMIDIRequestCandidate] {
        guard !packets.isEmpty else {return []}
        var chunks: [[ScoreMIDICandidateUMPEvent]] = []
        var current: [ScoreMIDICandidateUMPEvent] = []
        for packet in packets {
            let next = current + [packet]
            if try encoder.encode(next).count > maxBytes {
                guard !current.isEmpty else {throw SemanticScoreMIDIError.payloadBudgetExceeded}
                chunks.append(current);current=[packet]
            } else { current=next }
        }
        if !current.isEmpty {chunks.append(current)}
        return try chunks.enumerated().map { index, chunk in
            let data = try encoder.encode(chunk)
            guard data.count <= maxBytes else {throw SemanticScoreMIDIError.payloadBudgetExceeded}
            return ScoreMIDIMIDIRequestCandidate(
                source: sourceIdentity, partIndex: index, partCount: chunks.count,
                eventsJSON: data, sha256: sha256(data), eventCount: chunk.count)
        }
    }

    private static func umpCC(_ controller: Int, value: Double) -> [UInt32] {
        let first = UInt32(0x40B0_0000) | (UInt32(controller) << 8)
        let second = UInt32((value * Double(UInt32.max)).rounded())
        return [first, second]
    }

    private static func isHex64(_ value: String) -> Bool {
        value.count == 64 && value.unicodeScalars.allSatisfy({
            CharacterSet(charactersIn: "0123456789abcdef").contains($0)
        })
    }

    private static func sha256(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
