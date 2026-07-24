# GTFS Scorecard Action smoke test

This repository is a downstream consumer of the
[GTFS Scorecard GitHub Action](https://github.com/ChelseaKR/gtfs-scorecard).
Its manual workflow first proves that the protected patch tag and floating
major tag resolve to the expected immutable commits. It then executes those
commits against the same public GTFS Schedule feed. Each job must produce a
numeric score, letter grade, JSON artifact, and standalone HTML scorecard.

This is release evidence, not a health claim about the example feed.

## Local verification

Run `make verify` to test lightweight-tag resolution, annotated-tag peeling,
missing tags, mismatched commits, and workflow structure without contacting
GitHub. The hosted workflow performs the same assertion against the public
upstream repository before either action job receives execution authority.
