# Contributing

This repository verifies the published GTFS Scorecard action from the point of
view of a minimal downstream consumer.

Before opening a pull request:

1. run `make verify`, which is the same target CI runs, so a green laptop and
   a green pull request mean the same thing;
2. keep `permissions` read-only, pin every executable action reference to a
   full commit SHA, and give each pin a version comment naming the tag that
   SHA actually is — `make verify` resolves every comment against the upstream
   tag and fails when the two disagree;
3. update the changelog for a workflow-contract or evidence-policy change; and
4. explain whether a hosted manual run is needed, because local validation
   cannot execute GitHub Actions or reach the live feed through the action.

Do not weaken a failing assertion merely to restore green status. Determine
whether the public feed changed, the action regressed, or the expected release
revision moved, and preserve the run URL and artifacts in the pull request.
