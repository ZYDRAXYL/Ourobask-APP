# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Ourobask is a Flutter mobile app (Android-first, with iOS project scaffolding present) for tracking Task / Work / Idea items with scheduled notifications and alarms. All data is stored locally in SQLite; there is no backend/API. Data can be exported to / imported from a JSON backup file. The app's UI text and the README are in Thai.

Core domain concepts (see `lib/data/models.dart`):
- **Task** — a to-do item with an optional due date/time, priority, color, and completion state. Completed tasks disappear from all lists and move into a single History view (auto-purged after 30 days).
- **Quest** — a special Task subtype for savings goals: has a target amount and a log of deposits/withdrawals (`quest_entries`), auto-completes when the target is reached.
- **Project** (โฟลเดอร์งาน / "Work Project") — a folder that groups Tasks, Routines, and Notes together.
- **Note** — free-form text that only exists inside a Project (cannot exist standalone or be created outside one).
- **Routine** — a recurring item (weekly by weekday, or monthly by day-of-month) shown on the home page and in the calendar views; can optionally be linked to a Quest as a recurring savings plan.
- **Idea** / **IdeaBox** — a scratchpad ("idea box") for quick notes, optionally organized into category boxes; ideas can be promoted into a Task or a Note.
- **Reminder** — one or more scheduled alerts attached to a Task/Routine, each either a plain notification or a full alarm (with a custom or system sound).

## Common commands

```bash
flutter pub get                 # install dependencies
flutter analyze                 # static analysis (must be clean; flutter_lints ruleset in analysis_options.yaml)
flutter test                    # run the full test suite (test/*.dart)
flutter test test/note_test.dart            # run a single test file
flutter test test/note_test.dart --name "some test name"   # run a single test by name
flutter run                     # run the app on a connected device/emulator
```

Build APKs:
```bash
flutter build apk --release                  # single APK, all ABIs
flutter build apk --release --split-per-abi  # smaller per-architecture APKs (used for in-app auto-update)
```

By default release builds are signed with the debug keystore committed at `android/app/debug.keystore` (same key on every machine/CI run) so successive releases can update over each other in-app without an "package conflicts" install error. To sign with a real key (e.g. for Play Store), create `android/key.properties` with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.

CI (`.github/workflows/ci.yml`) runs on push to `main` and on PRs: `flutter analyze`, `flutter test`, then a release APK build; a build failure is echoed back as a PR comment. `.github/workflows/release.yml` builds and publishes a release APK to GitHub Releases when a `v*` tag is pushed (or via manual workflow dispatch).

## Architecture

```
lib/
├── app_info.dart   App name/version/repo constants used by the in-app update checker
├── main.dart       Entry point: inits notifications, constructs AppState, runs MaterialApp
├── data/           Models, SQLite schema/migrations, repository (CRUD), backup export/import
├── services/       NotificationService (alerts/alarms), sound picking, GitHub-release update checking/installing
├── state/          AppState: the single ChangeNotifier holding all app data and business logic
├── ui/             Screens (home, work/projects, calendar, idea box, settings, editors, history, update)
│   ├── calendar/   Week/month/year views + the period-jump picker
│   └── widgets/    Reusable cards/tiles/editors (task tile, note tile, reminder editor, etc.)
└── utils/          Due-date bucketing, history retention, Thai date/number formatting
```

**State management**: `AppState` (`lib/state/app_state.dart`, ~1000 lines) is the single `ChangeNotifier` that owns all in-memory app data (tasks, projects, routines, ideas, reminders, quest totals) and nearly all business logic (due-date bucketing for the home page, quest progress/`MoneySummary` aggregation, scheduling/cancelling reminders, completion/restore flow, history pruning). It is provided at the app root via `provider` (`ChangeNotifierProvider<AppState>`) and consumed throughout `ui/` with `context.watch`/`context.read`. UI widgets are largely thin; look in `AppState` first when tracing behavior that spans multiple screens (e.g. why a completed task disappears everywhere, or how quest totals roll up to a project/home).

**Persistence** (`lib/data/`): `database.dart` (`AppDatabase`) owns the `sqflite` connection, schema version, and `onCreate`/`onUpgrade` migrations. `repository.dart` (`Repository`) is the CRUD layer over that database, one method group per table (`kDataTables`: `quest_entries`, `reminders`, `tasks`, `routines`, `ideas`, `idea_boxes`, `notes`, `projects` — listed in FK-safe delete order). `models.dart` defines all domain classes plus their SQLite row (de)serialization. `backup.dart` implements JSON export/import with a versioned format (`BackupService.formatVersion`, currently 4) that stays backward-compatible with older exported files; imports can either merge with or overwrite existing data, and reschedule reminders afterward.

**Notifications/alarms** (`services/notification_service.dart`): wraps `flutter_local_notifications` + `timezone` to schedule per-reminder notifications or full alarms, including resolving a custom sound file into a `content://` URI via FileProvider for Android. `services/sound_service.dart` handles picking/copying a device sound file. Every reminder toggle in the UI (home page, task list) goes through this service to schedule/cancel the underlying OS notification.

**In-app update** (`services/update_service.dart` + `ui/update_page.dart`): checks the GitHub Releases API directly (`AppInfo.latestReleaseApi`, no token needed since the repo is public), compares semantic versions (`AppVersion`), and can download the architecture-matching APK with progress and hand it to the Android installer.

**Version consistency**: `AppInfo.version`/`buildNumber` (`lib/app_info.dart`) must match the `version:` field in `pubspec.yaml` — `test/update_test.dart` asserts this by parsing `pubspec.yaml` directly, so bump both together.

## Testing notes

Tests live flat under `test/` (no subfolders) and are largely plain `flutter_test` unit/logic tests against `lib/data`, `lib/state`, and `lib/utils` (due-date bucketing, idea box/random-pick behavior, quest math, history retention, backup format, update-version parsing), plus one `ui_smoke_test.dart` for basic widget pumping. There is no golden-image or integration-test setup.
