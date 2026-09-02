# Changelog

All notable changes to this downstream verification repository are documented
here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

- **`unscorable-feed`, a second negative job.** `threshold-gate` asks whether a
  measured feed that breaches a threshold is refused; this asks what happens
  when there is nothing to measure. It hands the action
  `tests/fixtures/not-a-gtfs-feed.zip` — a well-formed zip with no GTFS files
  — with no thresholds configured, so a failure can only mean the feed could
  not be scored, and asserts `grade`, `score` and `days-to-expiry` all came
  back blank. A number nobody measured is worse than an error, because it
  looks like an answer. The job first proves the fixture is still served and
  still not a GTFS feed, so a dead link cannot keep it red while silently
  changing what it tests. Injecting an unreadable feed was one of the four
  fault-injection cases, and the action refused it correctly; this makes that
  a standing assertion rather than a one-off observation.

### Fixed

- **`days-to-expiry` was the one published output nothing asserted.** The
  action documents it as blank when unavailable, so a missing measurement
  arriving as `0` would read as "expires today" *and* would satisfy the
  `min-days-to-expiry: 0` threshold the positive jobs configure — nothing in
  the workflow would have noticed. `assert-scorecard-contract.sh` now checks
  it in both directions: a value must be an integer that matches the artifact,
  and a blank must mean the artifact measured nothing either. A blank that
  discards a real measurement is the same bug wearing different clothes.

### Verified

- **The harness was measured rather than assumed.** "Written so that a broken
  action makes it red" had never been tested, and a smoke test that cannot
  fail is worse than none because it manufactures confidence. Four defects
  were injected one at a time on
  `experiment/prove-the-smoke-can-fail` and dispatched against the real action
  and the real feed. All four produced red, with the intended annotation:
  moving `V1_4_0_COMMIT` to the superseded v1.3.0 commit reddened
  `release-aliases` and `latest-release-tested` and *skipped* the three jobs
  that execute the action ([run 33584831710]); giving `threshold-gate` a
  threshold the feed meets reddened it with "the gate is not gating"; reading
  a removed action output reddened `protected-release` at `${GRADE:?}`; and
  pointing `floating-major` at a URL that is not a GTFS zip made the action
  refuse it rather than publish a plausible grade for a feed it could not read
  ([run 33584723021]). The evidence table is in the README.

[run 33584831710]: https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/actions/runs/33584831710
[run 33584723021]: https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/actions/runs/33584723021

### Fixed

- **Version comments beside SHA pins were unchecked.** This repository already
  refuses to let the action under test drift from its version comment, but
  applied no such rule to its own tooling pins — and the gap was not
  hypothetical: Dependabot's checkout 4.3.1 → 7.0.1 bump (#8) rewrote five
  SHAs and left every `# v4` comment behind, so each pin and its comment
  disagreed until a human noticed. `scripts/assert-pinned-versions.sh`
  resolves every comment against the upstream tag and fails when they
  disagree, when a pin carries no comment at all, or when a reference is not
  SHA-pinned without the `zizmor: ignore[unpinned-uses]` annotation that marks
  `floating-major`'s alias as an argued exception. A remote it cannot reach is
  reported as `UNVERIFIED`, never as "that tag does not exist": a failed read
  is not a finding.
- **CI ran a hand-copied subset of the declared gate.** `local-checks` inlined
  two of the Makefile's commands and omitted zizmor entirely, so the security
  audit ran only on a contributor's laptop and the `zizmor: ignore` waiver in
  the workflow was never exercised by anything that could block a merge. CI
  now installs both linters — each a version-pinned, checksum-verified release
  tarball — and runs `make verify` itself, so there is one gate definition
  instead of two that can drift.
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
