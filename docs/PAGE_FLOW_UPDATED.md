# Focus App 页面流程与状态管理更新文档

> 更新日期：2025-12-17  
> 目的：修正页面跳转逻辑和状态转换，明确StartPage和TimerPage的职责分离

---

## 1. 页面架构重新定义

### 1.1 页面清单与职责

| 页面名称 | 路径 | 核心职责 | 状态要求 |
|---------|------|---------|---------|
| **Index** | pages/Index | 任务列表、导航入口 | 无会话运行 |
| **StartPage** | pages/StartPage | 专注前配置（新增）| 无会话运行 |
| **FocusPage** | pages/FocusPage | 运行中计时器（运行时称TimerPage） | 会话运行中 |
| **TaskEditPage** | pages/TaskEditPage | 任务编辑表单 | - |
| **HistoryPage** | pages/HistoryPage | 历史统计查看 | - |
| **SettingsPage** | pages/SettingsPage | 应用设置 | - |
| **GuidePage** | pages/GuidePage | 新手引导 | - |

### 1.2 关键区别说明

#### StartPage（启动配置页）- 新增
- **何时出现**：用户点击"开始专注"之前
- **UI特征**：
  - 显示"Focus time"圆形占位符（0:00）
  - 倒计时模式开关
  - "Start Focus Session"主按钮（蓝色）
  - 统计卡片（历史数据展示）
  - **无暂停/继续按钮**
- **状态**：FocusStore 无活动会话（currentSession === null）
- **作用**：配置专注参数后启动新会话

#### FocusPage（运行计时页，运行时称TimerPage）
- **何时出现**：会话启动后（startFocus成功）
- **文件路径**：pages/FocusPage.ets
- **运行时概念名**：TimerPage（强调运行状态）
- **UI特征**：
  - 显示运行中的圆形进度环（实时更新）
  - 动态按钮：「暂停/继续」「休息」「结束专注」
  - 状态标签：「专注中」/「休息中」/「已暂停」
  - 实时计时器（更新每秒）
- **状态**：FocusStore 有活动会话（currentSession !== null, status=RUNNING/PAUSED/BREAKING）
- **作用**：显示运行状态、控制会话流程

---

## 2. 完整页面流程图（修正版）

```
┌─────────────────────────────────────────────────────────────┐
│                      App启动 / Index首屏                       │
│  检查未完成会话：FocusStore.checkAndRecoverSession()          │
└─────────────────────────────────────────────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
    有未完成会话              无未完成会话          底部Tab导航
         │                       │                       │
    ┌────▼────┐           ┌──────▼──────┐         ┌────▼────┐
    │恢复对话框│           │  Index首页   │         │ History │
    │继续/放弃│           │  任务列表    │         │ Settings│
    └────┬────┘           └──────┬──────┘         └─────────┘
         │                       │
    选择「继续」            用户操作：
         │               ┌───────┼───────┐
         │               │       │       │
         │           点击FAB  点击任务  编辑任务
         │               │    「开始」    │
         │               │       │       │
         └───────────────┼───────┘       │
                         │               │
                    ┌────▼────┐     ┌───▼────┐
                    │StartPage│     │TaskEdit│
                    │配置页面 │     │  Page  │
                    └────┬────┘     └───┬────┘
                         │               │
                  配置完成点击           │
                 「开始专注」         保存/取消
                         │               │
          FocusStore.startFocus()   router.back()
                         │               │
          router.replaceUrl()            │
                         │               │
                    ┌────▼────┐◄─────────┘
                    │TimerPage│
                    │运行计时 │
                    │  状态   │
                    └────┬────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
      点击「暂停」    点击「休息」   点击「结束」
          │              │              │
    FocusStore       FocusStore      FocusStore
    .pauseFocus()    .startBreak()   .finishFocus()
          │              │              │
    UI变「继续」   UI变休息模式    router.back()
          │              │              │
    点击「继续」    倒计时结束       ┌──▼──┐
          │              │            │Index│
    FocusStore     FocusStore        │首页 │
    .resumeFocus()  .finishBreak()   └─────┘
          │              │
    UI变运行中      UI变运行中
          │              │
          └──────────────┘
                 │
            继续计时循环
```

---

## 3. 关键状态转换表

### 3.1 FocusStore状态机

```
状态: NO_SESSION（无会话）
  ├─ 允许页面: Index, StartPage, History, Settings
  ├─ 禁止页面: TimerPage
  └─ 转换触发:
      └─ startFocus() → RUNNING

状态: RUNNING（运行中）
  ├─ 允许页面: TimerPage
  ├─ 禁止页面: StartPage（不能重复启动）
  └─ 转换触发:
      ├─ pauseFocus() → PAUSED
      ├─ startBreak() → BREAKING
      └─ finishFocus() → NO_SESSION

状态: PAUSED（已暂停）
  ├─ 允许页面: TimerPage
  ├─ UI显示: 「继续」按钮替代「暂停」
  └─ 转换触发:
      ├─ resumeFocus() → RUNNING
      └─ finishFocus() → NO_SESSION

状态: BREAKING（休息中）
  ├─ 允许页面: TimerPage
  ├─ UI显示: 圆环变休息色、显示休息倒计时
  └─ 转换触发:
      ├─ finishBreak() → RUNNING
      └─ skipBreak() → RUNNING
```

### 3.2 路由决策矩阵

| 用户操作 | 当前页面 | Store状态 | 目标页面 | Router方法 |
|---------|---------|----------|---------|-----------|
| 点击FAB(+) | Index | NO_SESSION | StartPage | push |
| 点击任务「开始」| Index | NO_SESSION | StartPage(taskId) | push |
| 「开始专注」| StartPage | NO_SESSION → RUNNING | TimerPage | replaceUrl |
| 恢复会话 | Index | PAUSED | TimerPage | push |
| 「结束专注」| TimerPage | RUNNING → NO_SESSION | Index | back |
| 「暂停」| TimerPage | RUNNING → PAUSED | TimerPage | 留在本页 |
| 「继续」| TimerPage | PAUSED → RUNNING | TimerPage | 留在本页 |
| 「休息」| TimerPage | RUNNING → BREAKING | TimerPage | 留在本页 |
| 底部Tab切换 | Index/History/Settings | NO_SESSION | 其他Tab | replaceUrl |

---

## 4. 代码实现指南

### 4.1 StartPage 核心逻辑（新建文件）

```typescript
// pages/StartPage.ets
@Entry
@Component
struct StartPage {
  @State taskId: number | null = null
  @State taskTitle: string = 'Anonymous'
  @State isCountdownMode: boolean = false
  @State countdownMinutes: number = 25
  
  async aboutToAppear() {
    // 从路由参数获取taskId
    const params = router.getParams() as { taskId?: number }
    if (params?.taskId) {
      this.taskId = params.taskId
      const task = TaskStore.findTask(this.taskId)
      if (task) {
        this.taskTitle = task.title
      }
    }
  }
  
  // 开始专注会话
  private async startFocus() {
    const options = {
      sessionType: this.isCountdownMode ? SessionType.COUNTDOWN : SessionType.FOCUS,
      timeLimitMs: this.isCountdownMode ? this.countdownMinutes * 60 * 1000 : null
    }
    
    const result = await FocusStore.startFocus(this.taskId, options)
    if (result.ok) {
      // 使用replaceUrl替换当前页面，防止返回到配置页
      router.replaceUrl({ url: 'pages/TimerPage' })
    } else {
      promptAction.showToast({ message: result.message ?? '启动失败' })
    }
  }
  
  build() {
    Column() {
      // Header: 返回按钮 + 标题
      // 大圆形（静态，显示0:00）
      // 倒计时模式Toggle
      // "Start Focus Session"按钮 → this.startFocus()
      // 统计卡片（历史数据）
    }
  }
}
```

### 4.2 TimerPage 状态检查（修改现有FocusPage.ets）

```typescript
// pages/TimerPage.ets (原FocusPage.ets)
@Entry
@Component
struct TimerPage {
  @State focusState: FocusState = FocusStore.getState()
  
  async aboutToAppear() {
    // 关键：检查是否有活动会话
    if (!this.focusState.currentSession) {
      // 如果没有会话，重定向回首页
      promptAction.showToast({ message: '无活动会话' })
      router.back()
      return
    }
    
    // 启动计时器订阅
    this.startTimer()
  }
  
  // 暂停
  private async onPause() {
    await FocusStore.pauseFocus()
    // 留在本页，UI自动更新为「继续」按钮
  }
  
  // 继续
  private async onResume() {
    await FocusStore.resumeFocus()
    // 留在本页，UI自动更新为「暂停」按钮
  }
  
  // 结束
  private async onFinish() {
    await FocusStore.finishFocus()
    router.back() // 返回Index
  }
  
  build() {
    Column() {
      // Header: 返回 + 状态标签
      // 大圆形（动态进度环）
      // 根据focusState.currentSession.status显示不同按钮
      if (this.focusState.currentSession?.status === SessionStatus.RUNNING) {
        Button('暂停').onClick(() => this.onPause())
        Button('休息').onClick(() => this.onBreak())
        Button('结束').onClick(() => this.onFinish())
      } else if (this.focusState.currentSession?.status === SessionStatus.PAUSED) {
        Button('继续').onClick(() => this.onResume())
        Button('结束').onClick(() => this.onFinish())
      } else if (this.focusState.isBreaking) {
        Button('结束休息').onClick(() => this.onFinishBreak())
      }
    }
  }
}
```

### 4.3 Index 启动逻辑（修改）

```typescript
// pages/Index.ets
@Entry
@Component
struct Index {
  // FAB点击
  private onFABClick() {
    // 不再直接启动会话，而是跳转到配置页
    router.push({ url: 'pages/StartPage' })
  }
  
  // 任务「开始」按钮
  private onTaskStart(taskId: number) {
    // 传递taskId到StartPage
    router.push({
      url: 'pages/StartPage',
      params: { taskId: taskId }
    })
  }
  
  // 恢复会话
  private onRecoverSession() {
    // 直接跳转到TimerPage（会话已存在）
    router.push({ url: 'pages/TimerPage' })
  }
}
```

---

## 5. 测试检查清单

### 5.1 页面跳转正确性
- [ ] Index → FAB → StartPage显示"Anonymous"和配置选项
- [ ] Index → 任务「开始」→ StartPage显示任务名称
- [ ] StartPage → 「开始专注」→ TimerPage显示运行计时器
- [ ] TimerPage → 「结束」→ Index（无会话）
- [ ] Index启动时检测到PAUSED会话 → 弹窗 → TimerPage

### 5.2 状态一致性
- [ ] StartPage显示时 FocusStore.currentSession === null
- [ ] TimerPage显示时 FocusStore.currentSession !== null
- [ ] 暂停后TimerPage按钮变为「继续」
- [ ] 休息时圆环颜色和文案变化
- [ ] 结束后TimerPage自动返回Index

### 5.3 边界情况
- [ ] StartPage点击「开始」时会话创建失败 → toast + 留在StartPage
- [ ] TimerPage加载时无会话 → toast + 返回Index
- [ ] 后台切换时暂停 → 回前台提示继续/结束
- [ ] 杀进程后重启 → Index显示恢复对话框- [ ] **活动任务识别**：task.activeSessionId !== null 显示咖啡图标，否则显示播放按钮
- [ ] **多任务防护**：同时只能有一个活动会话，启动新会话前检查并提示切换
---

## 6. 文件清单

### 需要新建的文件
- `entry/src/main/ets/pages/StartPage.ets`（启动配置页）

### 需要修改的文件
- `entry/src/main/ets/pages/Index.ets`（修改启动逻辑）
- `entry/src/main/ets/pages/FocusPage.ets`（重命名为TimerPage，添加状态检查）
- `docs/FRONTEND_DESIGN.md`（更新页面流程）
- `docs/ARCHITECTURE.md`（更新页面清单）

### 需要更新的配置
- `entry/src/main/resources/base/profile/main_pages.json`（添加StartPage路由）

---

## 7. 总结

### 问题根源
- 原设计混淆了"启动前配置"和"运行中计时"两个阶段
- FocusPage既承担配置又承担运行，导致状态转换混乱

### 解决方案
- **分离职责**：StartPage（配置）+ TimerPage（运行）
- **明确状态**：NO_SESSION只能在StartPage，有Session只能在TimerPage
- **单向流转**：StartPage → startFocus() → TimerPage → finishFocus() → Index
- **防御性检查**：TimerPage加载时检测无会话立即返回

### 收益
- 页面职责清晰，代码易维护
- 状态转换可预测，减少bug
- 用户体验符合直觉（配置→运行→结束）
