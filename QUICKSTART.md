# 🚀 Focus 专注 App - 快速启动检查清单

## 开始前检查（5 分钟）

### ✅ 环境准备
- [ ] 已安装 DevEco Studio 4.0+
- [ ] 已安装 HarmonyOS SDK API 10+
- [ ] 真机已连接 或 模拟器已启动
- [ ] USB 调试已开启

### ✅ 项目准备
- [ ] 项目已打开：`d:\Testing_App`
- [ ] 依赖同步完成（底部进度条消失）
- [ ] 无红色波浪线错误（警告可忽略）

---

## 首次运行（3 步骤）

### 1️⃣ 点击 Run 按钮
- 位置：DevEco Studio 顶部工具栏
- 快捷键：`Shift + F10`
- 等待编译（约 30-60 秒）

### 2️⃣ 授权权限
- 应用安装后自动弹出权限请求
- 点击 **"允许"** → `PUBLISH_AGENT_REMINDER`
- 权限用途：定时提醒功能

### 3️⃣ 开始演示
- 应用启动，显示首页
- 按照下方场景测试

---

## 📋 最小测试流程（5 分钟）

### 场景 1：快速专注（必测）
```
1. 点击「快速开始专注（无任务）」
2. 跳转到专注页，观察计时器运行
3. 等待 10 秒
4. 点击「暂停」→ 计时器停止
5. 点击「继续」→ 显示「第 2 段」
6. 点击「结束专注」→ 返回首页
```

**预期结果**：✅ 计时器正常运行，数据保存成功

---

### 场景 2：任务专注（必测）
```
1. 点击「+ 新建任务」
2. 输入标题：测试任务
3. 点击「创建任务」→ 返回首页
4. 任务列表显示刚创建的任务
5. 点击任务右侧「开始」按钮
6. 专注页显示任务标题
7. 专注 10 秒后点击「结束专注」
8. 返回首页，任务消失（已完成）
```

**预期结果**：✅ 任务创建、专注、完成流程正常

---

### 场景 3：历史查看（必测）
```
1. 完成场景 2
2. 点击首页右上角「历史」
3. 查看已完成任务列表
4. 查看统计数据（任务数、时长）
```

**预期结果**：✅ 历史数据正确展示

---

## 🐛 常见问题快速修复

### 问题 1：编译失败
```bash
# 清理缓存
rm -rf entry/build/
rm -rf .hvigor/

# 重新同步
DevEco Studio → File → Sync Project
```

---

### 问题 2：应用安装失败
```bash
# 卸载旧版本
hdc uninstall com.example.testing_app

# 重新安装
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

---

### 问题 3：页面跳转失败
```
检查：entry/src/main/resources/base/profile/main_pages.json

确保包含：
- pages/Index
- pages/FocusPage
- pages/TaskEditPage
- pages/GuidePage
- pages/HistoryPage
```

---

### 问题 4：计时器不动
```typescript
// 检查 FocusPage.ets

@State focusState: FocusState = FocusStore.getState()

// 确保 @State 装饰器存在
// 确保 TimerService.start() 被调用
```

---

### 问题 5：数据库错误
```bash
# 完全卸载应用（清空数据）
hdc uninstall com.example.testing_app

# 重新安装
点击 Run 按钮
```

---

## 📊 验证清单

### 基础功能（必验证）
- [ ] 应用启动无崩溃
- [ ] 首页任务列表显示
- [ ] 新建任务功能正常
- [ ] 快速专注功能正常
- [ ] 任务专注功能正常
- [ ] 暂停/继续功能正常
- [ ] 计时器实时更新
- [ ] 历史页数据展示

### 高级功能（可选验证）
- [ ] 休息功能（点击休息按钮）
- [ ] 切后台自动暂停（按 Home 键测试）
- [ ] 杀进程恢复（从最近任务强杀）
- [ ] 系统专注引导（点击引导按钮）
- [ ] 删除任务功能

---

## 🎯 演示准备

### 对外演示前（5 分钟准备）
```bash
1. 清空数据（卸载重装）
   hdc uninstall com.example.testing_app

2. 重新安装
   点击 Run 按钮

3. 预创建 2-3 个任务
   - 任务 1：写项目报告
   - 任务 2：学习 HarmonyOS
   - 任务 3：健身 30 分钟

4. 完成 1 个任务（生成历史数据）
   开始专注 → 等待 1 分钟 → 结束

5. 验证历史页有数据
```

---

## 📸 截图位置

### 关键页面截图（用于文档/演示）
1. **首页**：`pages/Index` - 任务列表 + 快速开始按钮
2. **专注页**：`pages/FocusPage` - 计时器 + 操作按钮
3. **历史页**：`pages/HistoryPage` - 统计卡片 + 已完成任务
4. **引导页**：`pages/GuidePage` - 使用说明
5. **任务编辑页**：`pages/TaskEditPage` - 表单输入

---

## 🔍 日志监控

### 启动日志监控（可选）
```bash
# 新开终端窗口
hdc shell hilog -r && hdc shell hilog -b D
hdc shell hilog | grep "FocusApp"

# 观察关键日志
- "RDB Store initialized"
- "TaskStore initialized"
- "FocusStore initialized"
- "Focus started"
- "Focus paused"
```

---

## ⏱️ 时间估算

| 步骤 | 时间 | 说明 |
|------|------|------|
| 环境检查 | 2 分钟 | 确认工具链和设备 |
| 项目启动 | 3 分钟 | 同步依赖 + 首次编译 |
| 基础测试 | 5 分钟 | 场景 1-3 快速验证 |
| 完整测试 | 15 分钟 | 所有功能验证 |
| **总计** | **25 分钟** | 从零到完整演示 |

---

## ✨ 成功标准

### ✅ MVP 可用性
- [x] 应用可正常安装启动
- [x] 核心流程（任务专注）可跑通
- [x] 数据持久化正常
- [x] 无阻塞性 Bug

### ✅ 演示就绪
- [x] 5 个页面可正常访问
- [x] 计时器实时刷新
- [x] 前后台切换正常
- [x] 历史数据可查看

---

## 🎓 新手提示

### 第一次接触 HarmonyOS？
1. 先阅读 [README.md](../README.md) 了解项目结构
2. 再看 [ARCHITECTURE.md](ARCHITECTURE.md) 理解设计思路
3. 遇到问题查 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
4. 运行项目，按场景测试

### 第一次使用 DevEco Studio？
- 界面类似 Android Studio / IntelliJ IDEA
- Run 按钮在顶部工具栏（绿色三角形）
- 日志窗口在底部 Hilog 标签
- 设备选择器在 Run 按钮左侧

---

## 📞 遇到问题？

### 优先级 1：查看日志
```bash
hdc shell hilog | grep "FocusApp" | grep "ERROR"
```

### 优先级 2：查看文档
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 常见问题
- [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - 文件清单

### 优先级 3：从头开始
```bash
# 完全清理
hdc uninstall com.example.testing_app
rm -rf entry/build/
rm -rf .hvigor/

# 重新开始
DevEco Studio → File → Sync Project
点击 Run 按钮
```

---

## 🎉 启动成功！

看到以下界面说明 MVP 可正常运行：

1. **首页**：显示「Focus 专注」标题 + 快速开始按钮 + 新建任务按钮
2. **专注页**：显示计时器（格式：MM:SS）+ 暂停/继续/休息/结束按钮
3. **历史页**：显示统计卡片 + 已完成任务列表

🚀 **开始探索吧！** 按照 [README.md](../README.md) 中的 7 个演示场景测试所有功能。

---

**祝您使用愉快！** 🎯

有问题随时查阅文档或查看代码注释。每个文件都有详细的功能说明。
