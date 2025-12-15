# Focus 专注 App - MVP 演示指南

> HarmonyOS ArkTS Stage 模型专注应用  
> 版本：v1.0-mvp  
> 日期：2025-12-14

---

## 📋 项目概述

Focus 专注 App 是一个基于 HarmonyOS Stage 模型的专注管理应用，采用"软专注"策略，帮助用户建立专注习惯。

### 核心特性
- ✅ 任务管理（CRUD）
- ✅ 专注计时（支持暂停/继续/多段）
- ✅ 无任务快速专注
- ✅ 休息提醒
- ✅ 前后台自动暂停
- ✅ 历史记录统计
- ✅ 系统专注模式引导

---

## 🚀 快速启动

### 前置要求
- DevEco Studio 4.0+
- HarmonyOS SDK API 10+
- 真机或模拟器

### 启动步骤

1. **打开项目**
   ```bash
   # 在 DevEco Studio 中打开 d:\Testing_App
   ```

2. **安装依赖**
   - DevEco Studio 会自动同步依赖
   - 检查 `oh-package.json5` 是否正常

3. **运行项目**
   - 连接真机/启动模拟器
   - 点击 Run 按钮（或 Shift+F10）
   - 等待编译和安装

4. **首次启动**
   - 应用会请求 `PUBLISH_AGENT_REMINDER` 权限
   - 点击允许以启用提醒功能

---

## 🎯 完整演示流程

### 场景 1：无任务快速专注

1. 启动应用，进入首页
2. 点击 **"快速开始专注（无任务）"**
3. 跳转到专注页，计时器开始运行
4. 观察计时器实时更新（秒级）
5. 点击 **"暂停"** → 计时器停止
6. 点击 **"继续"** → 创建新段，继续计时
7. 点击 **"结束专注"** → 会话完成，返回首页

**预期结果**：数据库中保存匿名任务和专注会话记录

---

### 场景 2：创建任务并专注

1. 首页点击 **"+ 新建任务"**
2. 输入任务标题：`完成项目报告`
3. 输入任务描述（可选）：`撰写季度总结PPT`
4. 点击 **"创建任务"** → 返回首页
5. 在任务列表中找到刚创建的任务
6. 点击任务右侧的 **"开始"** 按钮
7. 跳转到专注页，显示任务标题
8. 专注 1-2 分钟
9. 点击 **"结束专注"** → 任务标记为完成

**预期结果**：任务从首页消失，在历史页可查看

---

### 场景 3：休息功能

1. 开始任何专注（有任务或无任务）
2. 专注一段时间后，点击 **"休息"** 按钮
3. 当前专注自动暂停，跳转到休息计时器
4. 观察环形进度条和倒计时（默认 5 分钟）
5. 可选操作：
   - 等待倒计时结束 → 自动恢复专注
   - 点击 **"结束休息"** → 手动提前结束
6. 恢复专注后，会创建新的专注段（第 2 段）

**预期结果**：数据库记录休息事件，会话 break_count +1

---

### 场景 4：切后台自动暂停

1. 开始专注（计时器运行中）
2. 按 Home 键或切换到其他应用
3. 系统触发 `onBackground()` → 自动暂停计时
4. 5 分钟后收到系统提醒："专注会话已暂停"
5. 点击通知返回应用
6. 系统触发 `onForeground()` → 取消提醒
7. 用户可选择继续或结束专注

**预期结果**：数据正确保存，用户体验流畅

---

### 场景 5：杀进程恢复

1. 开始专注（计时器运行中）
2. 从最近任务列表强制关闭应用
3. 重新启动应用
4. 首页 `aboutToAppear()` 检测到未完成会话
5. 会话自动标记为 `PAUSED`，写入 `interruption_reason = 'APP_KILLED'`
6. 可显示恢复对话框（可选实现）

**预期结果**：数据库状态一致，无数据丢失

---

### 场景 6：查看历史

1. 完成至少 1 个任务的专注
2. 首页点击右上角 **"历史"** 按钮
3. 跳转到历史页
4. 查看统计卡片：
   - 已完成任务数
   - 总专注时长
5. 查看任务列表：
   - 任务标题
   - 专注时长
   - 完成时间

**预期结果**：数据准确展示，时间格式正确

---

### 场景 7：系统专注模式引导

1. 首页点击右上角 **"引导"** 按钮
2. 跳转到引导页
3. 阅读三个说明卡片：
   - 开启系统专注模式
   - 本应用的专注机制
   - 使用建议
4. 点击 **"前往系统设置"** → 跳转到系统设置
5. 用户手动开启 DND/专注模式（可选）

**预期结果**：用户理解应用机制，建立合理预期

---

## 📁 项目结构

```
entry/src/main/ets/
├─ entryability/
│  └─ EntryAbility.ets          # 入口 + 生命周期注入
├─ pages/
│  ├─ Index.ets                 # 首页（任务列表）
│  ├─ FocusPage.ets             # 专注页
│  ├─ TaskEditPage.ets          # 任务编辑页
│  ├─ GuidePage.ets             # 引导页
│  └─ HistoryPage.ets           # 历史页
├─ components/
│  ├─ TaskItem.ets              # 任务列表项
│  ├─ FocusTimer.ets            # 专注计时器
│  ├─ BreakTimer.ets            # 休息计时器
│  └─ StatCard.ets              # 统计卡片
├─ store/
│  ├─ taskStore.ets             # 任务状态管理
│  └─ focusStore.ets            # 专注状态管理
├─ services/
│  ├─ TimerService.ets          # 计时器服务
│  ├─ ReminderService.ets       # 提醒服务
│  └─ AppLifecycleService.ets   # 生命周期服务
├─ data/
│  ├─ RdbClient.ets             # RDB 连接
│  ├─ TaskRepo.ets              # 任务 Repo
│  ├─ SessionRepo.ets           # 会话 Repo
│  ├─ SegmentRepo.ets           # 段 Repo
│  └─ BreakRepo.ets             # 休息 Repo
├─ model/
│  ├─ Task.ets                  # 任务实体
│  ├─ FocusSession.ets          # 会话实体
│  ├─ FocusSegment.ets          # 段实体
│  ├─ BreakEvent.ets            # 休息实体
│  ├─ SessionStatus.ets         # 状态枚举
│  └─ Result.ets                # Result<T> 类型
└─ common/
   ├─ constants.ets             # 常量
   ├─ theme.ets                 # 主题
   └─ logger.ets                # 日志
```

---

## 🗄️ 数据库结构

### tasks 表
```sql
CREATE TABLE tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  description TEXT,
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  is_anonymous INTEGER NOT NULL DEFAULT 0,
  total_focus_time INTEGER NOT NULL DEFAULT 0
);
```

### focus_sessions 表
```sql
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
```

### focus_segments 表
```sql
CREATE TABLE focus_segments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  segment_index INTEGER NOT NULL,
  start_at INTEGER NOT NULL,
  end_at INTEGER,
  duration_ms INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (session_id) REFERENCES focus_sessions(id) ON DELETE CASCADE
);
```

### break_events 表
```sql
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
```

---

## 🔑 关键技术点

### 1. 外键约束启用
```typescript
// RdbClient.ets
await store.executeSql('PRAGMA foreign_keys = ON;')
```

### 2. Result<T> 模式
```typescript
// 所有 Repo 方法返回 Result<T>
const result = await TaskRepo.create(context, dto)
if (isSuccess(result)) {
  const taskId = result.data
} else {
  promptAction.showToast({ message: result.message })
}
```

### 3. Store 模式
```typescript
// 状态容器 + Actions
TaskStore.init(context)
await TaskStore.loadTasks()
await TaskStore.createTask({ title: '...' })
```

### 4. 生命周期管理
```typescript
// EntryAbility.ets
AppLifecycleService.register((event) => {
  if (event === 'background') {
    FocusStore.handleBackground()  // 自动暂停
  }
})
```

### 5. 计时器优化
```typescript
// 只刷新计时器组件，不重绘整页
TimerService.start((elapsedMs) => {
  FocusStore.state.elapsedTime = elapsedMs  // 局部状态更新
})
```

---

## ⚠️ 已知限制

### 技术限制
1. **后台计时无完美精度**：进程可能被系统回收
2. **无法阻止其他 App**：第三方应用权限限制
3. **ReminderAgent 触发时机**：受系统调度影响

### 产品限制
1. **软专注策略**：依赖用户主动留在应用内
2. **数据丢失风险**：需频繁落盘（每次暂停/结束）
3. **系统专注模式**：需用户手动开启

---

## 🐛 调试技巧

### 查看日志
```bash
# 过滤 FocusApp 日志
hdc shell hilog | grep FocusApp
```

### 清空数据库
```bash
# 卸载应用会清空数据
hdc uninstall com.example.testing_app
```

### 检查权限
```bash
# 查看应用权限
hdc shell bm dump -a
```

---

## 📝 测试清单

- [ ] 无任务快速专注
- [ ] 创建任务并专注
- [ ] 专注暂停/继续（多段）
- [ ] 休息功能（自动/手动结束）
- [ ] 切后台自动暂停
- [ ] 杀进程恢复（标记为 PAUSED）
- [ ] 历史页数据展示
- [ ] 系统专注模式跳转
- [ ] 删除任务（级联删除会话）

---

## 🚧 下一步计划（Should Have）

- [ ] 实际专注时长 vs 总时长区分
- [ ] 时间限制倒计时（到点自动结束）
- [ ] 打断原因记录（关联会话）
- [ ] 主页激励数据展示
- [ ] 按天归类任务
- [ ] 休息提示"跳过本次"
- [ ] 数据导出功能

---

## 📚 相关文档

- [架构设计文档](docs/ARCHITECTURE.md)
- [鸿蒙应用开发发布完整指南](鸿蒙应用开发发布完整指南.md)
- [HarmonyOS_ArkTS开发规范与最佳实践](HarmonyOS_ArkTS开发规范与最佳实践.md)

---

## 👨‍💻 开发者

本项目严格遵循以下规范：
- ArkTS Coding Style Guide
- Stage 模型分层架构
- Result<T> 错误处理模式
- 外键约束强制启用
- UI → Store → Service → Data 调用链

**技术栈**：ArkTS + ArkUI + Stage 模型 + RDB + ReminderAgent
