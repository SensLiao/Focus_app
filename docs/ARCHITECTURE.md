# Focus App MVP 架构设计文档

> 版本：v1.0-mvp  
> 日期：2025-12-14  
> 模型：Stage 模型 + ArkTS + ArkUI + RDB

---

## 1. MVP 范围确认

### 1.1 Must Have（两周内交付）
- ✅ 任务 CRUD：创建/编辑/删除待办事项
- ✅ 任务专注计时：单任务启动专注、支持暂停/继续
- ✅ 无任务直接计时：结束后保存为匿名完成事项
- ✅ 多段会话：单次专注可暂停并生成多个 FocusSegment
- ✅ 前后台行为：切后台自动暂停、返回恢复、离开挽留/通知
- ✅ 休息会话：可设置休息间隔与时长、休息开始/结束提示
- ✅ 数据持久化：RDB 存储任务、会话、段、休息记录
- ✅ 历史记录：查看已完成任务和专注统计

### 1.2 Should Have（有余力）
- 记录 actual_focus_duration vs total_duration
- 时间限制倒计时（到点自动结束）
- 打断原因记录

### 1.3 Out of Scope（明确不做）
- 系统级阻止其他 App
- 全局 DND 控制
- 读取其他 App 使用时长
- 后台秒级精准计时

---

## 2. 页面信息架构

### 2.1 页面列表
| 页面 | 路径 | 功能 |
|------|------|------|
| 首页（任务列表） | pages/Index | 任务 CRUD、快速开始专注 |
| 专注页 | pages/FocusPage | 全屏计时、暂停/继续、休息 |
| 引导页 | pages/GuidePage | 教学系统专注模式、跳转设置 |
| 历史页 | pages/HistoryPage | 已完成任务、专注记录 |
| 任务编辑页 | pages/TaskEditPage | 创建/编辑任务详情 |

### 2.2 页面跳转图
```
Index (首页)
  ├─> TaskEditPage (新建/编辑)
  ├─> FocusPage (开始专注)
  ├─> HistoryPage (查看历史)
  └─> GuidePage (首次引导)

FocusPage
  └─> Index (结束后返回)
```

---

## 3. 数据模型

### 3.1 实体定义

#### Task（任务）
```typescript
export interface Task {
  id: number
  title: string
  description?: string
  createdAt: number
  completedAt?: number
  isAnonymous: boolean  // true 表示无任务直接计时
  totalFocusTime: number // 累计专注时长（ms）
}
```

#### FocusSession（专注会话）
```typescript
export interface FocusSession {
  id: number
  taskId?: number  // 可空，匿名任务则为空
  startAt: number
  endAt?: number
  status: SessionStatus  // RUNNING | PAUSED | FINISHED
  actualFocusDuration: number  // 纯专注时长（不含休息）
  totalDuration: number        // 总时长（含休息/暂停）
  breakCount: number           // 休息次数
  interruptionReason?: string  // 打断原因
}

export enum SessionStatus {
  RUNNING = 'RUNNING',
  PAUSED = 'PAUSED',
  FINISHED = 'FINISHED'
}
```

#### FocusSegment（专注段）
```typescript
export interface FocusSegment {
  id: number
  sessionId: number
  segmentIndex: number  // 第几段（1/2/3...）
  startAt: number
  endAt?: number
  durationMs: number
}
```

#### BreakEvent（休息事件）
```typescript
export interface BreakEvent {
  id: number
  sessionId: number
  startAt: number
  endAt?: number
  plannedDuration: number  // 计划休息时长
  actualDuration: number   // 实际休息时长
  isSkipped: boolean       // 是否跳过
}
```

---

## 4. RDB 表结构与索引

### 4.1 表结构（SQLite）

```sql
-- 任务表
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  is_anonymous INTEGER NOT NULL DEFAULT 0,
  total_focus_time INTEGER NOT NULL DEFAULT 0
);

-- 会话表
CREATE TABLE focus_sessions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER,
  start_at INTEGER NOT NULL,
  end_at INTEGER,
  status TEXT NOT NULL CHECK(status IN ('RUNNING','PAUSED','FINISHED')),
  actual_focus_duration INTEGER NOT NULL DEFAULT 0,
  total_duration INTEGER NOT NULL DEFAULT 0,
  break_count INTEGER NOT NULL DEFAULT 0,
  interruption_reason TEXT,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- 专注段表
CREATE TABLE focus_segments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  segment_index INTEGER NOT NULL,
  start_at INTEGER NOT NULL,
  end_at INTEGER,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES focus_sessions(id) ON DELETE CASCADE
);

-- 休息事件表
CREATE TABLE break_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  start_at INTEGER NOT NULL,
  end_at INTEGER,
  planned_duration INTEGER NOT NULL,
  actual_duration INTEGER NOT NULL DEFAULT 0,
  is_skipped INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES focus_sessions(id) ON DELETE CASCADE
);

-- 索引
CREATE INDEX idx_tasks_completed ON tasks(completed_at);
CREATE INDEX idx_sessions_task_id ON focus_sessions(task_id);
CREATE INDEX idx_sessions_start ON focus_sessions(start_at);
CREATE INDEX idx_segments_session_id ON focus_segments(session_id);
CREATE INDEX idx_breaks_session_id ON break_events(session_id);
```

### 4.2 外键启用策略
- **每次连接** RDB 后立即执行：`PRAGMA foreign_keys = ON;`
- 实现位置：`RdbClient.getStore()` 方法内

---

## 5. ReminderAgent / BackgroundTasksKit 使用策略

### 5.1 ReminderAgent 使用场景
| 场景 | 类型 | 说明 |
|------|------|------|
| 专注结束提醒 | Timer | 倒计时 N 分钟后触发 |
| 休息结束提醒 | Timer | 休息时长到期提醒 |
| 离开后挽留提醒 | Timer | 切后台 5 分钟后提醒继续 |

### 5.2 BackgroundTasksKit 使用场景
- **短时任务**：用于离开后延迟提醒的兜底（ReminderAgent 主，BG Task 辅）
- **不用于**：后台精准计时（无法保证）

### 5.3 实现要点
- ReminderAgent 回调只能被动接收，不依赖轮询
- 提醒 ID 与 sessionId 关联，用于取消/查询
- 切后台时：暂停计时 + 创建 ReminderAgent 提醒
- 回前台时：取消未触发的提醒 + 恢复计时

---

## 6. 前后台/杀进程恢复策略

### 6.1 前后台切换感知
- **监听**：UIAbility `onForeground()` / `onBackground()`
- **行为**：
  - `onBackground()`：暂停当前会话、保存状态、创建离开提醒
  - `onForeground()`：取消提醒、询问用户是否继续

### 6.2 杀进程恢复
- **启动时检测**：查询 DB 中 `status='RUNNING'` 的会话
- **处理逻辑**：
  - 将该会话标记为 `PAUSED`
  - 写入 `interruption_reason = 'APP_KILLED'`
  - 提示用户："上次会话已暂停，是否继续？"

### 6.3 数据一致性保证
- 会话状态变更必须原子化（status + segment end_at）
- 使用事务确保多表写入一致性

---

## 7. 技术栈与分层

### 7.1 技术栈
- **语言**：ArkTS
- **UI**：ArkUI（声明式）
- **模型**：Stage 模型（UIAbility）
- **存储**：ArkData RDB（SQLite）
- **后台**：ReminderAgent + BackgroundTasksKit
- **状态管理**：Store 模式（自实现，类 Redux）

### 7.2 分层职责
```
┌─────────────────────────────────────┐
│  UI Layer (pages + components)      │  ← 只做展示和交互
├─────────────────────────────────────┤
│  Store Layer (focusStore/taskStore) │  ← 状态容器 + actions
├─────────────────────────────────────┤
│  Service Layer                       │  ← 封装系统能力
│  (ReminderService/LifecycleService)  │
├─────────────────────────────────────┤
│  Data Layer (Repo + RdbClient)       │  ← 持久化实现
└─────────────────────────────────────┘
```

### 7.3 调用链
```
UI → Store → Service → Data
       ↑         ↓
    (emit)   (Result<T>)
```

---

## 8. 文件清单（MVP 最小集）

```
entry/src/main/ets/
├─ entryability/
│  └─ EntryAbility.ets              # 入口，注入 LifecycleService
├─ pages/
│  ├─ Index.ets                     # 首页（任务列表）
│  ├─ FocusPage.ets                 # 专注页
│  ├─ GuidePage.ets                 # 引导页
│  ├─ HistoryPage.ets               # 历史页
│  └─ TaskEditPage.ets              # 任务编辑页
├─ components/
│  ├─ TaskItem.ets                  # 任务列表项
│  ├─ FocusTimer.ets                # 专注计时器
│  ├─ BreakTimer.ets                # 休息计时器
│  └─ StatCard.ets                  # 统计卡片
├─ store/
│  ├─ focusStore.ets                # 专注会话状态
│  └─ taskStore.ets                 # 任务状态
├─ services/
│  ├─ ReminderService.ets           # 提醒管理
│  ├─ AppLifecycleService.ets       # 前后台事件分发
│  └─ TimerService.ets              # 计时器服务
├─ data/
│  ├─ RdbClient.ets                 # RDB 连接与初始化
│  ├─ TaskRepo.ets                  # 任务 CRUD
│  ├─ SessionRepo.ets               # 会话 CRUD
│  ├─ SegmentRepo.ets               # 段 CRUD
│  └─ BreakRepo.ets                 # 休息 CRUD
├─ model/
│  ├─ Task.ets                      # 任务实体
│  ├─ FocusSession.ets              # 会话实体
│  ├─ FocusSegment.ets              # 段实体
│  ├─ BreakEvent.ets                # 休息实体
│  ├─ SessionStatus.ets             # 会话状态枚举
│  └─ Result.ets                    # Result<T> 类型
└─ common/
   ├─ constants.ets                 # 常量
   ├─ theme.ets                     # 主题
   └─ logger.ets                    # 日志工具
```

---

## 9. 状态管理设计（Store）

### 9.1 focusStore
```typescript
interface FocusState {
  currentSession: FocusSession | null
  currentSegmentStartAt: number | null
  isBreaking: boolean
  breakStartAt: number | null
  timerInterval: number  // 计时器 tick 间隔（ms）
  elapsedTime: number    // 当前段已流逝时间（ms）
}

// Actions
- startFocus(taskId?: number)
- pauseFocus()
- resumeFocus()
- finishFocus()
- startBreak(duration: number)
- finishBreak()
```

### 9.2 taskStore
```typescript
interface TaskState {
  tasks: Task[]
  loading: boolean
  error: string | null
}

// Actions
- loadTasks()
- createTask(task: Partial<Task>)
- updateTask(id: number, updates: Partial<Task>)
- deleteTask(id: number)
```

---

## 10. 关键流程设计

### 10.1 开始专注流程
```
用户点击"开始专注"
  → focusStore.startFocus(taskId)
    → SessionRepo.createSession(taskId)
    → SegmentRepo.createSegment(sessionId)
    → TimerService.start()
    → ReminderService.scheduleEndReminder() [可选]
  → 跳转 FocusPage
```

### 10.2 切后台流程
```
系统触发 onBackground()
  → AppLifecycleService.emit('background')
    → focusStore.pauseFocus()
      → 计算当前段时长
      → SegmentRepo.finishSegment(segmentId, duration)
      → SessionRepo.updateStatus(sessionId, 'PAUSED')
      → ReminderService.scheduleReturnReminder(5min)
    → 发送通知："专注已暂停，点击恢复"
```

### 10.3 回前台流程
```
系统触发 onForeground()
  → AppLifecycleService.emit('foreground')
    → ReminderService.cancelReturnReminder()
    → 弹窗："是否继续专注？"
      → 是 → focusStore.resumeFocus()
      → 否 → focusStore.finishFocus()
```

### 10.4 杀进程恢复流程
```
App 启动
  → EntryAbility.onCreate()
    → SessionRepo.findRunningSession()
    → 若有 → 标记为 PAUSED + 写入 interruption_reason
    → 跳转 Index 并提示："上次会话已暂停"
```

---

## 11. 性能优化点

### 11.1 UI 性能
- 计时器只刷新 `FocusTimer` 组件（@State elapsedTime）
- 任务列表使用 `List` + `LazyForEach`
- 避免整页 `@State`，拆分组件粒度

### 11.2 启动性能
- RDB 延迟初始化（首次使用时连接）
- 任务列表分页加载（MVP 可暂不做）

### 11.3 数据性能
- 所有外键列建索引
- `tasks` 表按 `completed_at` 索引（历史查询）
- 避免 `SELECT *`（只查需要的字段）

---

## 12. 已知限制与风险

### 12.1 技术限制
- ❌ 后台计时无秒级精度（进程可能被回收）
- ❌ 无法阻止用户使用其他 App
- ❌ ReminderAgent 触发时机受系统调度影响

### 12.2 产品风险
- 用户习惯依赖：需引导用户"在 App 内专注"
- 数据丢失风险：需频繁落盘（每次暂停/结束）

### 12.3 兜底策略
- 启动时检测未结算会话
- 用户可手动"放弃当前会话"
- 提供数据导出功能（后续）

---

## 13. 测试策略

### 13.1 单元测试
- `TaskRepo` CRUD
- `SessionRepo` 状态转换
- `focusStore` actions

### 13.2 集成测试
- 完整专注流程（开始→暂停→继续→结束）
- 前后台切换与恢复
- 提醒触发与取消

### 13.3 手工测试
- 杀进程恢复
- 系统专注模式跳转
- 休息提醒准确性

---

## 附录：技术决策记录

| 决策 | 原因 | 替代方案 |
|------|------|----------|
| 使用 RDB 而非 Preferences | 结构化数据、关系查询 | KV 存储 |
| 使用 ReminderAgent | 系统托管、稳定 | WorkScheduler |
| 切后台自动暂停 | 第三方 App 无后台精准计时 | 尝试后台计时 |
| Store 自实现 | 轻量、可控 | 引入状态管理库 |

---

**文档版本**：v1.0  
**下次更新**：MVP 交付后
