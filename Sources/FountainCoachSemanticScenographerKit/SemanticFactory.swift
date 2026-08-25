import Foundation

/// Chapter 103's externally consumable semantic-factory identity.
/// The factory is an execution graph; the scenographer remains one downstream consumer.
public enum SemanticFactoryIdentity {
    public static let id = "fountaincoach.semantic-factory@0.2.0"
    public static let version = "0.2.0"
    public static let operation = "reframe/semantic.factory.execute"
}

public enum SemanticFactoryNode: String, Codable, CaseIterable, Sendable {
    case libraryResolution = "library.resolution"
    case sourceAdmission = "source.admission"
    case structureParsing = "structure.parsing"
    case semanticReading = "semantic.reading"
    case readingPersistence = "reading.persistence"

    public var ordinal: Int { Self.allCases.firstIndex(of: self)! }
}

public enum SemanticFactoryLifecycle: String, Codable, CaseIterable, Sendable {
    case candidate, admitted, ready, running
    case completed, cancelled, refused, timedOut = "timed_out", failed

    public var terminal: Bool {
        switch self {
        case .completed, .cancelled, .refused, .timedOut, .failed: return true
        case .candidate, .admitted, .ready, .running: return false
        }
    }
}

/// Identity only: source text stays in Reframe/Store and never crosses the Kit boundary.
public struct SemanticFactorySource: Codable, Equatable, Hashable, Sendable {
    public let corpusID: String
    public let sourceDocumentID: String
    public let sourceDigest: String
    public let workID: String?
    public let chapterID: String?
    public let startLine: Int
    public let endLine: Int

    public init(corpusID: String, sourceDocumentID: String, sourceDigest: String,
                workID: String? = nil, chapterID: String? = nil,
                startLine: Int, endLine: Int) {
        self.corpusID = corpusID
        self.sourceDocumentID = sourceDocumentID
        self.sourceDigest = sourceDigest
        self.workID = workID
        self.chapterID = chapterID
        self.startLine = startLine
        self.endLine = endLine
    }
}

public struct SemanticFactoryExecution: Codable, Equatable, Hashable, Sendable {
    public let kitID: String
    public let runID: String
    public let sessionID: String
    public let executionID: String
    public let correlationID: String
    public let source: SemanticFactorySource

    public init(runID: String, sessionID: String, executionID: String, correlationID: String,
                source: SemanticFactorySource, kitID: String = SemanticFactoryIdentity.id) {
        self.kitID = kitID
        self.runID = runID
        self.sessionID = sessionID
        self.executionID = executionID
        self.correlationID = correlationID
        self.source = source
    }
}

public struct SemanticFactoryEvent: Codable, Equatable, Hashable, Sendable {
    public let execution: SemanticFactoryExecution
    public let node: SemanticFactoryNode
    public let lifecycle: SemanticFactoryLifecycle
    /// True only when this event ends the whole factory execution. A node's `completed` event is not terminal.
    public let terminal: Bool
    public let sequence: Int
    public let summary: String
    public let failureCode: String?
    public let storeReceiptID: String?

    public init(execution: SemanticFactoryExecution, node: SemanticFactoryNode,
                lifecycle: SemanticFactoryLifecycle, sequence: Int, summary: String,
                failureCode: String? = nil, storeReceiptID: String? = nil, terminal: Bool = false) {
        self.execution = execution
        self.node = node
        self.lifecycle = lifecycle
        self.terminal = terminal
        self.sequence = sequence
        self.summary = summary
        self.failureCode = failureCode
        self.storeReceiptID = storeReceiptID
    }
}

public enum SemanticFactoryValidationError: Error, Equatable, Sendable {
    case invalidSourceRange
    case emptySummary
    case nonMonotonicSequence
    case lineageMismatch
    case nodeOrderViolation
    case eventAfterTerminal
    case terminalMissingReceipt
}

/// Stateless validation shared by the host adapter, tests, and replay tooling.
public enum SemanticFactoryContract {
    public static let graph = SemanticFactoryNode.allCases

    public static func validate(_ events: [SemanticFactoryEvent]) throws {
        guard let first = events.first else { return }
        guard first.execution.source.startLine >= 1,
              first.execution.source.endLine >= first.execution.source.startLine else {
            throw SemanticFactoryValidationError.invalidSourceRange
        }
        var previousSequence = -1
        var previousNode = -1
        var terminal = false
        for event in events {
            guard event.execution == first.execution else { throw SemanticFactoryValidationError.lineageMismatch }
            guard event.sequence > previousSequence else { throw SemanticFactoryValidationError.nonMonotonicSequence }
            guard !event.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SemanticFactoryValidationError.emptySummary }
            guard event.node.ordinal >= previousNode else { throw SemanticFactoryValidationError.nodeOrderViolation }
            guard !terminal else { throw SemanticFactoryValidationError.eventAfterTerminal }
            if event.terminal {
                terminal = true
                if event.lifecycle == .completed && event.storeReceiptID == nil {
                    throw SemanticFactoryValidationError.terminalMissingReceipt
                }
            }
            previousSequence = event.sequence
            previousNode = event.node.ordinal
        }
    }
}
