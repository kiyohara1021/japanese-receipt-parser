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

- Receipt titles such as 領収書, レシート and お客様控え, and greetings such as いらっしゃいませ, are no longer chosen as the merchant name. A merchant whose name merely contains one of these words is still recognized.

[Unreleased]: https://github.com/kiyohara1021/japanese-receipt-parser/commits/main
