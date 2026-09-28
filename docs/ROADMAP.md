# Roadmap & status

✅ = implemented in this repo · 🟡 = partly / placeholder · ⬜ = not started

## Phase 1 — MVP

| Feature | Status | Notes |
| --- | --- | --- |
| Authentication: email/password, verification email, forgot password | ✅ | Supabase, enabled when `SUPABASE_URL` + key are set |
| Google login / Apple login | ✅ | Supabase OAuth; Apple shown on iOS/macOS. Needs provider setup in Supabase dashboard |
| Offline profile (no account) | ✅ | "Continue offline" |
| Per-account data isolation | ✅ | Separate storage folder per user id; RLS SQL ready for cloud |
| File manager: My Files, unlimited sub-folders, Recent, Favorites | ✅ | |
| Search, rename, move, duplicate (deep), delete (recursive), sort | ✅ | |
| PDF import + viewer, page navigation, zoom, search, thumbnails | ✅ | pdfrx (PDFium) |
| Draw / highlight / erase on PDF, undo/redo, autosave | ✅ | Annotations in PDF page coordinates |
| Whiteboard: white/black/green board, grid, ruled, dot paper | ✅ | |
| Pen, pencil, marker, highlighter, eraser, colours, sizes | ✅ | |
| Undo / redo / clear, multi-page boards, pan & zoom | ✅ | |
| Shapes: line, arrow, rectangle, circle/ellipse | ✅ | Shape tools (recognition from freehand is Phase 3) |
| Responsive UI (phone / tablet / desktop) | ✅ | NavigationBar ↔ NavigationRail, split view orientation |
| Ads: banner, interstitial, rewarded | ✅ | AdMob test ids by default; never on teaching screens |
| Local storage | ✅ | Atomic JSON + PDF blobs |

## Phase 2

| Feature | Status | Notes |
| --- | --- | --- |
| Split screen PDF + whiteboard, resizable | ✅ | Done early |
| Stylus: pressure, palm rejection (stylus-only mode), pen eraser end | ✅ | Done early |
| Laser pointer, spotlight, timer, stopwatch, zen mode, toolbar hide | ✅ | Done early |
| Cloud sync (files, folders, annotations, boards, preferences) | 🟡 | Schema + RLS in `supabase/migrations`; `features/sync` to build |
| Multi-device sync | ⬜ | Depends on cloud sync |
| Text notes on PDF, underline tool | ⬜ | |
| Lasso select / move strokes | ⬜ | |
| Custom background image | ⬜ | |
| Grid view & drag-and-drop in file manager | ⬜ | |

## Phase 3

| Feature | Status | Notes |
| --- | --- | --- |
| Export annotated PDF / canvas pages / images | ⬜ | Reuse `StrokeRenderer`; `pdf` or pdfrx engine for writing |
| Offline-first sync with conflict handling | 🟡 | Local-first storage + UUIDs already in place |
| Shape recognition from freehand strokes | ⬜ | |
| Premium subscription | 🟡 | `isPremium` flag wired to ads; add RevenueCat / in_app_purchase |
| Native ads | ⬜ | Needs native view factories per platform |
| Performance: stroke tiling/caching for very large boards | ⬜ | |
