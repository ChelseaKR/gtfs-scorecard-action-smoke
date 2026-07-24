# GTFS Scorecard Action smoke test

This repository is a downstream consumer of the
[GTFS Scorecard GitHub Action](https://github.com/ChelseaKR/gtfs-scorecard).
Its manual workflow verifies both the protected patch release and the floating
major tag against the same public GTFS Schedule feed. Each job must produce a
numeric score, letter grade, JSON artifact, and standalone HTML scorecard.

This is release evidence, not a health claim about the example feed.

## Quick start

Inspect and lint the workflow locally:

```sh
make verify
```

Run the hosted smoke from GitHub:

```sh
gh workflow run verify.yml --repo ChelseaKR/gtfs-scorecard-action-smoke
gh run watch --repo ChelseaKR/gtfs-scorecard-action-smoke
```

The hosted run is authoritative because it executes the published action
against the live public feed. Local lint proves workflow structure and trust
configuration, not the downstream action behavior.

## Operating boundary

- The workflow has read-only repository permission and no secrets.
- Executable action references are full commit SHAs. Version comments identify
  the release or alias resolution being tested.
- The example feed is public and replaceable; its score is not a performance
  target or endorsement.
- A failed run is triaged before an expected revision or assertion changes.

See [Contributing](CONTRIBUTING.md), the [security policy](SECURITY.md), and the
[decision log](docs/adr/0000-record-architecture-decisions.md).

## Standards Conformance

| Standard | Status | Evidence / scope |
| --- | --- | --- |
| Responsible-Tech Framework | Applies | Public-feed boundary, non-endorsement language, least authority, and the upstream/downstream reporting split |
| AI Development Measurement | Applies; measurement pending | Pull requests preserve delivery and remediation evidence; no local AI-tool telemetry is collected yet |
| Code Quality | Applies | `actionlint` and zizmor are required for workflow changes; executable refs are immutable |
| Security & Supply-Chain | Applies | [Security policy](SECURITY.md), read-only token, SHA-pinned actions, and CODEOWNERS |
| CI/CD | Applies | `.github/workflows/verify.yml` is the product and the hosted smoke is its integration gate |
| Release & Versioning | N/A — no released artifact | [Accepted decision](docs/adr/0001-no-released-artifact.md); this repository consumes upstream releases but publishes no package, image, action, or versioned data product |
| Accessibility | N/A — no owned UI | The repository ships no HTML interface; generated upstream HTML is retained only as test evidence |
| Observability | Applies at scheduled-job tier | GitHub run status and logs identify downstream availability and assertion failures |
| Performance | N/A — no interactive runtime | Job duration is operational evidence, not an end-user latency or throughput contract |
| Internationalization | N/A — operator-only harness | [Committed scope decision](docs/I18N.md) |
| AI Evaluation | N/A — no AI runtime | No model, prompt, retrieval, judge, or generated-answer path is present |
| Documentation | Applies | README, changelog, contribution guide, security policy, license, CODEOWNERS, and ADR log |
| Quality & Metrics | Applies | A green hosted run requires numeric score, grade, pass state, JSON, and standalone HTML |
| Incident Response | Applies | [Private reporting and disable/rotate/preserve response](SECURITY.md) |
| Data Governance | N/A — no retained user data | The job processes one public GTFS feed ephemerally and stores no user, account, or private source data |
