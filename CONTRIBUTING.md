# Contributing to Yomigami

Thank you for helping make Kindle reading better. Yomigami is an early native app;
small, well-tested improvements are easier to review than broad rewrites.

## Before you start

Read the [architecture](docs/ARCHITECTURE.md), [build guide](docs/BUILDING.md) and
[verification record](docs/VERIFICATION.md). Open an issue before a large behavior change.
Bug fixes, device compatibility evidence, accessibility and clear documentation are welcome.

## Submit a change

1. Fork the repository and create a branch from `main`.
2. Keep the change focused. Preserve users’ books, settings and reading progress.
3. Run `python3 scripts/check_repository.py`; run the native tests relevant to any reader change.
4. Explain the problem, resulting behavior and test evidence in your pull request.
5. Wait for review from `@KapoorCommits`. New commits dismiss previous approval.

Do not commit account credentials, logs containing private information, device dumps,
downloaded chapters, third-party ebooks, generated packages or local data directories.
Use original test fixtures. Do not claim physical device validation based on an emulator run.

## Licensing and attribution

Contributions are accepted under AGPL-3.0-or-later for Yomigami code. Keep upstream
notices, identify code adapted from another project, and state its source and license.
Only contribute material you have permission to contribute. No CLA is currently required.

## Reporting a problem

Include the Kindle model, firmware, Yomigami version, steps, expected behavior and actual
behavior. A small original fixture is ideal. Redact logs before attaching them. Report
security-sensitive issues using the [security policy](SECURITY.md), not a public issue.
