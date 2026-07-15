# GTFS Scorecard Action smoke test

This repository is a downstream consumer of the
[GTFS Scorecard GitHub Action](https://github.com/ChelseaKR/gtfs-scorecard).
Its manual workflow verifies both the protected patch release and the floating
major tag against the same public GTFS Schedule feed. Each job must produce a
numeric score, letter grade, JSON artifact, and standalone HTML scorecard.

This is release evidence, not a health claim about the example feed.
