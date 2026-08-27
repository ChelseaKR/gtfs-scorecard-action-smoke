# Changelog

All notable changes to this downstream verification repository are documented
here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Fixed

- **The smoke test could not fail on a gating regression.** Both jobs asserted
  `passed == "true"` while configuring no threshold, and the action defines
  `passed` as "true when scoring and every configured threshold passed", which
  is vacuously true when none are configured. The harness proved the action
  ran; it could not prove the action gates. A `threshold-gate` job now sets
  `min-days-to-expiry: 99999` and asserts the action fails, and the positive
  jobs configure lenient but real thresholds so their `passed` assertion means
  something. Closes #5.
- **The floating `v1` job did not test the floating alias.** It is now the one
  reference in the repository deliberately left unpinned, because a consumer
  following `@v1` is what the job exists to verify; SHA-pinning it made it a
  duplicate of the job above. `release-aliases` is a hard dependency and fails
  the run unless `v1` resolves to the expected commit, so what executes is
  known before it runs.
- **The pinned job tested a superseded commit.** `v1` resolves to
  `d800e0b4` (v1.4.0, released 2026-07-25); the workflow executed `@v1` and the
  four open branches pinned it to `715b8d5c` (v1.3.0), which would have made
  both jobs test the same commit. The pin is corrected, and a
  `latest-release-tested` job now fails when the newest published `v*` release
  is not among the commits under test, so the drift is an assertion rather
  than something to notice by hand. Closes #6.
- `tests/test-release-ref.sh` could not run on a machine with a global
  `tag.gpgsign = true`: `git tag lightweight` becomes a signed tag and git
  rejects it with "fatal: no tag message?", so the lightweight fixture could
  not be built. The fixture repository now sets its own signing config.

### Added

- A `pull_request` trigger running `local-checks`: the assertion suites and
  workflow lint. Without it a pull request that broke
  `scripts/assert-scorecard-contract.sh` would get no check at all, since the
  evidence jobs are scheduled and manual only. It needs no network, no secrets
  and no action execution, so it is safe on a forked pull request.
- A weekly schedule alongside the manual trigger. The last run before this was
  2026-07-25; evidence that waits to be remembered is not evidence.
- `release-aliases`, asserting that `v1.3.0` and `v1` resolve to the exact
  commits executed, so a version comment cannot quietly become a lie.
- Output-contract assertions: grade within A to F, score numeric and within 0
  to 100, JSON agreeing with the step outputs, HTML a standalone document.
  Replaces non-emptiness checks that a schema break would pass.
- Retained JSON and HTML evidence on every run, including failures, for 14
  days.
- Public governance baseline: LICENSE, SECURITY.md, CONTRIBUTING.md,
  CODEOWNERS, Dependabot with a release cooldown, decision records, and a
  `make verify` that runs the assertions, actionlint and zizmor.
- Every executable action reference is pinned to a full commit SHA.
