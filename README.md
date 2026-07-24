# GTFS Scorecard Action smoke test

This repository is a downstream consumer of the
[GTFS Scorecard GitHub Action](https://github.com/ChelseaKR/gtfs-scorecard).
Its manual workflow verifies both the protected patch release and the floating
major release against the same public GTFS Schedule feed. The executed action
references are immutable commits; their public-tag resolution is verified
before those pins are updated. Each job must produce a
numeric score, letter grade, JSON artifact, and standalone HTML scorecard.

This is release evidence, not a health claim about the example feed.

## Local verification

Run `make verify` to exercise the output-contract assertions against both
passing and deliberately malformed fixtures. The hosted workflow additionally
executes the published action against the live public feed.
