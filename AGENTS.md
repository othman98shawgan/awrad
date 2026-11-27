# Agents

For all Git, branching, and release operations, strictly follow the rules in [./GIT_WORKFLOW.md](./GIT_WORKFLOW.md).

After every PR is merged into `main`, always run `git checkout main && git pull origin main`, delete the merged local branch, and create a new branch from `main` for any follow-up fixes or new tasks (never reuse or push new commits to an already-merged branch).

Always showcase and align on the complete scope, architecture, and edge cases of any feature or fix before writing any code, especially for big features.

When preparing a Pull Request reminder, always format the PR Description inside a fenced markdown code block (```markdown ... ```) so it can be easily copied with one click into GitHub.

## App Identity (Debug vs. Release)
- Always separate **debug** builds from **release/profile** builds so local testing never overwrites or affects the installed store/production app:
  - **Debug:** Prefix the app display name with `[Dev] ` (e.g., `[Dev] Awrad`) and use a separate debug application/bundle ID (`com.example.<app>`).
  - **Release / Profile:** Use the production app name and store bundle/application ID (`com.othmanshawgan.<app>`).
- On Android, preserve Flutter's `applicationName` placeholder by using `manifestPlaceholders += [...]` (never `=`) and overriding `debug` `applicationId` via `androidComponents`.
- On iOS, parameterize `CFBundleDisplayName` in `Info.plist` (`$(APP_DISPLAY_NAME)`) and set `APP_DISPLAY_NAME` + `PRODUCT_BUNDLE_IDENTIFIER` per Xcode build configuration (`Debug` vs `Release`/`Profile`).

## Terminal & Background Commands (Windows)
- On Windows, Flutter/Dart CLI tools (`flutter analyze`, `flutter test`, `flutter gen-l10n`, etc.) hang silently with empty background logs when run inside the restricted terminal sandbox (`BypassSandbox: false`).
- Always run those background/CLI verification commands as **standalone single commands** (do not chain multiple commands with `;` or `&&`) using **`BypassSandbox: true`** so output streams live and the command completes cleanly.
- If you run `flutter analyze` and `flutter test`, invoke them as two separate `run_command` calls (`BypassSandbox: true`), not combined in one shell string.

## Roadmap
- [x] **Task 1 (`chore/architecture-data-refactor`)**: Minimalist 3-folder (`models/` / `services/` / `ui/`) refactor, separated sync-ready `AwradTask` + `DailyAwradLog` + `DailyPrayerLog` repositories, automatic legacy migration, normalized date provider, accurate partial rak‘ahs, and unit tests.
- [x] **Task 2 (`feat/serene-oasis-theme-shell`)**: "Serene Oasis" Material 3 light & dark theme (`#27`, `#28`), unified 4-tab app shell (single AppBar), and shared swipeable date switcher + calendar picker (`#18`, `#20`).
- [x] **Task 3 (`feat/daily-awrad-crud-templates`)**: Redesigned Daily Awrad screen (segmented progress card, 7-day strip, tri-state half-done cards, drag reorder `#24`, task notes `#25`), add/edit/delete + recurrence (`#7`–`#11`), and Import Awrad Templates (`#12`).
- [x] **Task 4 (`feat/prayer-tracker-redesign`)**: Redesigned Prayer Tracker tab with daily status card and tri-state prayer cards.
- [x] **Task 5 (`feat/progress-heatmap-teacher-report`)**: Progress tab with GitHub-style heatmap (`#14`–`#17`), weekly/monthly toggle, tap-day view, and shareable Teacher Report.
- [x] **Task 6 (`feat/settings-and-reminders`)**: Settings tab with template browser entry, manage awrad, wakelock toggle, daily notification reminders (`#29`–`#32`), and Guest/Cloud Sync prep.
- [x] **Task 7 (`feat/hijri-date-progress-enhancements`)**: Hijri date display in `DateSwitcherBar`, streak counters/milestones on the Progress tab, and Undo support for swipe-to-delete.
- [x] **Task 8 (`feat/backup-and-restore`)**: Local JSON export/import backup and restore for Awrad tasks, daily logs, and prayer history.
- [x] **Task 9 (`chore/store-release-prep`)**: v1.0.0 store release prep — `com.othmanshawgan.awrad` bundle/app ID, Android release signing config, branded splash screens, monochrome notification icon (`ic_stat_awrad`), iOS portrait lock, midnight rollover, and Store-safe copy.
- [ ] **Task 10 (`feat/arabic-l10n-rtl`)**: Arabic localization & RTL (`l10n`) — English/Arabic translations, full RTL layout, localized templates, and language selector in Settings.
- [ ] **Task 11 (`feat/cloud-sync-accounts`)**: Cloud Sync & Accounts — wire sync-ready repositories to Firebase/Supabase and replace the Guest Mode placeholder in Settings.
