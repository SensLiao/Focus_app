<div align="right"><a href="README.zh-CN.md">简体中文</a></div>

<p align="center"><img src="docs/hero.png" alt="Focus — a HarmonyOS focus timer that survives interruptions" width="100%"></p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-HarmonyOS%20(Stage%20model)-d97706?style=flat" alt="Platform: HarmonyOS, Stage model">
  <img src="https://img.shields.io/badge/language-ArkTS%20%2F%20ArkUI-d97706?style=flat" alt="Language: ArkTS / ArkUI">
  <img src="https://img.shields.io/badge/license-MIT-2f9e44?style=flat" alt="License: MIT">
</p>

Focus is a HarmonyOS focus timer and task manager built with ArkTS/ArkUI on the Stage model. It links every focus session to a real task, records every interruption — backgrounding, breaks, even a process kill — as an explicit state transition in a relational database, and recovers cleanly on the next launch, so a session's history is never silently lost. It is for anyone who wants a focus tool that stays honest about what actually happened across real-world interruptions.

<p align="center">
  <a href="#-quick-start">Quick start</a> ·
  <a href="#-architecture">Architecture</a> ·
  <a href="#-data-model">Data model</a> ·
  <a href="#-interruption-model">Interruption model</a> ·
  <a href="#-documentation">Documentation</a>
</p>

## 🧭 Overview

**Problem.** Most mobile focus timers treat interruptions as an afterthought. Switch apps mid-session, take a call, or let the system kill the process, and the timer either keeps counting a session you are no longer in, or drops the session entirely — either way the history lies. For a tool whose whole value is an honest record of focused time, that is a fatal flaw.

**Solution.** Focus treats every interruption as a first-class, recorded event. Sessions are multi-segment: each pause/resume closes one segment and opens another, breaks are logged as their own events, and every session carries an explicit `interruption_reason`. A lifecycle service observes foreground/background/destroy transitions and turns each into a database write, and a reconciliation pass on every launch converts any session left dangling by a process kill into a recoverable `PAUSED` record instead of an open-ended one. Everything durable lands in a foreign-key-constrained RelationalStore schema with idempotent, introspection-based migrations.

**Scope.** Focus is a single-device phone app (`deviceTypes: ["phone"]`). It does not sync to the cloud, has no accounts, and collects nothing — all data stays in a local RDB store. The UI language is Chinese.

## ✨ Highlights

- **Task-linked, multi-segment sessions** — full task CRUD, three session types (`NORMAL` count-up, `COUNTDOWN`, `POMODORO`), pause/resume that records each segment separately, and a dedicated break timer with skip and extend.
- **Every interruption becomes a record** — leaving the app closes the running session with an explicit `USER_PAUSED` record (and posts a notification to jump back in); a screen-off is *not* treated as leaving, so the timer keeps running through it.
- **Process-kill recovery** — on the next launch a reconciliation pass marks any session still `RUNNING` as `PAUSED` with `interruption_reason = 'APP_KILLED'`, and the task list surfaces it for one-tap resume, so a killed app leaves an honest, recoverable history entry.
- **Durable relational storage** — a 4-table RelationalStore schema (`tasks`, `focus_sessions`, `focus_segments`, `break_events`) with foreign-key constraints, 7 indexes, `SecurityLevel.S2`, and idempotent column-level migrations driven by `PRAGMA table_info` introspection.
- **Reminders that outlive the app** — break-end reminders are scheduled through the system ReminderAgent, so they fire even when the app is not in the foreground; in-app notifications cover background-exit and rest intervals.
- **Store-pattern state layer** — static-class singleton stores over `@Observed` state objects, with a `Result<T>` success/error envelope on every data operation and a single-active-session guard, so UI code never touches the database.
- **One wall-clock-accurate timer** — a single shared tick service derives elapsed time from timestamps rather than accumulated ticks, so drift never accumulates, and ticks update only local state to avoid full-page repaints.
- **Guided onboarding** — a first-run coach-mark overlay plus a guide page that deep-links into the system's own focus-mode settings, with multi-`Want` fallbacks for devices that route settings differently.

## 📸 Screenshots

<p align="center"><img src="docs/screens.png" alt="Focus representative UI — home task list, running timer, and history" width="100%"></p>
<p align="center"><sub>Representative UI (designed mockups): home task list, focus timer, and session history.</sub></p>

## 🏗 Architecture

<p align="center"><img src="docs/architecture.png" alt="Focus architecture: a one-way UI → Store → Services → RDB stack, with the lifecycle service turning interruptions into recorded state" width="100%"></p>
<p align="center"><sub>A one-way layered stack; the lifecycle service turns interruptions into recorded state.</sub></p>

Data flows in one direction, and each layer has exactly one job:

| Layer | What lives there |
| --- | --- |
| **Pages** (ArkUI) | 7 screens — home/task list, pre-focus setup, running timer, history, settings, task edit, and an onboarding guide — plus 8 shared components (timers, nav, stat cards, task rows, overlays). |
| **Stores** | `TaskStore` (task list) and `FocusStore` (the whole session/break lifecycle) — static-class singletons over `@Observed` state, every action returning `Result<T>`. |
| **Services** | App lifecycle event bus, the shared tick timer, ReminderAgent wrapper, notification manager (3 channels: background-exit, break-end, rest-interval), settings persistence over Preferences, and a system-settings navigator. |
| **Data** | `RdbClient` (connection, schema, migration, integrity check) plus one repository per table (`TaskRepo`, `SessionRepo`, `SegmentRepo`, `BreakRepo`), all returning `Result<T>`. |

Pages never touch the database; they call stores. Stores own business rules — the single-active-session guard, segment bookkeeping, break accounting — and delegate persistence to the repositories. Services do the work that outlives a single screen: the lifecycle bus receives `foreground` / `background` / `destroy` events from the app ability and routes them into `FocusStore`, which is where interruptions become database writes (see [Interruption model](#-interruption-model)).

<p align="center"><img src="docs/lifecycle.png" alt="Focus session lifecycle: RUNNING, PAUSED and FINISHED with the events that drive them - backgrounding closes the session as FINISHED with USER_PAUSED, a screen-off keeps it running, and a process kill is reconciled on the next launch" width="100%"></p>
<p align="center"><sub>Every interruption becomes an explicit record — and a process kill, which cannot run code at the time, is reconciled on the next launch instead.</sub></p>

## 🗃 Data model

Four tables, connected by foreign keys (`ON DELETE CASCADE` from sessions downward):

| Table | Key columns | Records |
| --- | --- | --- |
| `tasks` | `title`, `created_at`, `last_completed_at`, `total_focus_time`, `session_count`, `active_session_id` | A reusable task; accumulates focus time and completions across many sessions, and points at its in-progress session for one-tap resume. |
| `focus_sessions` | `task_id`, `start_at`, `end_at`, `status` (`RUNNING` / `PAUSED` / `FINISHED`), `interruption_reason`, `session_type`, `time_limit_ms`, `rest_interval_ms`, `rest_duration_ms` | One sitting of focused work, with an explicit status and the reason it ended or paused. |
| `focus_segments` | `session_id`, `segment_index`, `start_at`, `end_at`, `duration_ms` | One uninterrupted stretch inside a session — a pause/resume closes one segment and opens the next. |
| `break_events` | `session_id`, `start_at`, `planned_duration`, `actual_duration`, `is_skipped`, `reason` | Each break, including whether it was skipped and whether the app exited during it. |

Migrations are **introspection-based and idempotent**: on every connect, `RdbClient` reads `PRAGMA table_info` per table and applies only the `ALTER TABLE … ADD COLUMN` statements that are actually missing (backfilling data where needed), then verifies all four tables exist. Re-running is always safe, and existing data is never destroyed.

## 🔄 Interruption model

The precise behaviour, event by event:

| Event | What Focus does |
| --- | --- |
| App moves to **background** (screen on) | The running session is closed out with an explicit `USER_PAUSED` record, and a notification is posted so you can jump back in. Nothing keeps silently counting. |
| **Screen turns off** | Treated as *not* leaving — the timer keeps running. Turning the screen off to focus is the intended use, not an interruption. |
| **Break running** when the app exits | The break is finalised with reason `APP_KILLED`, so break accounting stays truthful. |
| **Process killed** mid-session | Nothing can run at kill time; instead, the next launch reconciles any session still marked `RUNNING` to `PAUSED` with `interruption_reason = 'APP_KILLED'`. |
| **Next launch** after a kill | The reconciled session surfaces on its task for one-tap resume; resuming clears the interruption reason and opens a fresh segment. |
| **Break ends** while backgrounded | A system ReminderAgent timer fires the break-end reminder even though the app is not in the foreground. |

This is the part of the app that was verified on a real device: backgrounding, killing the process from the recents screen, and relaunching all leave the history consistent.

## 🚀 Quick start

### Requirements

- **DevEco Studio** with the **HarmonyOS SDK 6.0.1** (API 21) toolchain
- A HarmonyOS phone or the DevEco emulator
- No signing material is committed — DevEco's automatic debug signing is enough to run

### Run

1. Open the project root in **DevEco Studio** (it reads `build-profile.json5` directly).
2. Let the IDE sync `oh-package.json5` dependencies (hvigor does this on open).
3. Select a connected device or emulator and run (**Shift+F10**).

### What you should see

First launch lands on the home page with an onboarding overlay walking through the home, timer, history and rest-mode features. Create a task, start a focus session from it, and press the home button mid-session — a notification appears, and the session is closed out with an explicit pause record that shows up in history instead of vanishing. The app asks for notification permission at runtime; reminders use the one declared permission, `ohos.permission.PUBLISH_AGENT_REMINDER`.

## 🗺 Project structure

```text
entry/src/main/ets/
├── pages/            # 7 screens: Index (home), StartPage, FocusPage, HistoryPage,
│                     #   SettingsPage, TaskEditPage, GuidePage
├── components/       # BottomNav, FocusTimer, BreakTimer, TaskItem, StatCard,
│                     #   NumberSelector, OnboardingOverlay, SuccessAnimation
├── store/            # focusStore (session/break lifecycle), taskStore (task list)
├── services/         # AppLifecycleService, TimerService, ReminderService,
│                     #   NotificationService, SettingsService, SettingsNavigator
├── data/             # RdbClient (schema + migrations) and one repo per table
├── model/            # Task, FocusSession, FocusSegment, BreakEvent, Result<T>
├── onboarding/       # OnboardingFlow step configuration
└── common/           # constants, theme tokens, hilog logger
Sample_frontend/      # The Figma-exported React/TypeScript prototype the ArkTS UI was ported from
```

## 🧪 Testing

Unit-test scaffolding is in place with **Hypium** (`@ohos/hypium` + `@ohos/hamock`); project-specific automated coverage is not claimed today. The interruption and process-kill recovery flows were verified manually on a real device (see [Interruption model](#-interruption-model)).

## 🖥 Compatibility

| Component | Support |
| --- | --- |
| HarmonyOS SDK | 6.0.1 (API 21), Stage model — `targetSdkVersion` = `compatibleSdkVersion` = `6.0.1(21)` |
| Device types | Phone |
| IDE / build | DevEco Studio, hvigor |
| UI language | Chinese |
| Cloud / sync | None — all data is local |

## 📚 Documentation

Design and implementation documents live in [`docs/`](docs/) (written in Chinese):

- [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) — MVP scope, Stage-model layering, and data flow
- [`BACKEND_DESIGN.md`](docs/BACKEND_DESIGN.md) — domain model, Store→Service→Data call chains, `Result<T>` conventions, migration notes
- [`FRONTEND_DESIGN.md`](docs/FRONTEND_DESIGN.md) — page structure, interaction flows, one-way data-flow rules
- [`PAGE_FLOW_UPDATED.md`](docs/PAGE_FLOW_UPDATED.md) — the routing/state table for all 7 pages
- [`RDB_IMPLEMENTATION_REPORT.md`](docs/RDB_IMPLEMENTATION_REPORT.md) — a file-and-line verification report of the database layer
- [`UI_DESIGN_SPECIFICATION.md`](docs/UI_DESIGN_SPECIFICATION.md) — the full visual/interaction spec behind the mockups

## 📊 Project status

- **Stable** — task CRUD, the three session types, segment/break accounting, history, settings persistence, onboarding, and the kill-recovery pass described above.
- **By design** — returning to the foreground does not auto-resume a session; resuming is an explicit user action, so no time is ever attributed to focus that didn't happen.
- **Not planned here** — cloud sync, accounts, multi-device state (a distributed-sync permission is stubbed but intentionally disabled).

## 👥 Team

Focus is a small collaborative project by **Ruixuan Liao** and **Ruijie Chen**. Together we built the task management, the interruption-aware focus sessions, the RDB persistence layer, and the lifecycle-safe recovery flow.

## 🧰 Tech stack

- **Language / UI:** ArkTS, ArkUI (declarative), `@Observed` state + AppStorage
- **Platform:** HarmonyOS Stage model, SDK 6.0.1 (API 21)
- **Data:** `@ohos.data.relationalStore` (RDB) with FK constraints; `@ohos.data.preferences` for settings
- **System services:** `reminderAgentManager` (timer reminders), `notificationManager` (3 channels), `hilog`
- **Build / test:** hvigor, `@ohos/hypium` + `@ohos/hamock`
- **Design source:** Figma prototype, exported to React/TS in `Sample_frontend/`

## 📄 License

Released under the **MIT License** — see [LICENSE](LICENSE).

<p align="center"><sub>Built by <a href="https://github.com/SensLiao">Ruixuan "Sens" Liao</a> · USYD Advanced Computing (Honours)</sub></p>
