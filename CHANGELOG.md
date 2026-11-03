# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- On-device OCR backed by Apple Vision
- Deterministic Japanese merchant and total candidate extraction
- CLI support for OCR text files, standard input, and images
- Anonymous Japanese receipt fixtures and tests
- English and Japanese documentation

### Fixed

- Dates with a two-digit year (`25/10/01`), Japanese era dates (`令和7年10月1日`, `R7.10.1`, `令和元年`), and month/day with a weekday (`10/01(水)`) are removed before parsing, so they are neither chosen as the merchant name nor read as amounts.

[Unreleased]: https://github.com/kiyohara1021/japanese-receipt-parser/commits/main
