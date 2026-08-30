<div align="right"><a href="README.md">English</a></div>

<p align="center"><img src="docs/hero.png" alt="Focus banner" width="100%"></p>

<p align="center"><b>一款能挺过各种中断的专注计时器。</b></p>

<p align="center">
<img src="https://img.shields.io/badge/HarmonyOS-Stage%20Model-fbbf24?style=flat-square" alt="HarmonyOS Stage Model">
<img src="https://img.shields.io/badge/ArkTS-ArkUI-fbbf24?style=flat-square" alt="ArkTS ArkUI">
<img src="https://img.shields.io/badge/SDK-6.0.1-fbbf24?style=flat-square" alt="SDK 6.0.1">
<img src="https://img.shields.io/badge/RelationalStore-RDB%20v3-fbbf24?style=flat-square" alt="RelationalStore RDB v3">
<img src="https://img.shields.io/badge/License-MIT-22c55e?style=flat-square" alt="License MIT">
<img src="https://img.shields.io/badge/Status-MVP-64748b?style=flat-square" alt="Status MVP">
</p>

Focus 是一款基于 HarmonyOS Stage 模型、使用 ArkTS/ArkUI 构建的专注计时器与任务管理应用。它将每一次专注计时都与真实任务关联，应用退到后台时自动暂停，并在进程被系统杀死后依然能够干净地恢复，从而确保会话历史不会被悄然丢失。它面向所有希望专注工具在真实中断场景（后台切换、休息、系统终止）下依然表现正确的人。

## ✨ 亮点

- **任务关联的专注会话** — 完整的任务增删改查（CRUD），支持多段式专注会话的暂停/恢复，以及独立的休息计时器。
- **面向中断的设计** — 一个生命周期服务会在应用切换到后台时自动暂停当前会话，并在回到前台时恢复。
- **进程被杀后的恢复** — 下次启动时，未完成的会话会被标记为 `PAUSED`，并记录 `interruption_reason = 'APP_KILLED'`，让历史保持一致，而不会留下悬空数据。
- **可靠的关系型存储** — 一个 DB 版本为 3 的 RelationalStore (RDB) 模式，包含 4 张表、7 个索引、外键约束，以及幂等的列级迁移。
- **Store 模式的状态层** — 在 `@Observed` 状态对象之上的静态类单例，配合 `Result<T>` 成功/错误信封，带来可预测的数据流。
- **高效重绘的计时器** — 计时器每次 tick 只更新本地状态，避免每秒触发整页重绘。

## 🏗 工作原理

Focus 分为三层：

- **UI（ArkUI）：** 渲染任务列表、专注/休息计时器与会话历史的页面组件。
- **状态（Store 模式）：** 静态类单例包裹一个 `@Observed` 状态对象，并暴露返回 `Result<T>` 信封的操作；计时器的 tick 保存在本地状态中，以避免整页重新渲染。
- **持久化（RelationalStore）：** 一个带版本管理的 RDB 模式（DB v3），含外键与索引，并通过幂等迁移在不破坏既有数据的前提下新增列。

一个生命周期服务把这几层串联起来：它观察前台/后台切换以自动暂停与恢复，并在启动时协调未完成的会话，从而实现进程被杀后的恢复。

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

已使用 **Hypium**（`@ohos/hypium`）搭建单元测试脚手架。中断与进程被杀恢复流程已在真机上验证。更广泛的自动化测试覆盖仍在路线图上，目前并未声称已经具备。

## 📌 项目状态

一个可用的 MVP。核心流程——任务管理、专注/休息会话、后台自动暂停以及进程被杀后的恢复——已端到端可用；更广泛的自动化测试覆盖仍在计划中。

## 📄 许可证

以 **MIT License** 发布——参见 [LICENSE](LICENSE)。

<p align="center"><sub>Built by <a href="https://github.com/SensLiao">Ruixuan "Sens" Liao</a> · USYD Advanced Computing (Honours)</sub></p>
