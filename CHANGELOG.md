# Changelog

## Unreleased candidate — 2026-11-10

- Added source-addressed dramatic-score semantic MIDI2 candidate contract
  `fountaincoach.semantic-score-midi@0.1.0`, using existing IDL
  `fountainstore/document.put` and `stage/midi.events.put` topics.
- Added 64-bit UMP CC candidate encoder for explicitly author-proposed sound cues,
  deterministic source-index chunking and SHA-256 receipts, scoped source identity
  validation, stale/duplicate cue refusal, and non-sonic source preservation.
- Added `fountain-score-midi-project` native Swift candidate generator, scenario
  YAML/checked JSON, nine focused tests including a private original-source
  fixture. All existing kit tests remain passing.
- No new IDL operation, MIDI-CI standard profile, Reframe live invocation,
  MIDI output, public production, FCIS-KIT release or hardware acceptance.


## 0.1.0 — 2026-08-24

Initial FCIS-KIT candidate:

- typed source-addressed Semantic Scenographer request and receipt;
- structured Teatro composition with stable object identities and spatial roles;
- injectable deterministic SVG renderer boundary;
- source-range, semantic-context, duplicate-identity, mode, and invalid-input validation;
- focused deterministic lifecycle and digest tests.

This is an implementation candidate, not an admitted, released, publicly catalogued, security-reviewed, hardware,
provider, or production claim.
