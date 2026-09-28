# Smart Class — guide for AI coding tools

Flutter smartboard / PDF annotation app for online teaching. Read
`docs/ARCHITECTURE.md` before larger changes; `docs/ROADMAP.md` lists what is
done and what is next.

## Commands

```sh
flutter pub get
flutter analyze          # must report "No issues found!"
flutter test             # all tests must pass
flutter run -d macos     # or windows / android / ios / linux
flutter run --dart-define-from-file=env/dev.json   # with Supabase configured
```

## Conventions

- Feature-first: `lib/features/<feature>/{domain,data,application,presentation}`.
  `domain/` has no widgets and no packages except `dart:ui`.
- State: Riverpod `Provider` / `Notifier` / `AsyncNotifier` only, no code
  generation. Providers live in `application/*_providers.dart`.
- Screens never touch the file system, Supabase or AdMob directly; go through
  a repository/service provider.
- Concrete services are wired only in `lib/main.dart` via provider overrides.
- Route paths come from `AppRoutes` (`lib/app/routes.dart`).
- Colours/spacing/breakpoints come from `lib/core/theme/app_theme.dart`.
- Models are immutable with `copyWith`, `toJson`, `fromJson`.
- New ids: `newId()` from `core/utils/id.dart` (UUID, safe for offline sync).
- Ads: only through `AdsController` / `BannerAdSlot`, and never on teaching
  screens (`AdPolicy`).
- Every new pure-logic class gets a unit test under `test/<feature>/`.

## Where to change things

| Task                                   | Start here                                             |
| -------------------------------------- | ------------------------------------------------------ |
| New drawing tool                       | `canvas/domain/drawing_tool.dart`, `canvas/presentation/painters/stroke_renderer.dart`, toolbar |
| Stylus / touch behaviour               | `canvas/presentation/drawing_surface.dart`             |
| Board backgrounds                      | `canvas/domain/board_background.dart`, `painters/background_painter.dart` |
| PDF viewer features                    | `pdf/presentation/`                                    |
| File operations (rename, move, ...)    | `files/data/file_repository.dart` + `files_providers.dart` |
| Classroom tools (timer, spotlight)     | `classroom/`                                           |
| Ad rules                               | `ads/domain/ad_policy.dart`                            |
| Auth provider                          | `auth/data/`                                           |
| Cloud sync (Phase 2)                   | new `features/sync/`, schema in `supabase/migrations/` |
