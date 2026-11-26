# Awrad

A serene daily Islamic worship, dhikr, and prayer habit tracker built with Flutter.

[![Get it on Google Play](https://img.shields.io/badge/Google_Play-Awrad-0D7A5F?style=for-the-badge&logo=google-play&logoColor=white)](https://play.google.com/store/apps/details?id=com.othmanshawgan.awrad)

## Features

- **Daily Awrad Tracker:** Create custom daily or weekday-scheduled wirds, import curated templates (*Daily Essentials*, *Morning & Evening Adhkar*, *Ramadan Intensive*), drag to reorder, add per-day notes, and track completion with tri-state progress (*Done*, *Half Done*, *Not Done*).
- **Prayer Tracker:** Log all five daily prayers with Fard, Sunnah (Mu'akkadah / Mustahabbah presets or custom counts), Witr, and *In Masjid* status.
- **Progress & Hijri Calendar:** GitHub-style consistency heatmap with Weekly and Monthly views, a Gregorian / Hijri month toggle, streak milestones, and shareable Awrad & Prayers reports.
- **Daily Reminders:** Schedule multiple daily notifications (general or linked to a specific wird) that automatically skip today once your tasks are complete.
- **Serene Oasis Theme:** Material 3 Light and Dark modes, Hijri + Gregorian date switcher, and local on-device storage.

## Tech Stack

- **Flutter** `3.47.9` (`Dart 3.13.7`)
- **State Management:** `flutter_riverpod`
- **Persistence:** `shared_preferences`
- **Notifications:** `flutter_local_notifications`, `timezone`, `flutter_timezone`

## Getting Started

```bash
flutter pub get
flutter run
```

### Verification

```bash
flutter analyze
flutter test
```
