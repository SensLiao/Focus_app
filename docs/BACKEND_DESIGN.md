# Backend Design – Focus App

> **版本**：v2.0  
> **更新日期**：2025-12-17  
> **目标**：让后端（Store/Service/Data）与前端契合，实现需求文档的 Must/Should/Could 功能，并对齐现有分层架构。  
> **强调**：可执行性（迁移脚本、字段落地、Store/Service 调用链、Result 约定、事务与测试要点）  
> **相关文档**：[ARCHITECTURE.md](./ARCHITECTURE.md) | [FRONTEND_DESIGN.md](./FRONTEND_DESIGN.md)

## 1. 领域模型与 ER 映射（基于附件图）
- Task (任务)
  - id, title, description, createdAt, **lastCompletedAt**（最后完成时间，支持多次完成）, isAnonymous, totalFocusTime, **activeSessionId**（当前活动会话ID，用于UI指示和恢复）, **sessionCount**（完成的会话总数）
- FocusSession (专注会话)
  - id, taskId?, startAt, endAt, status(RUNNING/PAUSED/FINISHED), actualFocusDuration, totalDuration, breakCount, interruptionReason
  - timeLimitMs?（倒计时上限）
  - sessionType?（NORMAL/COUNTDOWN/POMODORO，对应正计时/倒计时/番茄钟）
  - restIntervalMs?, restDurationMs?（休息间隔/休息时长）
- FocusSegment (专注段)
  - id, sessionId, segmentIndex, startAt, endAt, durationMs (用于多段累积专注)
- BreakEvent (休息事件)
  - id, sessionId, startAt, endAt, plannedDuration, actualDuration, isSkipped (图中 rest_record, rest_count)
- InterruptionReason (可复用 BreakEvent.interruptionReason 或 Session.interruptionReason；需求7.x)
- User (暂不落库，若后续需要分析用户/多账号，再新增 user 表 + analysis_result 字段)

**关键设计理念**（借鉴React应用）：
- **任务可多次完成**：完成会话后任务保留在列表，`totalFocusTime`累积，`sessionCount`递增
- **活动会话追踪**：`activeSessionId`非空时UI显示特殊图标（咖啡杯），点击直接恢复
- **单活动会话原则**：同时只能有一个RUNNING会话，启动新会话前需检查并提示切换

## 2. 数据库设计与迁移建议（可直接落代码）
现有表已覆盖 Task/Session/Segment/Break。新增字段对齐需求：
- focus_sessions
  - time_limit_ms INTEGER DEFAULT NULL
  - session_type TEXT DEFAULT 'NORMAL' CHECK(session_type IN ('NORMAL','COUNTDOWN','POMODORO'))
  - rest_interval_ms INTEGER DEFAULT NULL
  - rest_duration_ms INTEGER DEFAULT NULL
  - interruption_reason TEXT
- break_events
  - reason TEXT DEFAULT NULL  // 记录休息/中断原因（需求7.1）

索引（保持现有）：idx_sessions_task_id(task_id)、idx_sessions_start(start_at)、idx_segments_session_id(session_id)、idx_breaks_session_id(session_id)。

外键：每次连接后执行 `PRAGMA foreign_keys = ON;`（已在 RdbClient）。

迁移方案：
- RdbClient.DB_VERSION = DB_VERSION + 1。
- onUpgrade(store, old, new):
  - if old < new:
    - ALTER TABLE focus_sessions ADD COLUMN time_limit_ms INTEGER;
    - ALTER TABLE focus_sessions ADD COLUMN session_type TEXT DEFAULT 'NORMAL' CHECK(session_type IN ('NORMAL','COUNTDOWN','POMODORO'));
    - ALTER TABLE focus_sessions ADD COLUMN rest_interval_ms INTEGER;
    - ALTER TABLE focus_sessions ADD COLUMN rest_duration_ms INTEGER;
    - ALTER TABLE focus_sessions ADD COLUMN interruption_reason TEXT;
    - ALTER TABLE break_events ADD COLUMN reason TEXT;
  - 不删除旧列，保持向后兼容。
- 默认值不影响旧行；UI 读取为空时使用默认配置。
- 可选：在 onUpgrade 末尾执行一次 VACUUM（可跳过以减少升级成本）。

## 3. Repository API（门面，不暴露 SQL）
- TaskRepo
  - create(dto): Result<number>
  - update(id, dto): Result<void>
  - delete(id): Result<void> // 级联删除
  - findById(id): Result<Task>
  - findActive(): Result<Task[]>  // 查询未删除的任务（不再按completedAt区分）
  - findWithActiveSession(): Result<Task[]>  // 查询有活动会话的任务
  - findCompleted(limit?, offset?): Result<Task[]>  // 按lastCompletedAt排序
  - **updateActiveSession(taskId, sessionId?): Result<void>**  // 设置/清除活动会话ID
  - **incrementSessionCount(taskId): Result<void>**  // 会话完成时递增计数
- SessionRepo
  - create(taskId?, opts { timeLimitMs?, sessionType?, restIntervalMs?, restDurationMs?, interruptionReason? }): Result<number>
  - updateStatus(id, status, patch): Result<void> // patch 可含 time_limit_ms/session_type/rest_interval_ms/rest_duration_ms/interruption_reason
  - updateDurations(id, actualFocusDuration, totalDuration, breakCount): Result<void>
  - findById(id): Result<FocusSession>
  - findRunning(): Result<FocusSession|null>
  - findByTask(taskId): Result<FocusSession[]>
- SegmentRepo
  - create(sessionId, segmentIndex, startAt): Result<number>
  - finish(id, endAt, durationMs): Result<void>
  - findLastBySession(sessionId): Result<FocusSegment|null>
- BreakRepo
  - create(sessionId, plannedDuration, startAt, isSkipped=false, reason?): Result<number>
  - finish(id, endAt, actualDuration, reason?): Result<void>
  - findBySession(sessionId): Result<BreakEvent[]>

## 4. Store 层动作设计（前端契约 + 伪代码要点）
- FocusStore
  - startFocus(taskId?, options { timeLimitMs?, sessionType?, restIntervalMs?, restDurationMs?, interruptionReason? })
    - **检查是否有其他活动会话**：查询所有task.activeSessionId !== null，若存在弹窗提示切换
    - 创建 session + 第1段；启动计时器；若倒计时设置截止时间；回写状态。
    - **更新task.activeSessionId = sessionId**
  - pauseFocus(reason?)
    - 停止计时器；结束当前段；updateStatus(PAUSED, interruption_reason=reason)；可创建 return reminder。
  - resumeFocus()
    - 新建下一段；updateStatus(RUNNING)；恢复计时器；取消 return reminder。
  - finishFocus(reason?)
    - 结束当前段；聚合 actualFocusDuration/totalDuration；updateStatus(FINISHED, interruption_reason=reason)。
    - **更新 Task**：totalFocusTime += actualFocusDuration；lastCompletedAt = now()；sessionCount++；activeSessionId = null。
    - 取消所有提醒；**任务保留在列表中，可再次启动新会话**。
  - startBreak(durationMs, reason?)
    - 暂停专注计时；create break_event(reason)；启动休息计时/提醒；isBreaking=true。
  - finishBreak(reason?)
    - 结束 break_event；isBreaking=false；自动 resumeFocus()（除非 session 已结束）。
  - extendTimeLimit(deltaMs)
    - 更新 session.time_limit_ms；重新计算剩余；若已超时则触发 finish。
  - handleBackground()
    - pauseFocus(reason='app_background'); 创建 return reminder (5min)。
  - handleForeground()
    - 取消 return reminder；提示用户继续/结束。
  - checkAndRecoverSession()
    - 启动时查 RUNNING；标记为 PAUSED + interruption_reason='APP_KILLED'；提示恢复。
    - **若有task.activeSessionId，在Index首页显示恢复入口**（咖啡图标脉动效果）。
  - setInterruptionReason(reason)
    - 写入当前 session.interruption_reason 或 break.reason。

- TaskStore
  - loadTasks(); createTask(); updateTask(); deleteTask(); completeTask(taskId)

所有 action 返回 Result<void> 供 UI 做提示；错误不污染状态，必要时重新加载。

## 5. Service 层
- TimerService：前台计时；支持正计时与倒计时（传入 timeLimitMs）；tick 回调更新 elapsed/remaining。
- ReminderService：封装 ReminderAgent；场景：专注结束倒计时（可选）、休息结束提醒、切后台 5 分钟提醒返回；失败时返回 Result 供 UI 提示。
- AppLifecycleService：分发 foreground/background/destroy 事件，供 FocusStore 订阅。

## 6. 数据一致性与事务
- start/pause/resume/finish：段结束与 session 状态更新放入同一事务（避免部分写入）；必要时在 Repo 内部使用 batch SQL。
- break 记录与 session.breakCount 同步更新。
- 删除任务：依赖 ON DELETE CASCADE；UI 需确认提示。
- 迁移时避免锁表过长，ALTER 列顺序按上方列表执行。

## 7. 计算口径
- actualFocusDuration：所有已结束专注段 duration 之和（不含休息）。
- totalDuration：session.endAt - session.startAt（含休息/暂停）；若未结束则用 now 计算。
- breakCount：break_events 数量（跳过的不计数）。

## 8. 业务规则对应需求
- 倒计时到点自动结束：TimerService 达零触发 finishFocus(reason='timeout')。
- 强制结束倒计时：finishFocus(reason='force_stop_limit')。
- 新一轮倒计时：startFocus 同 taskId，新 session。
- 延长倒计时：extendTimeLimit(+5min)。
- 循环休息：startFocus 保存 restInterval/restDuration；Timer tick 达 interval 自动 startBreak；跳过不记记录。
- 休息延长：finishBreak 前用户点“再休息5分钟”，可选择更新当前 planned/actual 或关闭当前 break 并新建 5 分钟 break。
- 干扰原因：pause 或 break 结束时写 interruption_reason / break.reason。
- 后台/杀进程：handleBackground → pause + reminder；checkAndRecoverSession → 将 RUNNING 改 PAUSED 并写 reason。

## 9. 错误处理与返回格式
- 统一 Result<T>
  - ok: true/false; code; message; data?
- Repo 层不抛异常给 UI；所有错误转 Result。
- Store 捕获后：
  - UI Toast message
  - 不污染状态（回滚本地状态或重新 load）

## 10. 性能与可靠性
- 索引：维持 task_id/session_id/start_at 索引以支撑历史/统计查询。
- 计时器：只在前台运行；后台依赖 Reminder 提醒用户返回。
- 落盘频率：
  - start → 新建 session/segment
  - pause/resume → 结束/新建段，更新 session
  - finish → 汇总后写 session+task
  - break 开始/结束 → 立即落盘
- 统计扩展（需求8.5/8.6）：可新增 daily_stats 物化视图/表，按日期聚合；前端激励卡片读取聚合结果。
- 迁移安全：ALTER TABLE 顺序固定；失败需回滚并提示；建议在升级前自动备份（可选）。

## 11. 安全与权限
- 必要权限：ohos.permission.PUBLISH_AGENT_REMINDER。
- 日志：生产关闭 debug；不打印任务内容。
- 若需加密：RdbClient 配置 SecurityLevel.S3 + encrypt=true。

## 12. 测试建议
- 单元：Repo CRUD；Store start/pause/resume/finish/break 流程；倒计时触发；后台恢复。
- 集成：Reminder 回调路径；生命周期事件对状态影响；迁移 onUpgrade 兼容旧数据（老库升级后字段存在且默认值为空）。
- UI/E2E：任务 CRUD；专注多段；休息跳过/延长；后台暂停；倒计时自动结束；恢复弹窗；权限拒绝场景。
