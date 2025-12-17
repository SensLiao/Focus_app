# Frontend Design – Focus App

> **版本**：v2.0  
> **更新日期**：2025-12-17  
> **设计参考**：[Figma Design Link](https://www.figma.com/make/jEnyNbwbbfW22y9kEwjNWP/Focus-App)  
> **详细UI规范**：参见 [UI_DESIGN_SPECIFICATION.md](./UI_DESIGN_SPECIFICATION.md)

---

## 概述

本文档定义 Focus App 的前端架构、页面结构、交互流程和组件职责，与现有 ArkTS 架构、Store/Service/Data 层契合。强调"可实现度"与"代码对齐度"，便于后续 AI/人工快速落地。

**核心设计理念**：
- **Clean / Minimalist UI**：留白、圆角、冷色调传达专注感
- **状态驱动**：UI 只读 Store 状态，所有变更经 action 触发
- **单向数据流**：Component → Action → Store → Update → Component
- **用户体验优先**：流畅动画、即时反馈、容错设计

---

## 1. 页面与导航（信息架构 + 路由）

### 1.1 页面列表与职责

| 页面 | 路径 | 核心职责 | 状态来源 | 关键交互 |
|------|------|----------|----------|----------|
| **首页** | pages/Index | 任务列表、快速专注入口、底部导航（Home/History/Settings）；首屏执行"未完成会话恢复"提示 | TaskStore, FocusStore | 点击任务播放按钮 → StartPage；点击 FAB → StartPage；会话恢复提示 → TimerPage |
| **启动配置页** | pages/StartPage | 专注前配置（选择/创建任务、设置倒计时模式、休息间隔等）；包含"创建任务"和"无任务启动"两个入口 | TaskStore, FocusStore, SettingsService | 配置完成 → TimerPage；创建任务 → TaskEditPage；无任务启动 → TimerPage（匿名会话） |
| **计时页** | pages/TimerPage (FocusPage) | 实际运行中的全屏计时页面，显示大圆形进度环、计时器、状态切换（专注/休息）、操作按钮（暂停/继续/休息/结束）；前后台提示、倒计时到点自动结束、延长/强制结束；干扰原因输入弹窗 | FocusStore（实时订阅） | 暂停 → 弹出干扰原因输入；休息 → 切换到休息模式；完成 → 返回首页 |
| **休息视图** | 同 TimerPage 内部状态 | TimerPage 内部状态切换到休息模式，圆环和UI显示休息进度（支持跳过/延长） | FocusStore（isBreaking=true） | 结束休息 → 恢复专注；延长 → 增加休息时长 |
| **任务编辑** | pages/TaskEditPage | 创建/编辑任务详情（表单校验：标题必填 ≤ 60 字；描述可选 ≤ 200 字） | TaskStore | 保存 → 返回上一页；取消 → 返回上一页 |
| **历史记录** | pages/HistoryPage | 完成任务与会话统计（按日期或任务分组，展示休息次数/总时长/实际专注时长）；支持按任务/日期筛选 | SessionRepo, TaskStore | 点击详情 → 展开底部抽屉；筛选 → 重新加载数据 |
| **引导页** | pages/GuidePage | 系统专注模式教学 + 跳转设置（按钮拉起系统设置） | SettingsService | 跳转系统设置 → 打开系统设置页 |
| **设置页** | pages/SettingsPage | 通知开关、默认专注时长、默认休息时长与间隔、是否自动延长休息、数据导出占位 | SettingsService | 修改设置 → 保存到本地存储 |

**设计要点**：
- **StartPage 作为配置中心**：所有专注会话启动前都经过 StartPage 进行参数配置，避免在 Index 直接启动导致的状态混乱
- **TimerPage 纯运行态**：进入时必须已有 `currentSession`，否则立即返回 Index；避免配置逻辑混入运行页面
- **底部导航仅三个 Tab**：Home（Index）、History、Settings；简洁明了，符合 Minimalist 设计理念

### 1.2 导航结构与路由逻辑
```
Index (首页) - 带底部导航 Tab Bar (Home/History/Settings)
  ├─> 点击 FAB (+) ────────────> StartPage (启动配置页)
  ├─> 点击任务「开始」按钮 ───> StartPage (传入 taskId，预填任务信息)
  ├─> 底部 Tab: History ─────> HistoryPage
  ├─> 底部 Tab: Settings ────> SettingsPage
  └─> 首屏恢复提示 ───────────> TimerPage (恢复未完成会话)

StartPage (启动配置页)
  ├─> 点击「创建任务」─────────> TaskEditPage (创建新任务)
  ├─> 点击「开始专注」─────────> TimerPage (启动会话，跳转到运行计时页)
  └─> 点击「无任务启动」───────> TimerPage (匿名会话)

TaskEditPage (任务编辑)
  └─> 保存/取消 ─────────────> router.back() 返回 StartPage 或 Index

TimerPage (运行计时页)
  ├─> 结束专注 ───────────────> Index (返回首页)
  ├─> 暂停后退出 ─────────────> Index (保存暂停状态)
  └─> 切后台/回前台 ───────────> 自动暂停/恢复提示对话框

HistoryPage
  └─> 点击「查看详情」─────────> (展开卡片或跳转详情页，暂定卡片内展开)

SettingsPage
  └─> (纯配置页，无跳转)
```

### 1.3 关键路由规则
- 页面跳转统一使用 `router.push()`（保留返回栈）或 `router.replaceUrl()`（替换当前页）
- 返回使用 `router.back()`
- 底部导航 Tab 切换使用 `router.replaceUrl()` 确保不重复堆栈
- TimerPage 在会话结束后必须清理状态并返回 Index

## 2. UI 状态绑定（核心 @State/@Observed）
- TaskStore
  - tasks: Task[]
  - loading/error: boolean|string|null
- FocusStore
  - currentSession: FocusSession|null
  - currentSegment: FocusSegment|null
  - currentTaskId: number|null
  - isBreaking: boolean
  - breakStartAt: number|null
  - breakElapsedTime: number
  - elapsedTime: number // 当前专注段已过毫秒
  - timeLimitMs?: number|null // 倒计时上限（需求2.8）
  - sessionType?: 'FOCUS' | 'COUNTDOWN' | 'POMODORO'
  - restIntervalMs?: number|null // 需求3.3
  - restDurationMs?: number|null // 需求3.3
  - returnReminderId?: number
  - breakReminderId?: number
  - interruptionReason?: string // 需求7.1

UI 只读 Store 状态；所有变更经 action 触发（UI 不直接触 DB/Service）。

## 3. 关键交互流程（与 Store action 对应，便于实现）
- 创建/编辑/删除任务：TaskEditPage 调用 TaskStore.create/update/delete；成功后 router.back，失败 toast。
- 启动专注
  - 来源：任务卡按钮（taskId）或“快速专注”无任务。
  - 调用 FocusStore.startFocus(taskId?, options?: { timeLimitMs, sessionType, restIntervalMs, restDurationMs }).
  - 成功后跳转 FocusPage；展示任务标题/匿名标识，显示计时或倒计时模式；底部按钮根据 sessionType 切换文案（如“结束倒计时”）。
- 暂停专注：FocusPage → FocusStore.pauseFocus(reason?); UI 切“已暂停”状态，按钮变“继续/结束”，可输入干扰原因。
- 继续专注：FocusPage → FocusStore.resumeFocus(); 新建专注段，计时重启，清理暂停提醒。
- 结束专注：FocusPage → FocusStore.finishFocus(reason?); 汇总时长后返回首页，toast 提示。
- 倒计时结束（2.9）：Timer tick 检测 <=0 → 自动 finishFocus(reason='timeout')；UI 弹“时间到”。
- 强制结束倒计时（2.10）：按钮“结束倒计时”→ finishFocus(reason='force_stop_limit')。
- 新一轮倒计时（2.11）：结束后保留任务上下文 → startFocus(taskId, { timeLimitMs })。
- 延长倒计时（2.12 Could）：按钮“延长5分钟”→ FocusStore.extendTimeLimit(+5min)；UI 立即刷新剩余。
- 临时休息（3.1）：FocusPage“休息”→ startBreak(durationMs, reason?); UI 切到 BreakTimer。
- 提前结束休息（3.2）：“结束休息”→ finishBreak(); 返回专注。
- 配置循环休息（3.3/3.4）：SettingsPage 设置 restInterval/restDuration；FocusStore 计时达到 interval 时弹窗提示（按钮：开始休息 / 跳过一次）。
- 休息结束提示（3.5）：Reminder 回调或计时到期 → finishBreak() 自动恢复。
- 休息跳过（3.6）：休息开始提示弹窗含“跳过”→ 直接回到专注，不记录 break_event。
- 休息延长5分钟（3.7）：BreakTimer 按钮“再休息5分钟”→ 延长当前休息 plannedDuration；UI 更新进度。
- 前后台行为（4.x）
  - 切后台：AppLifecycleService 通知 → FocusStore.handleBackground(); UI toast/通知“已暂停，返回继续”。
  - 回前台：弹窗“继续/结束”；继续 resumeFocus，结束 finishFocus。
  - 关闭/被杀：首页 aboutToAppear 检查 RUNNING 会话，标记为暂停并提示恢复。
- 系统专注模式教学（5.x）：GuidePage 文案 + 跳转设置；无数据改动。
- 专注环境建议（6.1）：在 FocusPage/GuidePage 入口展示建议卡片。
- 干扰原因记录（7.x）：暂停/休息结束弹出输入框；FocusStore.setInterruptionReason(reason) 落盘；历史页可展示。

## 4. 组件职责对照（更细粒度，便于编写 props/events）
- BottomNav：三 Tab 切换；props：currentTab，onChange(tab).
- TaskItem：展示任务/累计时长；props：task，onStart(taskId)，onDelete(taskId)，onClickEdit(taskId)；不触 DB。
- FocusTimer：显示专注计时/倒计时、段序号、任务标题；props：session, elapsedTime, timeLimitMs, sessionType; events：onPause(), onFinish(), onBreak(), onExtendTime(), onForceFinish(); 按钮显隐根据 sessionType/isBreaking。
- BreakTimer：显示休息倒计时/进度；props：plannedDuration, elapsed, isSkipped; events：onFinishBreak(), onExtendBreak(), onSkipBreak().
- StatCard：展示完成数量/总时长/休息次数等；props：stats.

## 5. UI 数据需求与字段映射
- 列表：Task.title / description / totalFocusTime / completedAt / isAnonymous。
- 专注页：session.status、elapsedTime、timeLimitMs、sessionType、restIntervalMs、restDurationMs、breakCount、actualFocusDuration、totalDuration、interruptionReason。
- 休息：current break 剩余时间、plannedDuration、isSkipped、reason。
- 历史：每任务的总专注时长、完成时间、专注段数、休息次数、倒计时标记（sessionType=COUNTDOWN）、打断原因列表。
- 干扰：interruptionReason（session 或 break.reason）展示于历史/详情。

## 6. 设计要点与限制提示
- 计时精准度：仅前台保障；后台不承诺秒级精度，UI 文案需提示“后台将自动暂停”。
- 提醒：依赖系统 ReminderAgent；初次进入专注页若未授予权限显示 Banner + 去设置按钮。
- 倒计时与正计时：UI 需区分模式；倒计时归零自动结束，正计时需手动结束；延长/强制结束仅对 COUNTDOWN 生效。
- 外键/级联：删除任务时 UI 要确认，提示会级联删除关联会话与休息记录。
- 无任务计时：自动创建匿名任务并在历史页展示；历史显示“匿名专注”。
- 可恢复性：首页首屏检查“未完成会话”并弹窗恢复；恢复后进入 FocusPage。
- 任务按天归类（Could）：列表可按任务的最新会话日期分组（UI 层分组渲染，无需新字段）。

## 7. 错误与空态
- 列表空态：插画+文案；按钮“新建任务”“快速专注”。
- 权限未授予：专注页/设置页显示 Banner，按钮跳转系统权限设置。
- 数据加载失败：Toast + 重试按钮；列表显示轻量错误提示。
- 提醒创建失败：Toast 提示，仍可前台计时；后台提醒不可用需告知。

## 8. 性能与可用性
- 计时器仅局部刷新 FocusTimer/BreakTimer，避免整页重绘。
- 大列表使用 List + ForEach key；必要时分页或懒加载。
- 按钮可点击区 ≥ 44x44；休息/结束操作二次确认（AlertDialog）。
- 页面 aboutToDisappear 清理计时器监听；进入后台已由 Store 处理。

## 9. UI 与 Store 动作对照表
- Index：loadTasks(), startFocus(taskId?), deleteTask(), goto History/Settings/Guide, recoverSession()
- FocusPage：startFocus/resume/pause/finish, startBreak/finishBreak, extendTimeLimit, forceFinishCountdown, setInterruptionReason
- BreakTimer：finishBreak, extendBreak(+5min), skipBreak
- SettingsPage：update default timeLimit, restInterval, restDuration, notification toggle
- HistoryPage：loadCompleted(), refresh stats

## 10. 验收检查清单（前端）
- Must：任务 CRUD；专注计时；暂停/继续；无任务计时；后台自动暂停；休息会话；休息结束通知；系统专注教学。
- Should：倒计时模式；延长/强制结束倒计时；跳过休息；延长休息；干扰原因输入；提示/激励数据。
- Could：任务按天归类的分组渲染；番茄模式视图；统计趋势图占位。

---

## 11. UI 设计规范详细说明

### 11.1 完整UI规范文档
**文档位置**：[UI_DESIGN_SPECIFICATION.md](./UI_DESIGN_SPECIFICATION.md)

该文档包含以下详细内容：
1. **交互逻辑梳理**（§ 1）
   - 1.1 任务管理流程：初始状态、创建任务、任务列表交互
   - 1.2 专注计时流程：准备阶段、进行阶段、休息模式、底部详情抽屉
   - 1.3 历史记录与统计：筛选机制、图表展示
   - 1.4 设置：通知管理、时间参数

2. **颜色规范**（§ 2）
   - 主色调：皇家蓝 `#2F54EB`
   - 辅助色：浅灰 `#F5F7FA`、纯白、薄荷绿、渐变紫
   - 文本颜色：深黑 `#1F1F1F`、中灰 `#8C8C8C`
   - 语义化颜色：成功/错误/警告/信息
   - 对比度要求：≥ 4.5:1（正文）、≥ 3:1（标题）

3. **形状与组件**（§ 3）
   - 圆角规范：卡片 12-16px、按钮 28px、计时器正圆
   - 阴影规范：轻阴影、中阴影、重阴影
   - 组件尺寸规范：详细表格

4. **布局与定位**（§ 4）
   - 底部导航：60dp 高度、3图标均匀分布
   - 卡片布局：任务卡片、统计卡片
   - 空状态：居中布局
   - 计时器页面：中心化布局、单手可达性
   - 弹窗与遮罩：底部抽屉、对话框

5. **字体排印**（§ 5）
   - 字体家族：HarmonyOS Sans（优先）
   - 字体层级：Display(60sp)、H1(24sp)、Body(16sp/14sp)、Caption(12sp)
   - 排版细节：行高1.5x、对齐方式、文本截断

6. **动画与过渡**（§ 6）
   - 页面转场：Slide（300ms, ease-out）
   - 组件动画：Ripple、FAB展开
   - 进度动画：圆环进度、计时器数字
   - 加载状态：骨架屏、加载指示器

7. **响应式适配**（§ 7）
   - 屏幕尺寸断点：Small < 360dp、Medium 360-600dp、Large 600-840dp
   - 字体缩放、计时器圆形适配
   - 安全区域：顶部/底部/左右预留
   - 横屏适配：左右布局

8. **可访问性**（§ 9）
   - 颜色对比度要求
   - 触控目标最小尺寸 48dp × 48dp
   - 屏幕阅读器支持

### 11.2 关键设计元素速查

#### 主要颜色
| 名称 | HEX | 用途 |
|------|-----|------|
| 皇家蓝 | `#2F54EB` | 主按钮、选中状态、FAB |
| 浅灰背景 | `#F5F7FA` | App整体背景 |
| 薄荷绿 | `#389E0D`（图标） | 播放按钮 |
| 渐变紫 | `#B37FEB` → `#531DAB` | 倒计时进度环 |
| 橙色 | `#FA8C16` | 休息模式 |
| 深黑 | `#1F1F1F` | 标题、主要文本 |
| 中灰 | `#8C8C8C` | 次要文本 |

#### 关键尺寸
| 组件 | 尺寸 |
|------|------|
| 计时器圆形 | 280dp（Medium屏幕） |
| 主要按钮高度 | 56dp |
| 底部导航高度 | 60dp |
| FAB直径 | 56dp |
| 卡片圆角 | 12-16px |
| 按钮圆角 | 28px（全圆角） |

#### 字体层级
| 层级 | 字号 | 字重 | 用途 |
|------|------|------|------|
| Display | 60sp | Medium (500) | 计时器数字 |
| H1 | 24sp | Bold (700) | 页面标题 |
| H2 | 20sp | Bold (700) | 卡片标题 |
| Body 1 | 16sp | Regular (400) | 主要正文 |
| Body 2 | 14sp | Regular (400) | 次要正文 |
| Caption | 12sp | Light (300) | 辅助信息 |

### 11.3 实现建议

#### 颜色常量定义（common/theme.ets）
```typescript
export const Theme = {
  // Primary Colors
  COLOR_PRIMARY: '#2F54EB',          // 皇家蓝
  COLOR_PRIMARY_LIGHT: '#597EF7',    // 浅蓝
  COLOR_PRIMARY_DARK: '#1D39C4',     // 深蓝
  
  // Background Colors
  COLOR_BG_LIGHT: '#F5F7FA',         // 浅灰背景
  COLOR_BG_WHITE: '#FFFFFF',         // 纯白
  
  // Accent Colors
  COLOR_SUCCESS: '#52C41A',          // 成功绿
  COLOR_MINT: '#389E0D',             // 薄荷绿
  COLOR_ORANGE: '#FA8C16',           // 橙色（休息）
  COLOR_ERROR: '#F5222D',            // 错误红
  
  // Text Colors
  COLOR_TEXT_PRIMARY: '#1F1F1F',     // 深黑
  COLOR_TEXT_SECONDARY: '#8C8C8C',   // 中灰
  COLOR_TEXT_DISABLED: '#BFBFBF',    // 浅灰
  
  // Gradients
  GRADIENT_PURPLE: ['#B37FEB', '#531DAB'],
  GRADIENT_ORANGE: ['#FFD591', '#FA8C16'],
  
  // Border Radius
  RADIUS_SMALL: 8,
  RADIUS_MEDIUM: 12,
  RADIUS_LARGE: 16,
  RADIUS_FULL: 28,
  
  // Spacing
  SPACE_XSMALL: 4,
  SPACE_SMALL: 8,
  SPACE_MEDIUM: 12,
  SPACE_LARGE: 16,
  SPACE_XLARGE: 24,
  
  // Font Sizes
  FONT_SIZE_DISPLAY: 60,
  FONT_SIZE_H1: 24,
  FONT_SIZE_H2: 20,
  FONT_SIZE_BODY1: 16,
  FONT_SIZE_BODY2: 14,
  FONT_SIZE_CAPTION: 12,
  
  // Shadows
  SHADOW_LIGHT: { radius: 8, color: '#0000000d', offsetX: 0, offsetY: 2 },
  SHADOW_MEDIUM: { radius: 12, color: '#2F54EB33', offsetX: 0, offsetY: 4 },
  SHADOW_HEAVY: { radius: 24, color: '#00000026', offsetX: 0, offsetY: 8 }
}
```

#### 组件示例（参考 StartPage.ets）
StartPage 已实现完整的 UI 规范：
- 大圆形占位符（280dp，淡紫色 #E0E0F5）
- 倒计时模式切换（Toggle + 时长选择器）
- 蓝色主按钮（#3B66F5，全圆角 28px）
- 统计卡片（白色背景，阴影效果）
- 响应式布局（安全区域、间距规范）

#### 计时器页面（参考 FocusPage.ets）
FocusPage/TimerPage 已实现：
- 实时进度圆环（Progress component，蓝色/紫色渐变）
- 动态按钮显示（根据 SessionStatus 切换）
- 渐变背景（专注模式：蓝→黑；休息模式：橙→黑）
- 干扰原因对话框（底部居中，遮罩层）

### 11.4 设计与代码对应关系

| UI组件 | 代码文件 | 关键实现 |
|--------|----------|----------|
| 首页任务列表 | Index.ets | TaskItem component，BottomNav，FAB |
| 启动配置页 | StartPage.ets | Toggle，时长选择器，统计卡片 |
| 运行计时页 | FocusPage.ets (TimerPage) | Progress ring，动态按钮，渐变背景 |
| 任务编辑页 | TaskEditPage.ets | TextInput，表单验证 |
| 历史页 | HistoryPage.ets | 日期分组，筛选器，统计图表 |
| 设置页 | SettingsPage.ets | Toggle，数字输入框 |

---

## 12. 参考资源

- **Figma设计稿**：[Focus App Design](https://www.figma.com/make/jEnyNbwbbfW22y9kEwjNWP/Focus-App)
- **UI设计规范**：[UI_DESIGN_SPECIFICATION.md](./UI_DESIGN_SPECIFICATION.md)
- **架构设计**：[ARCHITECTURE.md](./ARCHITECTURE.md)
- **后端设计**：[BACKEND_DESIGN.md](./BACKEND_DESIGN.md)
- **页面流程**：[PAGE_FLOW_UPDATED.md](./PAGE_FLOW_UPDATED.md)
