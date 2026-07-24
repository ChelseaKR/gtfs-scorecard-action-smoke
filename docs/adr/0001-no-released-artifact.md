# ADR 0001: Do not publish an artifact

Status: Accepted

## Context

The repository's only purpose is to exercise an action published by the
upstream GTFS Scorecard project. Publishing this workflow as a package, action,
image, or data release would create a second version contract without adding a
consumer capability.

## Decision

Declare Release & Versioning N/A for this repository. Changes are reviewed,
recorded in the changelog, and exercised at the current main revision, but this
consumer harness does not create version tags or release artifacts. The
upstream action owns SemVer, signed tags, provenance, and release notes.

## Consequences

The workflow must identify the immutable upstream revision it executes.
Downstream evidence cites a GitHub run and commit rather than a release of this
repository. If this repository ever publishes a reusable artifact, this
decision is superseded and the full release standard applies before the first
tag.
