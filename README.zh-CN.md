<div align="right"><a href="README.md">English</a></div>

<p align="center"><img src="docs/hero.png" alt="Focus — a HarmonyOS focus timer that survives interruptions" width="100%"></p>

Focus 是一款基于 HarmonyOS Stage 模型、使用 ArkTS/ArkUI 构建的专注计时器与任务管理应用。它将每一次专注计时都与真实任务关联，应用退到后台时自动暂停，并在进程被系统杀死后依然能够干净地恢复，从而确保会话历史不会被悄然丢失。它面向所有希望专注工具在真实中断场景（后台切换、休息、系统终止）下依然表现正确的人。

## ✨ 亮点

- **任务关联的专注会话** — 完整的任务增删改查（CRUD），支持多段式专注会话的暂停/恢复，以及独立的休息计时器。
- **面向中断的设计** — 一个生命周期服务会在应用切换到后台时自动暂停当前会话，并在回到前台时恢复。
- **进程被杀后的恢复** — 下次启动时，未完成的会话会被标记为 `PAUSED`，并记录 `interruption_reason = 'APP_KILLED'`，让历史保持一致，而不会留下悬空数据。
- **可靠的关系型存储** — 一个 DB 版本为 3 的 RelationalStore (RDB) 模式，包含 4 张表、7 个索引、外键约束，以及幂等的列级迁移。
- **Store 模式的状态层** — 在 `@Observed` 状态对象之上的静态类单例，配合 `Result<T>` 成功/错误信封，带来可预测的数据流。
- **高效重绘的计时器** — 计时器每次 tick 只更新本地状态，避免每秒触发整页重绘。

## 🏗 架构

<p align="center"><img src="docs/architecture.png" alt="Focus architecture: a one-way UI → Store → Services → RDB stack, with the lifecycle service driving auto-pause and kill-recovery" width="100%"></p>
<p align="center"><sub>单向分层的架构，以及把中断转化为已记录状态的生命周期服务。</sub></p>

数据是单向流动的。ArkUI 页面负责渲染任务列表、专注/休息计时器与会话历史，本身从不直接访问数据库，而是调用 store。Store 是包裹 `@Observed` 状态对象的静态类单例，它暴露的每个操作都返回一个 `Result<T>` 信封，因此成功与失败在每一处调用点都以相同方式处理。再往下，Timer、Reminder 与 Lifecycle 这几个服务承担那些生命周期超出单个页面的工作；所有需要持久化的数据都落入一个带版本管理的 RelationalStore 模式（`tasks`、`focus_sessions`、`focus_segments`、`break_events`），其中包含外键、索引，以及在不破坏既有数据的前提下新增列的幂等迁移。

真正让中断变得可承受的，是生命周期服务。它观察前台、后台与销毁（destroy）的转换，并把每一次转换都变成一次显式的状态变更，而不是记录中的一段空白：切换到后台会自动暂停正在进行的会话，回到前台则恢复它。如果进程被直接杀死，该会话会在下次启动时被协调处理 —— 标记为 `PAUSED` 并记录 `interruption_reason = 'APP_KILLED'` —— 于是被杀死的应用留下的是一条诚实的历史记录，而不是一个没有结尾的会话。

## 📸 界面截图

<p align="center"><img src="docs/screens.png" alt="Focus representative UI" width="100%"></p>
<p align="center"><sub>示意性 UI（设计稿）。</sub></p>

## 👥 团队

Focus 是 **Ruixuan Liao** 与 **Ruijie Chen** 合作完成的一个小型项目。我们共同构建了任务管理、面向中断的专注会话、RDB 持久化层，以及生命周期安全的恢复流程。

## 🧰 技术栈

- **语言 / UI：** ArkTS、ArkUI（声明式）
- **平台：** HarmonyOS Stage 模型（SDK 6.0.1）
- **数据：** `@ohos.data.relationalStore` (RDB)
- **提醒：** ReminderAgent
- **构建：** hvigor
- **测试：** `@ohos/hypium`

## 🚀 快速开始

前置条件：安装了 HarmonyOS SDK（6.0.1）的 DevEco Studio。

1. 在 **DevEco Studio** 中打开本项目。
2. 选择一台已连接的设备或模拟器。
3. 运行应用（**Shift+F10**）。

## 🧪 测试

已使用 **Hypium**（`@ohos/hypium`）搭建单元测试脚手架。中断与进程被杀恢复流程已在真机上验证。目前并未声称具备更广泛的自动化测试覆盖。

## 📄 许可证

以 **MIT License** 发布——参见 [LICENSE](LICENSE)。

<p align="center"><sub>Built by <a href="https://github.com/SensLiao">Ruixuan "Sens" Liao</a> · USYD Advanced Computing (Honours)</sub></p>
