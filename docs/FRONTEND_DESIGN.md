# Frontend Design – Focus App

> 目标：让前端 UI 与现有 ArkTS 架构、Store/Service/Data 层契合，并满足需求文档（Must/Should/Could）。本设计文档强调“可实现度”与“代码对齐度”，便于后续 AI/人工快速落地。

## 1. 页面与导航（信息架构 + 路由）
- 首页 Index：任务列表、快速专注入口、底部导航（Home/History/Settings）；首屏执行“未完成会话恢复”提示。
- 专注页 FocusPage：全屏计时/倒计时、暂停/继续、休息、结束；前后台提示、倒计时到点自动结束、延长/强制结束；干扰原因输入弹窗。
- 休息视图：FocusPage 内部态切换到 BreakTimer（休息倒计时/进度，支持跳过/延长）。
- 任务编辑 TaskEditPage：创建/编辑任务（表单校验：标题必填 ≤ 60 字；描述可选）。
- 历史 HistoryPage：完成任务与会话统计（按日期或任务分组，展示休息次数/总时长/实际专注时长）。
- 引导 GuidePage：系统专注模式教学 + 跳转设置（按钮拉起系统设置）。
- 设置 SettingsPage：通知开关、默认专注时长、默认休息时长与间隔、是否自动延长休息、数据导出占位。
- 路由：main_pages.json 已配置；页面跳转统一使用 router.replaceUrl/push，返回使用 router.back。

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
