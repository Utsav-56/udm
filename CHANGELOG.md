## [1.2.0] - 2026-05-05
### Changed
- Refactored `ManagerPreferences` into a standalone `freezed` class with `json_serializable` support.
- Moved `FileTypeEntry` and `FileTypePreference` to dedicated model files.
- Improved persistence logic for manager settings with automated JSON encoding/decoding.
- Cleaned up `DownloadManager` by extracting model definitions.

## [1.1.0] - 2026-05-03
### Added
- Comprehensive project-wide documentation: `README.md`, `developer-docs.md`, and `building.md`.
- Explanatory docstrings added to all major Dart entities following `dart-coding-practice` standards.

### Changed
- Improved code clarity and internal documentation for better maintainability.

## [1.0.0] - 2026-04-08
### Added
- Initial project structure and core multi-stream download logic.
