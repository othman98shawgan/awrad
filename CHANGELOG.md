# Changelog

All notable changes to Awrad will be documented in this file.

## [1.0.1+2] - 2026-11-27

### Added
- **Local Auto-Backup & Recovery**: Debounced and lifecycle-flushed local JSON snapshots with `.prev.json` fallback and startup recovery prompt when local storage is empty.
- **Manual Backup Export & Import**: Export **Awrad List Only** (for sharing templates) or **Full Backup (Awrad & Progress)** directly to device **Files / Downloads** or via the native **Share** sheet, plus `.json` import with Merge/Replace preview.
- **Fixed Daily Progress Card**: Anchored the Daily Progress summary card above the day-swiping `PageView` on the Awrad tab.

### Fixed
- **Release Notifications**: Added `keep.xml` and updated Android notification permission handling so scheduled reminders work reliably in release builds.

### Changed
- **Debug App Identity**: Debug builds now use `[Dev] Awrad` and `com.example.awrad` so local testing does not affect the production app.

## [1.0.0+1]

### Added
- Initial release of Awrad: Daily Awrad & Prayer tracker, Progress heatmap & Teacher Report, Scheduled Reminders, Hijri date display, and Serene Oasis light/dark themes.
