# Prompt for AI Agent: Flutter Download Manager (UDM) UI Development

You are an **Expert Flutter UI/UX Architect** tasked with designing and implementing a high-performance, premium user interface for **UDM (Universal Download Manager)**. 

The goal is to create a UI that rivals (and surpasses) the functional power of Internet Download Manager (IDM) while delivering a modern, visually stunning, and smooth experience using Flutter.

---

<context>
## Project Overview: UDM
UDM is a multi-threaded download manager written in Dart/Flutter. 
The core logic is already implemented, featuring:
- `Downloader`: Base class for managing downloads.
- `DownloadStatus`: A detailed status model containing `totalSize`, `totalBytesDownloaded`, `bytesPerSecond`, `progressPercent`, `eta`, and `state` (initial, downloading, paused, cancelled, completed).
- Support for multi-stream downloads with segment-level tracking.

Your task is to build the **frontend** layer that connects to this logic and provides a "pro-grade" experience.
</context>

<aesthetic_direction>
## Visual & UX Philosophy
Move away from generic AI-generated styles. We want a **"Powerful & Premium"** aesthetic:
- **Style**: Sleek Dark Mode (with a Light Mode alternative). Consider **Glassmorphism** or **Neumorphism** for control panels.
- **Color Palette**: Deep midnight backgrounds with vibrant neon accents (e.g., Electric Blue for progress, Magenta for warnings, Emerald for completed).
- **Typography**: Use a distinctive, modern font pair (e.g., *Outfit* for headers, *JetBrains Mono* for technical metrics).
- **Motion**: Every action should feel reactive. Use staggered list animations, smooth hero transitions between list and details, and "pulsing" effects for active downloads.
- **Layout**: A clean sidebar for categories, a spacious main dashboard for the download list, and a detailed "segment map" visualization for multi-threaded progress.
</aesthetic_direction>

<instructions>
## Implementation Roadmap

### 1. Design System & Theming
- Establish a comprehensive `ThemeData` including custom `ColorSchemes` and `TextThemes`.
- Create a set of "Atomic Components": Premium Progress Bars (with gradients and glows), Custom Action Buttons, and Status Badges.

### 2. Main Dashboard (The "Command Center")
- **Sidebar**: Categories (All, Downloading, Finished, Queued, Cancelled, Scheduled).
- **Download List**: A high-density but readable list/grid. Each item shows:
    - File Name & Extension Icon.
    - Dynamic Progress Bar with percentage.
    - Real-time metrics: Speed (KB/s), Size (Downloaded/Total), ETA.
    - Quick actions: Pause/Resume, Cancel, Open Folder.
- **Top Bar**: "Add New", "Start All", "Stop All", "Settings", and a Global Search.

### 3. "Add New Download" Interface
- A refined modal or side-drawer.
- Input fields: URL (with auto-paste detection), Filename (auto-resolved from URL), Save Path (with folder picker), and Category.
- A "Grab Info" button that triggers a HEAD request to show file size/type before starting.

### 4. Detail View (The "X-Ray")
- A drill-down view for an active download.
- **Segment Map**: A visual grid representing the multi-threaded segments, showing individual progress for each thread.
- **Logs View**: A collapsible terminal-style view showing real-time downloader events.
- **Speed Graph**: A micro-chart showing speed fluctuations over time.

### 5. Settings & Configuration
- Interface to tweak `threadCount`, `progressSyncInterval`, and default download directories.
- Theme switching (System/Light/Dark).

### 6. Technical Requirements
- Use a robust state management solution (e.g., `Provider` or `Riverpod`).
- Ensure the UI is responsive (Works beautifully on Desktop and Mobile).
- Use `CustomPainter` for high-performance segment maps if needed.
- Implement smooth animations for state transitions (e.g., an item moving from "Downloading" to "Finished").
</instructions>

<output_format>
Provide the full Dart code for the implementation, organized by files (Design System, Models, Widgets, Screens, Main). Include brief explanations for major design choices.
</output_format>

---

**Note**: Focus on creating an interface that feels "Alive" and "Pro". Every pixel should serve a purpose, and every animation should provide feedback.
