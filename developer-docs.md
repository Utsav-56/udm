<!-- updated :: 2026-05-03 14:53:00 -->

# UDM Developer Documentation

This document provides a deep dive into the architecture, coding principles, and internal mechanics of the Universal Download Manager (UDM).

## Architectural Overview

UDM follows a modular, isolate-based architecture to ensure high performance and UI responsiveness.

### Core Components
1. **HeadParser**: Responsible for initial server communication to determine file metadata (size, type, range support).
2. **MultiStreamDownload**: The orchestrator that divides the file into ranges and manages worker isolates.
3. **Worker Isolates**: Independent Dart processes that handle individual segment downloads and disk I/O.
4. **Messenger**: A robust communication layer using `SendPort` and `ReceivePort` to sync progress between workers and the main thread.
5. **DownloadStatus**: The central state machine tracking telemetry (speed, ETA, progress).

## 🌊 Data Flow
1. **Initiation**: `main()` creates a `DownloaderConfig` and initializes `MultiStreamDownload`.
2. **Metadata Fetch**: `sendHeadRequest` retrieves file headers.
3. **Allocation**: The main thread creates the target file and truncates it to the full size to reserve disk space.
4. **Isolate Spawning**: Based on `threadCount`, multiple `downloadWorker` isolates are spawned.
5. **Download Loop**: Each worker performs a range GET request and writes data to its assigned file offset.
6. **Progress Sync**: Workers send periodic `ProgressMessage` objects to the main thread.
7. **Finalization**: Once all threads finish, the main thread cleans up resources and closes file handles.

## Folder Structure
| Directory | Responsibility |
| :--- | :--- |
| `lib/downloader/` | Core download implementations (Multi/Single stream). |
| `lib/models/` | Data models and configuration schemas. |
| `lib/helpers/` | Cross-platform utilities for paths, terminal, and extensions. |
| `bin/` | CLI entry point and argument parsing. |

## 🛠️ Coding Principles
This project strictly adheres to the **`dart-coding-practice`** standards:
- **Explanatory Docstrings**: Every entity must explain *Why* it exists and *How* to use it.
- **DRY & Modular**: Business logic is never mixed with UI/CLI presentation.
- **Isolate Safety**: All communication between isolates must be serializable and robust against race conditions.

## ➕ Adding New Features
### How to add a new Downloader Type (e.g., FTP)
1. **Create the Model**: Add any specific FTP configuration to `DownloaderConfig`.
2. **Implement the Downloader**: Create `FtpDownloader` in `lib/downloader/` extending the `Downloader` base class.
3. **Handle Entry**: Update the factory logic in the entry point to instantiate your new class when an FTP URL is detected.

## Common Pitfalls & Troubleshooting
- **Isolate Desynchronization**: Ensure that `DownloadStatus` is updated via messages; do not attempt to share mutable memory between isolates.
- **File Access Conflicts**: Only one isolate should hold a `FileMode.writeOnly` handle to a specific file range at a time (UDM handles this by seeking to unique offsets).
