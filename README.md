<!-- updated :: 2026-05-03 14:53:00 -->

# UDM: Universal Download Manager

UDM is a high-performance, multi-threaded command-line download manager built with Dart. It is designed to maximize your bandwidth by utilizing concurrent streams while maintaining a robust fallback system for non-resumable servers.

## Tech Stack
| Technology | Description | Icon |
| :--- | :--- | :--- |
| **Dart** | High-performance programming language | <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/dart/dart-original.svg" alt="dart" width="20" height="20"/> |
| **Flutter** | UI Framework (Planned for desktop/mobile versions) | <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" alt="flutter" width="20" height="20"/> |

## Key Features
- **Parallel Segment Downloads**: Utilizes Dart Isolates to download multiple file segments simultaneously, bypassing single-connection speed limits.
- **Smart Protocol Detection**: Automatically performs a HEAD request to detect if the server supports range requests (`Accept-Ranges: bytes`).
- **Resilient Fallback**: If multi-threading is unsupported or fails, UDM seamlessly transitions to a reliable single-stream download.
- **Intelligent Filename Resolution**: Resolves the best filename by checking Content-Disposition headers, the URL path, and user overrides.
- **Interactive CLI Dashboard**: Real-time progress bars for each thread, overall speed metrics, and ETA calculations.
- **Disk Pre-allocation**: Truncates the target file to the expected size before downloading to ensure disk space availability and reduce fragmentation.

## Getting Started

### Prerequisites
- Dart SDK `^3.0.0`
- Flutter SDK (Optional, for UI components)

### Installation
```bash
# Clone the repository
git clone https://github.com/Utsav-56/udm.git
cd udm

# Fetch dependencies
dart pub get
```

### Usage
Run the CLI tool directly using the Dart VM:
```bash
dart bin/udm.dart [options] <url>
```

#### CLI Arguments
| Argument | Description | Example |
| :--- | :--- | :--- |
| `-h`, `--help` | Prints usage information. | `dart bin/udm.dart --help` |
| `-v`, `--verbose` | Enables detailed internal logging. | `dart bin/udm.dart --verbose <url>` |
| `--version` | Prints the current tool version. | `dart bin/udm.dart --version` |

<!-- <details>
<summary>📸 View CLI Dashboard Preview</summary>

[PLACEHOLDER: Add a GIF of the terminal progress bars here]
</details> -->

## For Developers
Detailed architectural information, coding standards, and contribution guides can be found in [developer-docs.md](developer-docs.md).

## Building from Source
For a step-by-step guide on how to compile and install UDM on your local machine, refer to [building.md](building.md).
