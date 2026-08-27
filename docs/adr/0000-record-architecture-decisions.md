# ADR 0000: Record architecture decisions

Status: Accepted

## Context

This repository is intentionally small, but its workflow is evidence for a
published action release. Decisions about mutable aliases, executed revisions,
feed choice, assertion semantics, token authority, and evidence retention can
change what a green run proves.

## Decision

Record consequential changes under `docs/adr/` using sequential
`NNNN-short-title.md` filenames. Each record states context, decision,
alternatives, consequences, and status. Pull-request discussion may supplement
but never replace the durable record.

## Consequences

Routine revision bumps remain changelog entries. A change to the trust or
evidence model requires an ADR that a future release reviewer can find without
reconstructing old pull-request conversations.
