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
| `release-aliases` | `v1.3.0` and `v1` still resolve to the exact commits the jobs below execute. A moved alias fails here, before anything runs. |
| `latest-release-tested` | The newest published `v*` release is among the commits under test. A new release that nothing here exercises fails the run. |
| `protected-release` | The current release, SHA-pinned, scores the feed and satisfies its configured thresholds. |
| `floating-major` | The same feed through an unpinned `@v1`, which is what the flagship README tells consumers to write. |
| `local-checks` | The assertion scripts and workflow lint. The only job a pull request runs, since it needs no network, no secrets and no action execution. |
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

## Trust boundary

- Read-only repository permission, no secrets.
- Every executable action reference is a full commit SHA, with one deliberate
  exception. `floating-major` uses `@v1` unpinned, because a consumer
  following that alias is precisely what the job exists to verify: pinning it
  would replace the thing under test with a copy of the job above it. The risk
  is bounded rather than ignored, since `release-aliases` is a hard dependency
  and fails the run unless `v1` resolves to the expected commit, so what
  executes is known before it runs. No secrets, `contents: read` only.
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

Local verification exercises the assertion scripts against passing and
deliberately malformed fixtures, and lints the workflow. It cannot execute
GitHub Actions or reach the live feed, so it proves the assertions behave, not
that the action does.

## When a run goes red

Triage before changing an assertion. Determine whether the public feed changed,
the action regressed, or an expected release revision moved. Preserve the run
URL and the retained artifacts in the pull request. Do not weaken a failing
assertion to restore green: a harness that is edited until it passes is the
thing this repository was rebuilt to stop being.

See [Contributing](CONTRIBUTING.md), the [security policy](SECURITY.md), and the
[decision log](docs/adr/0000-record-architecture-decisions.md).
