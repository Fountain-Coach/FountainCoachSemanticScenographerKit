import Foundation
import FountainCoachSemanticScenographerKit

private struct Artifact: Encodable {
    let kind: String
    let relativePath: String
    let sha256: String
    let bytes: Int
    let eventCount: Int
}

private struct ProjectionReceipt: Encodable {
    let schema = "fountaincoach.semantic-score-midi.candidate-artifacts.v1"
    let instrumentID = SemanticScoreMIDIIdentity.id
    let phase = "generated-not-executed"
    let sourceWork: String
    let sourceOwner: String
    let sourceRevision: String
    let sourcePDFSHA256: String
    let states: Int
    let semanticSourceEvents: Int
    let authoredCues: Int
    let sourceLines: Int
    let sourceIndexDigest: String
    let candidateUMPControlChanges: Int
    let sourceIndexDocuments: Int
    let midiCandidateBatches: Int
    let originalSourceTextIncluded = false
    let emittedMIDI = false
    let persistedInFountainStore = false
    let receivedStoreReceipt = false
    let midi2HardwareInteroperability = false
    let normativeMIDI2SemanticProfile = false
    let auditionedCsound = false
    let artifacts: [Artifact]
}

private enum CLIError: Error {
    case invalidArguments
    case outputAlreadyExists
}

@main
struct ScoreMIDIProjectTool {
    static func main() throws {
        let args = Array(CommandLine.arguments.dropFirst())
        guard args.count == 8 else {
            throw CLIError.invalidArguments
        }
        var flags: [String: String] = [:]
        for index in stride(from: 0, to: args.count, by: 2) {
            let name = args[index]
            guard ["--source", "--revision", "--sha", "--output"].contains(name),
                  flags[name] == nil else {throw CLIError.invalidArguments}
            flags[name] = args[index + 1]
        }
        guard let source = flags["--source"], let revision = flags["--revision"],
              let sha = flags["--sha"], let destination = flags["--output"] else {
            throw CLIError.invalidArguments
        }
        let origin = try Data(contentsOf: URL(fileURLWithPath: source))
        // Validate before creating output. Partial results cannot be mistaken
        // for accepted MIDI transport or a successful Store operation.
        let projection = try SemanticScoreMIDIInstrument.project(
            pressJSON: origin, expectedRevision: revision,
            expectedSourcePDFSHA256: sha)
        let output = URL(fileURLWithPath: destination, isDirectory: true)
        guard !FileManager.default.fileExists(atPath: output.path) else {
            throw CLIError.outputAlreadyExists
        }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var artifacts: [Artifact] = []
        for part in projection.sourceIndex {
            let name = "store/part-\(part.partIndex).json"
            let target = output.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(),
                                                   withIntermediateDirectories: true)
            try part.data.write(to: target, options: .atomic)
            artifacts.append(Artifact(kind: "fountainstore/document.put candidate",
                                      relativePath: name, sha256: part.sha256,
                                      bytes: part.data.count,
                                      eventCount: try JSONDecoder().decode(ScoreMIDISourceIndexChunk.self,
                                                                          from: part.data).entries.count))
        }
        for part in projection.proposedMIDI {
            let name = "midi/part-\(part.partIndex).json"
            let target = output.appendingPathComponent(name)
            try FileManager.default.createDirectory(at: target.deletingLastPathComponent(),
                                                   withIntermediateDirectories: true)
            try part.eventsJSON.write(to: target, options: .atomic)
            artifacts.append(Artifact(kind: "stage/midi.events.put candidate",
                                      relativePath: name, sha256: part.sha256,
                                      bytes: part.eventsJSON.count, eventCount: part.eventCount))
        }
        let receipt = ProjectionReceipt(
            sourceWork: projection.sourceWork, sourceOwner: projection.sourceOwner,
            sourceRevision: projection.sourceRevision,
            sourcePDFSHA256: projection.sourcePDFSHA256,
            states: projection.totalStates, semanticSourceEvents: projection.totalSourceEvents,
            authoredCues: projection.totalOriginalCues, sourceLines: projection.totalSourceLines,
            sourceIndexDigest: projection.sourceIndexDigest,
            candidateUMPControlChanges: projection.proposedControlChanges,
            sourceIndexDocuments: projection.sourceIndex.count,
            midiCandidateBatches: projection.proposedMIDI.count,
            artifacts: artifacts)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
        try encoder.encode(receipt).write(to: output.appendingPathComponent("candidate-receipt.json"), options: .atomic)
        print("SCORE_MIDI_SWIFT_CANDIDATE \(output.path)")
        print("SOURCE \(projection.sourcePDFSHA256) EVENTS \(projection.totalSourceEvents) CUES \(projection.totalOriginalCues) UMP_PROPOSALS \(projection.proposedControlChanges)")
        print("STORE_CANDIDATES \(projection.sourceIndex.count) MIDI_CANDIDATES \(projection.proposedMIDI.count) ACTUAL_STORE_WRITE false ACTUAL_MIDI_EMISSION false")
    }
}
