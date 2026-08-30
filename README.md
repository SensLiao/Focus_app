<div align="right"><a href="README.zh-CN.md">简体中文</a></div>

<p align="center"><img src="docs/hero.png" alt="Focus banner" width="100%"></p>

<p align="center"><b>A focus timer that survives interruptions.</b></p>

<p align="center">
<img src="https://img.shields.io/badge/HarmonyOS-Stage%20Model-fbbf24?style=flat-square" alt="HarmonyOS Stage Model">
<img src="https://img.shields.io/badge/ArkTS-ArkUI-fbbf24?style=flat-square" alt="ArkTS ArkUI">
<img src="https://img.shields.io/badge/SDK-6.0.1-fbbf24?style=flat-square" alt="SDK 6.0.1">
<img src="https://img.shields.io/badge/RelationalStore-RDB%20v3-fbbf24?style=flat-square" alt="RelationalStore RDB v3">
<img src="https://img.shields.io/badge/License-MIT-22c55e?style=flat-square" alt="License MIT">
<img src="https://img.shields.io/badge/Status-MVP-64748b?style=flat-square" alt="Status MVP">
</p>

Focus is a HarmonyOS focus timer and task manager built with ArkTS/ArkUI on the Stage model. It links every focus timer to a real task, auto-pauses when the app leaves the foreground, and recovers cleanly after a process kill so a session's history is never silently lost. It is for anyone who wants a focus tool that behaves correctly across real-world interruptions — backgrounding, breaks, and system-initiated termination.

## ✨ Highlights

- **Task-linked focus sessions** — full task CRUD, with multi-segment focus sessions that support pause/resume and a dedicated break timer.
- **Interruption-aware by design** — a lifecycle service auto-pauses the active session when the app moves to the background and resumes it on return to the foreground.
- **Process-kill recovery** — on the next launch, an unfinished session is marked `PAUSED` with `interruption_reason = 'APP_KILLED'`, so history stays consistent instead of dangling.
- **Durable relational storage** — a RelationalStore (RDB) schema at DB version 3 with 4 tables, 7 indexes, foreign-key constraints, and idempotent, column-level migrations.
- **Store-pattern state layer** — static-class singletons over an `@Observed` state object, with a `Result<T>` success/error envelope for predictable data flow.
- **Repaint-efficient timer** — timer ticks update only local state, avoiding full-page repaints every second.

## 🏗 How it works

Focus is organised in three layers:

- **UI (ArkUI):** page components that render task lists, the focus/break timer, and session history.
- **State (Store pattern):** static-class singleton stores wrap an `@Observed` state object and expose actions that return a `Result<T>` envelope; timer ticks are kept in local state to avoid re-rendering whole pages.
- **Persistence (RelationalStore):** a versioned RDB schema (DB v3) with foreign keys and indexes, plus idempotent migrations that add columns without destroying existing data.

A lifecycle service ties these together: it observes foreground/background transitions to auto-pause and resume, and reconciles unfinished sessions on startup to deliver kill-recovery.

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

Unit-test scaffolding is in place using **Hypium** (`@ohos/hypium`). The interruption and process-kill recovery flows were verified on a real device. Broader automated coverage is on the roadmap rather than claimed today.

## 📌 Project status

A working MVP. The core flows — task management, focus/break sessions, background auto-pause, and kill-recovery — function end-to-end; broader automated test coverage is planned.

## 📄 License

Released under the **MIT License** — see [LICENSE](LICENSE).

<p align="center"><sub>Built by <a href="https://github.com/SensLiao">Ruixuan "Sens" Liao</a> · USYD Advanced Computing (Honours)</sub></p>
