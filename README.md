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

## Source-addressed dramatic-score MIDI candidate (2026-11-10)

`SemanticScoreMIDIInstrument.project` adds a reusable, **non-executing** bridge for
Fountain Press dramatic scores. Instrument identity:
`fountaincoach.semantic-score-midi@0.1.0` (candidate only).
It consumes a source-authorized `fountain.press.semantic-midi-event-projection.v1`
JSON record with a **caller-pinned source Git revision and PDF SHA-256**. It preserves
original page/line ranges, source-block hashes, voices, complete non-sonic passages,
compound scene/light/sound cue identities, and explicitly authored timing where available.
It does not infer a tempo, schedule, MIDI notes, stage action, or voice recording.

Only selected sound cues with a declared **non-authorial rehearsal mapping** become
MIDI 2.0 64-bit UMP Control Change *candidates*. The group/channel, parameter,
source address, two UMP words, and original cue identity remain inspectable.
These mappings use Fountain Coach's `wind_mix`, `turbulence_mix`, `head_mix`,
`voice_mix` extensions (CC70–73) and are **not** MIDI Association standard
semantic assignments. Scene and lighting cues remain source events, not notes.

The kit does not own MIDI2 transport, sound output, FountainStore, permissions,
authorial decisions, or Reframe's Swift MIDI2 Monitor. It produces only two
host-executable request payload classes whose topics are already declared by
the MIDI backplane IDL:

- `fountainstore/document.put`: deterministic, bounded source-event index parts
  with source identity, original cue links and source-line hashes; **no manuscript text**.
- `stage/midi.events.put`: optional source-linked UMP CC packet proposals, with
  `executionState=not-dispatched` until a host actually executes them.

The optional Swift CLI `fountain-score-midi-project` writes those immutable
candidate parts, their digests and a receipt explicitly stating that neither
Store writes nor MIDI emission happened. It refuses to overwrite existing output.

Run the focused test suite with `swift test --filter SemanticScoreMIDIInstrumentTests`
from this package; `swift test` tests the existing Scenographer and Semantic
Factory behaviors too. Private original-score tests are opt-in via
`FCIS_SCORE_MIDI_SOURCE_JSON=/path/to/authorized/semantic-midi.json` and never
bundle the source. The versioned candidate scenario and its checked JSON are in
`Scenarios/semantic-score-midi-instrument.{yaml,json}`.

The original private *Between Gardens* source evaluated to **327 source
passages, 536 source lines, 32 cue identities, and 16 non-authorial CC
proposals**. The CLI produced two ~60 KB source-index parts and one ~6 KB
MIDI-event part. Subsequent **isolated native FountainStoreInstrument** tests
persisted and read those source-index events and MIDI-event candidates using
the existing IDL operations, but no Reframe live peer dispatch, AX/window-ID,
FountainStore lifecycle terminal receipt, hardware interaction, or instrument
release was established. See the owned `PLANS.md` and the host candidate
scenario in `midi2-gpu-fabric/apps/modernization-studio/LiveScenarios`.
