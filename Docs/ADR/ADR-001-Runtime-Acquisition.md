# ADR-001: Runtime Acquisition

## Status

Proposed for future runtime sprints.

## Context

Sprint 1 creates the MacPlay Launcher project skeleton, models, persistence, UI shell, tests, and documentation. It intentionally does not choose or implement a Wine runtime source.

## Decision

Wine runtime acquisition is not implemented in Sprint 1.

Future runtime acquisition options are:

- Trusted community Wine build.
- Bundled Wine runtime.
- Self-built and self-hosted Wine runtime.

All future runtime downloads must require checksum verification before extraction or use.

## Consequences

- Sprint 1 can build and test without runtime binaries.
- Later sprints must make a separate, reviewable runtime supply-chain decision.
- Runtime implementation must include checksum validation before any installation flow is accepted.

