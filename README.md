<div align="right"><a href="README.zh-CN.md">简体中文</a></div>

<p align="center"><img src="docs/hero.png" alt="Focus — a HarmonyOS focus timer that survives interruptions" width="100%"></p>

Focus is a HarmonyOS focus timer and task manager built with ArkTS/ArkUI on the Stage model. It links every focus timer to a real task, auto-pauses when the app leaves the foreground, and recovers cleanly after a process kill so a session's history is never silently lost. It is for anyone who wants a focus tool that behaves correctly across real-world interruptions — backgrounding, breaks, and system-initiated termination.

## ✨ Highlights

- **Task-linked focus sessions** — full task CRUD, with multi-segment focus sessions that support pause/resume and a dedicated break timer.
- **Interruption-aware by design** — a lifecycle service auto-pauses the active session when the app moves to the background and resumes it on return to the foreground.
- **Process-kill recovery** — on the next launch, an unfinished session is marked `PAUSED` with `interruption_reason = 'APP_KILLED'`, so history stays consistent instead of dangling.
- **Durable relational storage** — a RelationalStore (RDB) schema at DB version 3 with 4 tables, 7 indexes, foreign-key constraints, and idempotent, column-level migrations.
- **Store-pattern state layer** — static-class singletons over an `@Observed` state object, with a `Result<T>` success/error envelope for predictable data flow.
- **Repaint-efficient timer** — timer ticks update only local state, avoiding full-page repaints every second.

## 🏗 Architecture

<p align="center"><img src="docs/architecture.png" alt="Focus architecture: a one-way UI → Store → Services → RDB stack, with the lifecycle service driving auto-pause and kill-recovery" width="100%"></p>
<p align="center"><sub>A one-way layered stack, with the lifecycle service that turns interruptions into recorded state.</sub></p>

Data flows in one direction. ArkUI pages render task lists, the focus/break timer and session history, and never touch the database themselves; they call into the stores. The stores are static-class singletons wrapping an `@Observed` state object, and every action they expose returns a `Result<T>` envelope, so success and failure are handled the same way at every call site. Below them, the timer, reminder and lifecycle services do the work that outlives a single screen, and everything durable lands in a versioned RelationalStore schema (`tasks`, `focus_sessions`, `focus_segments`, `break_events`) with foreign keys, indexes, and idempotent migrations that add columns without destroying existing data.

The lifecycle service is what makes interruptions survivable. It observes foreground, background and destroy transitions, and turns each into an explicit state change rather than a gap in the record: moving to the background auto-pauses the running session, and returning to the foreground resumes it. If the process is killed outright, the session is reconciled on the next launch — marked `PAUSED` with `interruption_reason = 'APP_KILLED'` — so a killed app leaves an honest history entry instead of an open-ended session.

## 📸 Screenshots

<p align="center"><img src="docs/screens.png" alt="Focus representative UI" width="100%"></p>
<p align="center"><sub>Representative UI (designed mockups).</sub></p>

## 👥 Team

Focus is a small collaborative project by **Ruixuan Liao** and **Ruijie Chen**. Together we built the task management, the interruption-aware focus sessions, the RDB persistence layer, and the lifecycle-safe recovery flow.

## 🧰 Tech stack

- **Language / UI:** ArkTS, ArkUI (declarative)
- **Platform:** HarmonyOS Stage model (SDK 6.0.1)
- **Data:** `@ohos.data.relationalStore` (RDB)
- **Reminders:** ReminderAgent
- **Build:** hvigor
- **Testing:** `@ohos/hypium`

## 🚀 Getting started

Prerequisites: DevEco Studio with the HarmonyOS SDK (6.0.1) installed.

1. Open the project in **DevEco Studio**.
2. Select a connected device or an emulator.
3. Run the app (**Shift+F10**).

## 🧪 Testing

Unit-test scaffolding is in place using **Hypium** (`@ohos/hypium`). The interruption and process-kill recovery flows were verified on a real device. Broader automated coverage is not claimed today.

## 📄 License

Released under the **MIT License** — see [LICENSE](LICENSE).

<p align="center"><sub>Built by <a href="https://github.com/SensLiao">Ruixuan "Sens" Liao</a> · USYD Advanced Computing (Honours)</sub></p>
