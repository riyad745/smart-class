# Smart Class

অনলাইন ক্লাসের (Google Meet / Zoom) জন্য Smartboard-style Interactive PDF Reader
ও Teaching App। একটি Flutter codebase থেকে **Android, iOS, iPad, Android Tablet,
Windows ও macOS**।

A smartboard-style PDF reader and whiteboard for teaching over screen share.

## যা আছে (Features)

- **Whiteboard:** white/black/green board, grid/ruled/dot paper; pen, pencil,
  marker, highlighter, eraser, laser pointer; line, arrow, rectangle, circle;
  colours, stroke size; undo/redo/clear; multi-page; pan & pinch-zoom.
- **PDF:** import, viewer, page navigation, zoom, full-text search, thumbnails,
  PDF-এর ওপর সরাসরি লেখা/highlight/erase, autosave.
- **Split screen:** PDF + whiteboard পাশাপাশি, divider টেনে resize।
- **Stylus:** Apple Pencil / S Pen / active pen, pressure, palm rejection
  ("stylus only" mode), pen-এর eraser end দিয়ে মোছা।
- **Classroom tools:** spotlight, timer/stopwatch, zen mode, toolbar hide/show।
- **File manager:** My Files, unlimited folder/sub-folder, Recent, Favorites,
  search, rename, move, duplicate, delete, sort।
- **Auth:** email/password (verification + forgot password), Google, Apple,
  অথবা offline — প্রতিটি account-এর data আলাদা।
- **Ads:** AdMob banner (শুধু home), interstitial (class শেষে, frequency-capped),
  rewarded (১ ঘণ্টা ad-free)। Teaching screen-এ কখনো ad নয়। Premium = no ads।

বিস্তারিত অবস্থা: [docs/ROADMAP.md](docs/ROADMAP.md) ·
বাজেট/সময়: [docs/BUDGET_TIMELINE.md](docs/BUDGET_TIMELINE.md) ·
Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Run

```sh
flutter pub get
flutter run                      # offline mode, AdMob test ads on mobile
```

Cloud accounts (Supabase):

```sh
cp env/example.json env/dev.json # fill in your project URL and publishable key
flutter run --dart-define-from-file=env/dev.json
```

In the Supabase dashboard: enable Email, Google and Apple providers, add
`io.smartclass.app://login-callback` as a redirect URL, and run
`supabase/migrations/0001_init.sql` (needed for cloud sync in Phase 2).

## Before release

- Replace AdMob **test** ids: app id in `android/app/src/main/AndroidManifest.xml`
  and `ios/Runner/Info.plist`, unit ids via `--dart-define` (see `lib/core/config/env.dart`).
- Change the Android `applicationId` / iOS bundle id from `com.example.smart_class`.
- Replace the Premium developer toggle in Settings with real in-app purchases.

## Quality

```sh
flutter analyze   # No issues found
flutter test      # unit + widget + app smoke tests
```
