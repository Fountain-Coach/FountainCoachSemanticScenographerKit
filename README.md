# Fountain Coach Semantic Scenographer Kit

FCIS-KIT candidate for `fountaincoach.semantic-scenographer@0.1.0`.

The kit turns a source-addressed semantic proposal into a structured Teatro composition and a deterministic SVG
render. It carries source document identity and exact ranges, beat/movement/lane/note addresses, spatial roles, and
stable object identities. It never copies manuscript text, reads FountainStore, selects a provider, owns Reframe UI,
or mutates source or uncertainty state.

## Contract

`SemanticScenographerInstrument.execute(_:)` accepts an exact source identity and range, admitted semantic addresses,
typed scenographic relations, and a declared mode. It returns a structured `TeatroComposition` with traceable objects,
a score digest, a deterministic render digest, and terminal lifecycle state. The `TeatroSVGRenderer` protocol keeps
the renderer injectable; the default `DeterministicTeatroSVGRenderer` is the reproducible SVG boundary for this
candidate.

The Reframe consumer owns Copilot mediation, Source View and UncertaintyScoreKit authority, MIDI2 transport,
FountainStore persistence, AX projection, permissions, and product policy. This package is a semver-ready candidate;
admission, release, publication, and live acceptance remain separate decisions.

## Scenario

The authoring scenario is declared in `Scenarios/semantic-scenographer-instrument.yaml` and its checked JSON
projection. It is candidate-only and makes no provider, security, hardware, or production claim.

## Validation

```sh
swift test --package-path kits/FountainCoachSemanticScenographerKit
```
