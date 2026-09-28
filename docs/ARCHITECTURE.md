# Architecture

Smart Class is a single Flutter codebase for Android, iOS, iPadOS, Windows,
macOS (and Linux for development). The goal of the architecture is that a
human *or an AI coding tool* can open one folder and understand one feature
without reading the rest of the app.

## Principles

1. **Feature-first folders.** Everything about a feature lives under
   `lib/features/<feature>/`.
2. **Four layers per feature, always the same names:**

   | Folder         | Contains                                          | May import                     |
   | -------------- | ------------------------------------------------- | ------------------------------ |
   | `domain/`      | Immutable models + pure logic. No Flutter widgets.| `dart:*`, `dart:ui` only       |
   | `data/`        | Repositories/services talking to disk, network, SDKs | `domain/`, `core/`          |
   | `application/` | Riverpod providers & controllers (state)          | `domain/`, `data/`, `core/`    |
   | `presentation/`| Screens and widgets                               | everything above               |

3. **Interfaces at the edges.** Storage (`KeyValueStore`, `BlobStore`), auth
   (`AuthRepository`) and ads (`AdService`) are interfaces. Concrete
   implementations are chosen in one place: `lib/main.dart`.
4. **Local-first.** Every write goes to the device first. The UI never waits
   on the network. Cloud sync (Phase 2) replicates the same records.
5. **Minimal dependencies.** Each package in `pubspec.yaml` has a clear job
   (see below). No code generation, so there is no build step to forget.

## Folder map

```
lib/
  main.dart                 Composition root (chooses Supabase/local auth, AdMob/no-op ads)
  app/                      MaterialApp, router, route names
  core/
    config/env.dart         --dart-define configuration
    storage/                KeyValueStore, BlobStore, per-user UserStorage
    theme/app_theme.dart    Colours, spacing, breakpoints, ThemeData
    utils/, widgets/        Small shared helpers and dialogs
  features/
    auth/                   Sign-in (email, Google, Apple, offline), user scoping
    files/                  My Files tree: folders, PDFs, boards, search, sort, favourites
    canvas/                 Drawing engine + whiteboard (shared by PDF annotation)
    pdf/                    PDF viewer, per-page ink layer, search, thumbnails
    workspace/              Split screen (PDF + whiteboard)
    classroom/              Zen mode, spotlight, timer/stopwatch, toolbar hide
    ads/                    Ad policy (pure), AdMob service, banner slot
    settings/               Per-account preferences (theme, premium flag)
test/                       Mirrors lib/features
supabase/migrations/        Backend schema with row-level security (Phase 2)
```

## Key data model

```
FileNode  { id, parentId?, name, type: folder|pdf|board, createdAt, updatedAt,
            isFavorite, lastOpenedAt?, sizeBytes }
CanvasDocument { pages: { pageIndex: CanvasPage } }
CanvasPage     { background, strokes: [Stroke] }
Stroke         { id, tool, color, width, points: [x, y, pressure] }
```

* The file tree is **flat** (each node stores `parentId`). Unlimited nesting,
  one-field moves, and it maps 1:1 to a database table.
* A board file's strokes are stored under its id. A PDF's annotations are
  stored under the PDF's id, keyed by page index; the side whiteboard in split
  screen is stored under `<pdfId>_board`.
* PDF strokes are in **PDF page coordinates** (points), so they stay attached
  to the content at every zoom level and on every screen size.
* All ids are UUIDv4, so items created offline on two devices never collide.

## On-device storage

```
<app support dir>/smart_class/users/<userId>/
  data/files_index.json        the FileNode tree
  data/canvas/<fileId>.json    strokes
  data/preferences.json
  blobs/<fileId>               imported PDF bytes
```

Each account gets its own folder, so accounts on a shared device are isolated.
Writes are atomic (temp file + rename).

## The drawing engine (`features/canvas`)

* `CanvasDocumentController` — the single source of truth while editing:
  add stroke, erase, clear, background, undo/redo (`History<T>`), and
  debounced autosave. Used by both the whiteboard and PDF annotation.
* `DrawingSurface` — turns raw pointer events into strokes. It is the only
  widget that knows about stylus vs. touch.
* `StrokeRenderer` — stateless painting (smoothing, pressure, shapes, laser).
  Reuse it for image/PDF export in Phase 3.

### Stylus & touch rules

| Input                    | "Any" mode (phones)        | "Stylus only" mode (tablets) |
| ------------------------ | -------------------------- | ---------------------------- |
| Apple Pencil / S Pen / active pen | draws             | draws                        |
| Pen's eraser end (inverted stylus) | erases           | erases                       |
| Mouse (left button)      | draws                      | draws                        |
| One finger               | draws                      | pans (palm rejection)        |
| Two fingers              | pan + pinch zoom           | pan + pinch zoom             |

Pressure is read from `PointerEvent.pressure` when the device reports a range;
otherwise a constant is recorded (graceful fallback). Flutter already receives
Apple Pencil and S Pen as `PointerDeviceKind.stylus`, so no native plugin is
needed for the MVP. Native hooks (Apple Pencil double-tap, S Pen button) can be
added later behind a small platform-channel service.

Inside the PDF viewer, the ink layer claims drawing pointers in the gesture
arena (`EagerGestureRecognizer`) so pages don't scroll while writing, but
fingers still scroll in stylus-only mode.

## Ads

`AdPolicy` (pure, unit-tested) is the single rulebook:

* No ads on desktop, for premium users, or during a rewarded ad-free hour.
* Banner: only on the file manager (home).
* Interstitial: only after leaving a teaching session, at most every 5 minutes.
* **Never** on the whiteboard, PDF, split screen or presentation tools.

Native ads need per-platform native view factories and were left for later;
`AdService` is where they plug in.

## Packages

| Package            | Why                                                    |
| ------------------ | ------------------------------------------------------ |
| flutter_riverpod   | State management & dependency injection (no codegen)   |
| go_router          | Declarative routes + auth redirect                     |
| pdfrx              | PDFium-based viewer on all platforms (MIT/BSD, free)   |
| file_picker        | Import PDFs from device storage                        |
| path_provider/path | App data directory                                     |
| supabase_flutter   | Auth now; database/storage/realtime for sync in Phase 2|
| google_mobile_ads  | AdMob banner / interstitial / rewarded (Android, iOS)  |
| uuid               | Collision-free offline ids                             |

## Cloud sync plan (Phase 2)

1. Apply `supabase/migrations/0001_init.sql` (tables + row-level security).
2. Add `features/sync/`: a `SyncService` that pushes local changes (rows with
   `updatedAt` newer than the last sync) and pulls remote changes, last-write-
   wins per record, strokes merged per page by stroke id.
3. PDFs upload to the `pdfs` storage bucket at `<userId>/<fileId>.pdf`.
4. Repositories stay unchanged for the UI; they just gain a "dirty" marker.
