# Security policy

## Supported surface

This repository contains a downstream GitHub Actions smoke workflow. It does
not deploy a service, accept user accounts, or publish a package. Security
reports in scope here include workflow-token exposure, unsafe expression or
shell handling, unexpected artifact disclosure, and a discrepancy between the
documented and executed GTFS Scorecard action revision.

Vulnerabilities in the GTFS Scorecard action itself should be reported through
the upstream project's
[private vulnerability reporting](https://github.com/ChelseaKR/gtfs-scorecard/security/advisories/new).

## Reporting

Report vulnerabilities in this repository through
[private vulnerability reporting](https://github.com/ChelseaKR/gtfs-scorecard-action-smoke/security/advisories/new).
Do not include secrets, exploit details, or sensitive URLs in a public issue.

Expect acknowledgement within 72 hours and, for high-severity findings, a fix
or concrete remediation plan within 14 days.

## Response

The maintainer will disable the affected workflow if continued execution could
expose credentials or run untrusted code, rotate any exposed credential,
preserve the relevant run metadata, and document the cause and corrective
control before re-enabling the smoke.
