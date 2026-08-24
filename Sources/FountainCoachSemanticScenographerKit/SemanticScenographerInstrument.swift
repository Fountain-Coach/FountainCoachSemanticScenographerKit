import CryptoKit
import Foundation

/// FCIS-KIT identity for the Chapter 100 Semantic Scenographer candidate.
public enum SemanticScenographerInstrumentIdentity {
    public static let id = "fountaincoach.semantic-scenographer@0.1.0"
    public static let version = "0.1.0"
    public static let operation = "reframe/capability.invoke"
    public static let capability = "semantic scenographer"
}

public struct SemanticSourceRange: Codable, Equatable, Hashable, Sendable {
    public let startLine: Int
    public let endLine: Int

    public init(startLine: Int, endLine: Int) {
        self.startLine = startLine
        self.endLine = endLine
    }
}

/// A source-grounded address. The kit carries identity and ranges, never manuscript text.
public struct SemanticAddress: Codable, Equatable, Hashable, Sendable {
    public let sourceDocumentID: String
    public let sourceRange: SemanticSourceRange
    public let beatID: String?
    public let movementID: String?
    public let laneID: String?
    public let noteID: String?

    public init(
        sourceDocumentID: String,
        sourceRange: SemanticSourceRange,
        beatID: String? = nil,
        movementID: String? = nil,
        laneID: String? = nil,
        noteID: String? = nil
    ) {
        self.sourceDocumentID = sourceDocumentID
        self.sourceRange = sourceRange
        self.beatID = beatID
        self.movementID = movementID
        self.laneID = laneID
        self.noteID = noteID
    }
}

public enum ScenographicRole: String, Codable, CaseIterable, Sendable {
    case figure
    case object
    case field
    case zone
    case distance
    case threshold
    case boundary
    case axis
    case trajectory
    case void
    case witness
    case annotation
}

/// An interpreted relation supplied by the host/model. It is not source authority.
public struct ScenographicRelation: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let address: SemanticAddress
    public let role: ScenographicRole
    public let label: String

    public init(id: String, address: SemanticAddress, role: ScenographicRole, label: String) {
        self.id = id
        self.address = address
        self.role = role
        self.label = label
    }
}

public struct TeatroNormalizedRect: Codable, Equatable, Hashable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct TeatroObject: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let address: SemanticAddress
    public let role: ScenographicRole
    public let label: String
    public let frame: TeatroNormalizedRect
    public let visible: Bool

    public init(
        id: String,
        address: SemanticAddress,
        role: ScenographicRole,
        label: String,
        frame: TeatroNormalizedRect,
        visible: Bool = true
    ) {
        self.id = id
        self.address = address
        self.role = role
        self.label = label
        self.frame = frame
        self.visible = visible
    }
}

public struct TeatroComposition: Codable, Equatable, Sendable {
    public let stageID: String
    public let sourceDocumentID: String
    public let sourceDigest: String
    public let mode: String
    public let renderer: String
    public let objects: [TeatroObject]
    public let scoreDigest: String

    public init(
        stageID: String,
        sourceDocumentID: String,
        sourceDigest: String,
        mode: String,
        renderer: String,
        objects: [TeatroObject],
        scoreDigest: String
    ) {
        self.stageID = stageID
        self.sourceDocumentID = sourceDocumentID
        self.sourceDigest = sourceDigest
        self.mode = mode
        self.renderer = renderer
        self.objects = objects
        self.scoreDigest = scoreDigest
    }
}

public struct SemanticScenographerRequest: Codable, Equatable, Sendable {
    public let sourceDocumentID: String
    public let sourceDigest: String
    public let sourceRange: SemanticSourceRange
    public let context: [SemanticAddress]
    public let relations: [ScenographicRelation]
    public let mode: String

    public init(
        sourceDocumentID: String,
        sourceDigest: String,
        sourceRange: SemanticSourceRange,
        context: [SemanticAddress],
        relations: [ScenographicRelation],
        mode: String = "stage-plan"
    ) {
        self.sourceDocumentID = sourceDocumentID
        self.sourceDigest = sourceDigest
        self.sourceRange = sourceRange
        self.context = context
        self.relations = relations
        self.mode = mode
    }
}

public struct SemanticScenographerReceipt: Codable, Equatable, Sendable {
    public let instrumentID: String
    public let state: String
    public let terminal: Bool
    public let composition: TeatroComposition
    public let renderDigest: String

    public init(instrumentID: String, state: String, terminal: Bool, composition: TeatroComposition, renderDigest: String) {
        self.instrumentID = instrumentID
        self.state = state
        self.terminal = terminal
        self.composition = composition
        self.renderDigest = renderDigest
    }
}

public enum SemanticScenographerInstrumentError: Error, Equatable, Sendable {
    case missingSourceIdentity
    case invalidSourceRange
    case missingContext
    case missingRelations
    case invalidRelation(index: Int)
    case duplicateRelationID(String)
    case invalidMode
}

public protocol TeatroSVGRenderer: Sendable {
    var identifier: String { get }
    func render(_ composition: TeatroComposition) throws -> String
}

/// A deterministic, renderer-neutral Teatro-compatible SVG seam for the first kit candidate.
public struct DeterministicTeatroSVGRenderer: TeatroSVGRenderer {
    public let identifier = "teatro-svg-boundary.v1"

    public init() {}

    public func render(_ composition: TeatroComposition) throws -> String {
        let objects = composition.objects.map { object in
            let frame = object.frame
            return "<g id=\"\(escape(object.id))\" data-source=\"\(escape(object.address.sourceDocumentID))\" data-start=\"\(frameNumber(object.address.sourceRange.startLine))\" data-end=\"\(frameNumber(object.address.sourceRange.endLine))\" data-role=\"\(object.role.rawValue)\" data-label=\"\(escape(object.label))\"><rect x=\"\(frameNumber(frame.x))\" y=\"\(frameNumber(frame.y))\" width=\"\(frameNumber(frame.width))\" height=\"\(frameNumber(frame.height))\" /></g>"
        }.joined()
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 1 1\" data-stage=\"\(escape(composition.stageID))\" data-score=\"\(escape(composition.scoreDigest))\">\(objects)</svg>"
    }

    private func frameNumber(_ value: Int) -> String { String(value) }
    private func frameNumber(_ value: Double) -> String { String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value) }
    private func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

public enum SemanticScenographerInstrument {
    public static func execute(
        _ request: SemanticScenographerRequest,
        renderer: any TeatroSVGRenderer = DeterministicTeatroSVGRenderer()
    ) throws -> SemanticScenographerReceipt {
        try validate(request)
        let sorted = request.relations.sorted { $0.id < $1.id }
        let objects = sorted.enumerated().map { index, relation in
            let column = Double(index % 4)
            let row = Double(index / 4)
            return TeatroObject(
                id: relation.id,
                address: relation.address,
                role: relation.role,
                label: relation.label,
                frame: TeatroNormalizedRect(x: 0.08 + column * 0.23, y: 0.12 + row * 0.24, width: 0.17, height: 0.14))
        }
        let scoreMaterial = sorted.map { "\($0.id)|\($0.role.rawValue)|\($0.address.sourceRange.startLine)-\($0.address.sourceRange.endLine)" }.joined(separator: ";")
        let scoreDigest = digest("\(SemanticScenographerInstrumentIdentity.id)|\(request.sourceDocumentID)|\(request.sourceDigest)|\(request.mode)|\(scoreMaterial)")
        let composition = TeatroComposition(
            stageID: "semantic-scenographer-stage",
            sourceDocumentID: request.sourceDocumentID,
            sourceDigest: request.sourceDigest,
            mode: request.mode,
            renderer: renderer.identifier,
            objects: objects,
            scoreDigest: scoreDigest)
        let svg = try renderer.render(composition)
        return SemanticScenographerReceipt(
            instrumentID: SemanticScenographerInstrumentIdentity.id,
            state: "succeeded",
            terminal: true,
            composition: composition,
            renderDigest: digest(svg))
    }

    private static func validate(_ request: SemanticScenographerRequest) throws {
        guard !request.sourceDocumentID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !request.sourceDigest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SemanticScenographerInstrumentError.missingSourceIdentity
        }
        guard request.sourceRange.startLine >= 1, request.sourceRange.endLine >= request.sourceRange.startLine else {
            throw SemanticScenographerInstrumentError.invalidSourceRange
        }
        guard !request.context.isEmpty else { throw SemanticScenographerInstrumentError.missingContext }
        guard !request.relations.isEmpty else { throw SemanticScenographerInstrumentError.missingRelations }
        guard ["stage-plan", "relational-diagram", "storyboard", "temporal-score", "memory-vector"].contains(request.mode) else {
            throw SemanticScenographerInstrumentError.invalidMode
        }
        var IDs = Set<String>()
        for (index, relation) in request.relations.enumerated() {
            guard !relation.id.isEmpty, !relation.label.isEmpty,
                  relation.address.sourceDocumentID == request.sourceDocumentID,
                  relation.address.sourceRange.startLine >= request.sourceRange.startLine,
                  relation.address.sourceRange.endLine <= request.sourceRange.endLine,
                  relation.address.sourceRange.endLine >= relation.address.sourceRange.startLine else {
                throw SemanticScenographerInstrumentError.invalidRelation(index: index)
            }
            guard IDs.insert(relation.id).inserted else { throw SemanticScenographerInstrumentError.duplicateRelationID(relation.id) }
        }
    }

    private static func digest(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
