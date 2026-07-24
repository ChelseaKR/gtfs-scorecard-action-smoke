# GTFS Scorecard Action smoke test

This repository is a downstream consumer of the
[GTFS Scorecard GitHub Action](https://github.com/ChelseaKR/gtfs-scorecard).
Its manual and weekly scheduled workflow verifies both the protected patch
release and the floating major release against the same public GTFS Schedule
feed. Action execution is pinned to the immutable commits resolved from those
tags. Each job must produce a numeric score, letter grade, JSON artifact, and
standalone HTML scorecard.

Runs are bounded to 20 minutes and retain their JSON/HTML evidence for 14 days.
The schedule detects downstream breakage even when no release is in progress;
manual dispatch remains available for release review.

This is release evidence, not a health claim about the example feed.
