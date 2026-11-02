# BasementOS — agent handoff document

Read this fully before touching anything. It contains everything you need.

## Objective

Build **BasementOS**: a jailbreak-based system shell app for **iPhone 4S (iOS 8.4.1, ARMv7, 512 MB RAM, 960x640)** living in this folder (`~/project`, package id `com.basementos.shell`). Material Design 3 inspired dark UI, accent **#B69DF8**. Language: **Objective-C + UIKit + Theos**, storage **SQLite** (sqlite3, linked in Makefile). Distribution: `.deb`.

Build workflow: the agent writes ALL code locally first. The user will later provide a GitHub key/token; code is pushed to GitHub and **GitHub Actions builds the `.deb`** (`.github/workflows/build.yml` already exists: macOS runner, installs theos + theos/sdks, `make package FINALPACKAGE=1`, uploads `packages/*.deb` as artifact). Never run heavy local builds otherwise.

## Hard rules

- Work ONLY inside this folder.
- Theos: `TARGET := iphone:clang:latest:8.4.1`, `ARCHS = armv7`, ARC, sqlite3 linked, install prefix /Applications.
- **iOS 8–compatible APIs ONLY.** UIKit primitives, `UIAlertController` fine (iOS 8+).
- **NO NSTask on iOS (it's private/broken)** — process spawning happens via fork/execvp with pipes, see `src/BOSProcess.{h,m}` (already done).
- RAM is 512 MB: no fat images, minimal allocations, keep modules independent, incremental strategy (standalone app first, tweak later).
- App runs landscape (960x640); Info.plist has the right orientations + MinOS 8.4.1 + UIDeviceFamily=1.

## CRITICAL — how the previous agent must write code

The previous agent discovered its long file writes degenerate into garbage (hundreds of lines of pointless `[a stringByAppendingString:a]` "warm-up" filler chains, undefined identifiers like `theblock3`, `applyKeys_x`...). This repeatedly corrupted source files and had to be cleaned up by truncation.

**Therefore: write source files in SHORT chunks via `bash` heredoc** (`cat > file <<'EOF'`, then `cat >> file <<'EOF'` for sections), keep each append **under ~40 lines**, one small method per append, verify with `tail`/`wc -l` after each append, and NEVER write decorative filler code. Plain, minimal code only. If you must rewrite a corrupted file, truncate to the last known-good line first (`head -N file > tmp && mv tmp file`).

## Infrastructure already done (verified clean)

- `Makefile` — Theos app, uikitflags, sqlite3 `-lsqlite3`, lists ALL planned src files below.
- `control` — Depends: firmware >= 8.4.1 (не полагайся на содержимое — перепроверь при сборке).
- `resources/Info.plist` — bundle id, MinOS 8.4.1, orientations, etc.
- `.gitignore`, `.github/workflows/build.yml` (CI).
- `src/main.m` — app entrypoint.
- `src/BOSAppDelegate.{h,m}` — window, nav rooted at BOSHomeViewController, `[[BOSDatabase sharedDatabase] ensureSchema]` on finishLaunching.
- `src/BOSTheme.{h,m}` — palette (+ светлая тема через flag-file `/var/mobile/Library/BasementOS/light_theme`, `setLightTheme:`), helpers: `backgroundColor`, `textColor`, `secondaryTextColor`, `cardColor`, `md3FilledButtonWithTitle:`, etc.
- `src/BOSDatabase.{h,m}` — singleton SQLite helper: `ensureSchema` (notes, events, state tables in `/var/mobile/Library/BasementOS/basementos.sqlite`), `queryWithSQL:arguments:`, `executeWithSQL:arguments:insertedId:`.
- `src/BOSProcess.{h,m}` — fork+execvp, `spawn/passThru` style API, `runner`-ish, kill via /proc + killall fallback. Used by Terminal + Server Manager.
- `src/BOSHomeViewController.{h,m}` — collection grid of 7 app tiles (Clock, Calendar, Notes, Files, Servers, Terminal, Settings), live clock header card (timer tick), pushes VC classes on tap. **Imports all 7 sub-VC headers — they must ALL exist to compile.**
- `src/BOSClockViewController.{h,m}` — big live time card + stopwatch (start/stop, laps in list, Menlo).
- `src/BOSCalendarViewController.{h,m}` — CLEAN NOW (84 lines): viewDidLoad (table + `+ Add event` button), `loadEvents` (`SELECT id, event_date, title ...`), `addEvent` (UIAlertController with 2 textfields Title / YYYY-MM-DD — note: the Save handler doesn't yet insert row, TODO), datasource methods, `didSelectRowAtIndexPath` deletes the event (`DELETE FROM events WHERE id = ?`) then reloads.
- `src/BOSNotesViewController.{h,m}` — **PARTIAL/CLEAN-BUT-BALD**: ivars + `viewDidLoad` done (title field, body `_editor` UITextView, Save button, `_list` UITableView, `_rows` array, calls `loadNotes`). The `loadNotes` / `saveNote` / datasource / cell-tap methods are NOT YET WRITTEN (previous agent kept corrupting them - write fresh, minimal):
  - `loadNotes`: `SELECT id, text FROM notes ORDER BY id DESC LIMIT 100`, fill `_rows`, reload. Store `_currentId` for editing.
  - `saveNote`: if `_currentId` nil → `INSERT INTO notes (text) VALUES (?)` args `[body]`; else `UPDATE notes SET text = ? WHERE id = ?`. Then clear `_field`/`_editor`, `_currentId = nil`, reload.
  - Tap cell → load `row[@"text"]` into `_editor`, title split before `\n-\n` into `_field`, set `_currentId`.
- `src/BOSFilesViewController.{h,m}` — **NOT YET**: NSFileManager browser rooted at `/var/mobile`, table of subpaths, navigate into dirs (`../` row), tap a text file → preview inside a UITextView in a drill-down (or overlay). Keep tiny.
- `src/BOSServerManagerViewController.{h,m}` — **NOT YET**: cards for HTTP (lighttpd), SSH/SFTP (dropbear), Minecraft 1.12.2 (experimental); each card shows status (check via `BOSProcess` pid/ps), Start/Stop button calling `BOSProcess` (commands below).
- `src/BOSTerminalViewController.{h,m}` — **NOT YET**: UITextView output (Menlo, background `[BOSTheme textColor]` on dark bg), input UITextField, run line via `BOSProcess` exec + pipe output into text view; remember iOS 8, no fancy stuff.
- `src/BOSSettingsViewController.{h,m}` — **NOT YET**: theme toggle (light/dark, `[[BOSTheme shared] setLightTheme:]`), "About BasementOS" card, maybe device info (model/iOS via UIDevice).

## Storage contract

DB: `/var/mobile/Library/BasementOS/basementos.sqlite`
- `notes(id, text)`
- `events(id, event_date, title)` — **column order: event_date FIRST, then title**
- `state(key TEXT PRIMARY KEY, value TEXT)`

Theme flag: `/var/mobile/Library/BasementOS/light_theme` (presence = light). `~/project/services/` — server scripts (lighttpd HTTP on 8080, dropbear SSH/SFTP port 22, experimental Minecraft 1.12.2 via a lightweight java-equiv or mark TODO) go here; they must be plain sh, small, and referenced by Server Manager commands. `All files fitting /var/mobile/Library/BasementOS/` prefix for data.

## Next steps for you (in order)

1. Finish `BOSNotesViewController` (methods listed above) — small chunks.
2. Write `BOSFilesViewController`, `BOSTerminalViewController`, `BOSServerManagerViewController`, `BOSSettingsViewController` — one at a time, small heredoc chunks, verify with `tail` after each.
3. Create `services/` scripts + README.md, plus an optional icon (remove/adjust `icon` reference in Info.plist if skipped).
4. Re-check `Makefile` SUBPROJECTS file list matches reality; skim each `.m` for garbage (`stringByAppendingString:` chains, undefined vars) and delete junk lines.
5. Report back to the user — do NOT build or commit anything. User handles GitHub push/CI with their own key later; right after user gives a GitHub repo+token, init repo, push, confirm Actions produced `*.deb`.

## Notes about the user

- Speaks Russian. Tone: casual, direct ("ну чо там" style). Answer in Russian, short.
- Triggers handoff prompts with "Continue if you have next steps..." — finishing steps above IS the right response.
- Previous agent's biggest failure = code degeneration on long writes; your job is to avoid it by keeping every tool write tiny.
