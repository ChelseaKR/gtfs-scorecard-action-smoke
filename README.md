# GTFS Scorecard Action smoke test

This repository is a downstream consumer of the
[GTFS Scorecard GitHub Action](https://github.com/ChelseaKR/gtfs-scorecard).
It exists to prove the action works when consumed from somewhere other than
its own repository, which an in-repo job cannot prove.

This is release evidence, not a health claim about the example feed.

## What the workflow verifies

Five jobs, each written so that a broken action makes it red.

| Job | What it proves |
|---|---|
| `release-aliases` | `v1.4.0` and `v1` still resolve to the exact commits the jobs below execute. A moved alias fails here, before anything runs. |
| `latest-release-tested` | The newest published `v*` release is among the commits under test. A new release that nothing here exercises fails the run. |
| `protected-release` | The current release, SHA-pinned, scores the feed and satisfies its configured thresholds. |
| `floating-major` | The same feed through an unpinned `@v1`, which is what the flagship README tells consumers to write. |
| `local-checks` | `make verify`: the assertion scripts, the pinned-version check, workflow lint and the zizmor audit. The only job a pull request runs, since it needs no secrets and no action execution. |
| `threshold-gate` | The action **fails** when given a threshold nothing can meet. |

That last job is the one that makes the rest meaningful. The action documents
`passed` as "true when scoring and every configured threshold passed", so
asserting `passed == "true"` while configuring no thresholds asserts nothing:
with none configured it is vacuously true. Both jobs did exactly that until
this change, so the harness proved the action *ran* and could never prove the
action *gates*.

The negative job sets `min-days-to-expiry: 99999`, roughly 273 years. No
published GTFS calendar reaches it, so the threshold is unmeetable by
construction. A grade threshold would be the wrong instrument: if the example
feed improved, a `min-grade: A` negative test would begin passing silently and
stop testing anything.

The positive jobs configure deliberately lenient thresholds, `min-grade: F`
and `min-days-to-expiry: 0`. That exercises the threshold path without tying
the smoke to the example feed's quality, so an ordinary feed change cannot
masquerade as an action regression.

## Measured, not asserted

"Written so that a broken action makes it red" is a claim, and a smoke test
that cannot fail is worse than no smoke test because it manufactures
confidence. So the claim was measured: four defects were injected one at a
time on
[`experiment/prove-the-smoke-can-fail`](https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/commits/experiment/prove-the-smoke-can-fail)
and dispatched against the real action and the real feed.

| Injected | Result |
|---|---|
| `V1_4_0_COMMIT` moved to the v1.3.0 commit — the alias drift the guard exists to catch | [red](https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/actions/runs/33584831710). `release-aliases`: "tag v1.4.0 resolved to d800e0b4, expected 715b8d5c". `latest-release-tested` also red. The three jobs that execute the action were **skipped**, so nothing ran against an unverified commit. |
| `threshold-gate` given a threshold the feed meets, i.e. the gate stops gating | [red](https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/actions/runs/33584723021): "The action succeeded against an unmeetable threshold … the gate is not gating." |
| `protected-release` reads an action output that no longer exists | [red](https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/actions/runs/33584723021): `GRADE` arrives empty and `${GRADE:?}` fails closed. |
| `floating-major` pointed at a URL that is not a GTFS zip | [red](https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/actions/runs/33584723021): the action refuses it — "GTFS feed could not be scored" — rather than publishing a plausible grade for a feed it could not read. |

Four for four. The harness fails when it should.

## Trust boundary

- Read-only repository permission, no secrets.
- Every executable action reference is a full commit SHA, with one deliberate
  exception. `floating-major` uses `@v1` unpinned, because a consumer
  following that alias is precisely what the job exists to verify: pinning it
  would replace the thing under test with a copy of the job above it. The risk
  is bounded rather than ignored, since `release-aliases` is a hard dependency
  and fails the run unless `v1` resolves to the expected commit, so what
  executes is known before it runs. No secrets, `contents: read` only.
- Every pin carries a version comment, and `make verify` resolves each comment
  against the upstream tag. A 40-character hash is only reviewable through its
  comment, and Dependabot's checkout 4.3.1 → 7.0.1 bump (#8) rewrote five
  SHAs while leaving every `# v4` comment in place, so the pins and their
  comments disagreed until a human caught it. That is now a check rather than
  a hope. A reference that is *not* SHA-pinned must be annotated
  `zizmor: ignore[unpinned-uses]`, which keeps `floating-major` an argued
  exception and stops an unannotated one appearing beside it.
- The example feed is public and replaceable. Its score is not a performance
  target and not an endorsement.

## Running it

Hosted, and authoritative:

```sh
gh workflow run verify.yml --repo ChelseaKR/gtfs-scorecard-action-smoke
gh run watch --repo ChelseaKR/gtfs-scorecard-action-smoke
```

It also runs weekly on a schedule. Evidence that waits for someone to remember
to click it is not evidence; before the schedule was added, the last run was
2026-07-25.

Locally:

```sh
make verify
```

`make verify` is the single definition of the gate: `local-checks` runs that
exact target rather than a hand-copied list of its steps, so a green laptop
and a green pull request mean the same thing. It exercises the assertion
scripts against passing and deliberately malformed fixtures, resolves every
pinned action reference against its version comment, lints the workflow and
runs the zizmor audit. It cannot execute GitHub Actions or reach the live feed
through the action, so it proves the assertions behave, not that the action
does.

## When a run goes red

Triage before changing an assertion. Determine whether the public feed changed,
the action regressed, or an expected release revision moved. Preserve the run
URL and the retained artifacts in the pull request. Do not weaken a failing
assertion to restore green: a harness that is edited until it passes is the
thing this repository was rebuilt to stop being.

See [Contributing](CONTRIBUTING.md), the [security policy](SECURITY.md), and the
[decision log](docs/adr/0000-record-architecture-decisions.md).
