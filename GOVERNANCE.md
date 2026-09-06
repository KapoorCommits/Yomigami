# Project governance

Yomigami is maintained by [@KapoorCommits](https://github.com/KapoorCommits), who owns
the repository and has final responsibility for direction, review and releases.

## Pull requests

`.github/CODEOWNERS` assigns every path to `@KapoorCommits`. The intended `main`
protection requires a pull request, one approving review from a code owner, passing
repository checks and resolved conversations. Approvals are dismissed after new commits;
force pushes and branch deletion are disabled. The live GitHub settings are authoritative.

Outside contributors cannot merge changes simply by opening or approving a PR. Public
reviews and suggestions are welcome; required maintainer approval is a separate gate.

GitHub does not allow authors to approve their own PRs. With only one maintainer, a
maintainer-authored PR needs another authorized reviewer or an explicit owner-admin bypass.
Admin bypass is retained for that case and recovery; it is not granted to contributors.
The owner may change these policies as the maintainer team grows.
