# Contributing

Thank you for helping improve Japanese Receipt Parser.

## Before opening an issue

- Remove or replace all real names, addresses, phone numbers, membership IDs, invoice IDs, and purchase details.
- Never attach a real receipt image. Reproduce the issue with synthetic OCR text.
- Search existing issues before opening a new one.

## Development workflow

1. Fork the repository and create a focused branch.
2. Add a synthetic fixture or unit test that demonstrates the behavior.
3. Keep parsing deterministic and explain any new heuristic.
4. Run `swift build` and `swift test`.
5. Open a pull request describing false-positive and false-negative tradeoffs.

Changes that introduce network access, telemetry, third-party dependencies, or automatic use of unconfirmed values require prior discussion in an issue.

By contributing, you agree that your contribution is licensed under the MIT License.
