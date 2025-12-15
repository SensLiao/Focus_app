# Focus 专注 App - 常见问题与解决方案

## 🐛 常见编译错误

### 1. 找不到模块错误

**错误示例**：
```
Cannot find module '../model/Result' or its corresponding type declarations
```

**原因**：文件路径大小写或文件不存在

**解决方案**：
1. 检查文件是否存在：`d:\Testing_App\entry\src\main\ets\model\Result.ets`
2. 检查导入路径是否正确（大小写敏感）
3. 重启 DevEco Studio 并重新同步项目

---

### 2. Context 类型错误

**错误示例**：
```
Type 'Context' is not assignable to type 'Context'
```

**解决方案**：
```typescript
// 使用 getContext(this) 获取上下文
import common from '@ohos.app.ability.common'

const context = getContext(this) as common.UIAbilityContext
```

---

### 3. @Observed 装饰器错误

**错误示例**：
```
Decorator '@Observed' is not valid here
```

**解决方案**：
```typescript
// @Observed 只能用于 class，不能用于 interface
@Observed
export class TaskState {
  tasks: Task[] = []
  // ...
}
```

---

### 4. 权限未声明

**错误示例**：
```
Permission denied: ohos.permission.PUBLISH_AGENT_REMINDER
```

**解决方案**：
1. 检查 `entry/src/main/module.json5`
2. 确保 `requestPermissions` 包含：
```json5
"requestPermissions": [
  {
    "name": "ohos.permission.PUBLISH_AGENT_REMINDER"
  }
]
```

---

## ⚙️ 运行时问题

### 1. 数据库初始化失败

**症状**：应用启动后崩溃或无法加载任务

**排查步骤**：
```bash
# 查看日志
hdc shell hilog | grep FocusApp

# 查找错误关键词
# - "Failed to get RDB Store"
# - "Failed to init tables"
```

**解决方案**：
1. 卸载应用重新安装（清空数据库）
```bash
hdc uninstall com.example.testing_app
```
2. 检查 RdbClient.ets 中的表创建 SQL 语法

---

### 2. 外键约束违反

**症状**：删除任务后会话未级联删除

**排查步骤**：
```typescript
// 检查 RdbClient.ets
await store.executeSql('PRAGMA foreign_keys = ON;')
```

**解决方案**：
1. 确保每次连接后启用外键
2. 检查索引是否创建
3. 验证外键列数据类型一致

---

### 3. 计时器不更新

**症状**：专注页计时器停止刷新

**可能原因**：
1. TimerService 未启动
2. 组件状态未绑定

**解决方案**：
```typescript
// FocusPage.ets
@State focusState: FocusState = FocusStore.getState()

// 确保 State 装饰器正确绑定
// 计时器回调会触发重绘
TimerService.start((elapsedMs) => {
  FocusStore.state.elapsedTime = elapsedMs
})
```

---

### 4. 提醒不触发

**症状**：切后台后 5 分钟未收到提醒

**可能原因**：
1. 权限未授予
2. ReminderAgent 创建失败
3. 系统省电策略限制

**排查步骤**：
```bash
# 查看日志
hdc shell hilog | grep "Reminder"

# 检查权限状态
hdc shell bm dump -a | grep PUBLISH_AGENT_REMINDER
```

**解决方案**：
1. 手动授予权限：设置 → 应用管理 → Focus 专注 → 权限管理
2. 检查系统电池优化：允许后台活动
3. 使用真机测试（模拟器可能不稳定）

---

## 🎯 性能优化问题

### 1. 任务列表滚动卡顿

**症状**：任务列表滚动不流畅

**解决方案**：
```typescript
// Index.ets - 使用 LazyForEach
List({ space: Theme.SPACE_MEDIUM }) {
  ForEach(this.taskState.tasks, (task: Task) => {
    ListItem() {
      TaskItem({ task: task })
    }
  }, (task: Task) => task.id.toString())  // 关键：提供 key
}
```

---

### 2. 专注页切换卡顿

**症状**：跳转到 FocusPage 有延迟

**原因**：首次渲染计算量大

**解决方案**：
1. 减少初始渲染组件数量
2. 使用占位符（Loading）过渡
3. 预加载数据

---

### 3. 内存占用过高

**症状**：应用长时间运行后内存增长

**排查**：
1. 检查计时器是否正确停止
2. 检查监听器是否注销

**解决方案**：
```typescript
// 页面销毁时清理
aboutToDisappear() {
  TimerService.stop()
  AppLifecycleService.unregister(this.listener)
}
```

---

## 📱 设备兼容问题

### 1. 不同屏幕尺寸适配

**问题**：在不同设备上布局错乱

**解决方案**：
```typescript
// 使用百分比和 layoutWeight
Button('开始')
  .width('80%')  // 相对宽度
  .layoutWeight(1)  // 弹性布局
```

---

### 2. 深色模式支持

**问题**：深色模式下文字看不清

**解决方案**：
```typescript
// theme.ets - 添加深色模式配置
static readonly COLOR_TEXT_PRIMARY_DARK = '#ffffff'
static readonly COLOR_BACKGROUND_DARK = '#121212'

// 根据系统主题切换
const isDark = ConfigurationConstant.ColorMode.COLOR_MODE_DARK
```

---

## 🔐 数据安全问题

### 1. 敏感数据泄露

**风险**：日志打印任务内容

**解决方案**：
```typescript
// logger.ets - 生产环境关闭调试日志
export class Logger {
  static debug(message: string, ...args: any[]): void {
    if (isDevelopment) {  // 只在开发环境打印
      hilog.debug(DOMAIN, TAG, message, ...args)
    }
  }
}
```

---

### 2. 数据库加密

**需求**：任务内容需要加密

**解决方案**（后续实现）：
```typescript
// RdbClient.ets
const config: relationalStore.StoreConfig = {
  name: Constants.DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S3,  // 最高安全级别
  encrypt: true  // 启用加密
}
```

---

## 🧪 测试相关问题

### 1. 单元测试环境搭建

**问题**：如何测试 Repo 层

**解决方案**：
```typescript
// entry/src/test/TaskRepo.test.ets
import { describe, it, expect } from '@ohos/hypium'
import { TaskRepo } from '../main/ets/data/TaskRepo'

describe('TaskRepo', () => {
  it('should create task', async () => {
    const result = await TaskRepo.create(context, {
      title: 'Test Task'
    })
    expect(result.ok).assertTrue()
  })
})
```

---

### 2. 模拟数据测试

**问题**：如何快速生成测试数据

**解决方案**：
```typescript
// 在 Index.ets aboutToAppear 中添加
if (isDevelopment) {
  await this.seedTestData()
}

private async seedTestData() {
  for (let i = 1; i <= 10; i++) {
    await TaskStore.createTask({
      title: `测试任务 ${i}`,
      description: `这是第 ${i} 个测试任务`
    })
  }
}
```

---

## 📊 日志分析技巧

### 查看完整流程日志

```bash
# 启动日志收集
hdc shell hilog -r && hdc shell hilog -b D

# 过滤 Focus App 日志
hdc shell hilog | grep "FocusApp"

# 保存到文件
hdc shell hilog | grep "FocusApp" > focus_logs.txt
```

### 关键日志点

| 操作 | 日志关键词 | 位置 |
|------|-----------|------|
| 数据库初始化 | "RDB Store initialized" | RdbClient |
| 任务加载 | "Loaded N tasks" | TaskRepo |
| 专注开始 | "Focus started" | FocusStore |
| 专注暂停 | "Focus paused" | FocusStore |
| 切后台 | "Handled background" | FocusStore |
| 提醒创建 | "Reminder created" | ReminderService |

---

## 🔄 版本升级问题

### 数据库迁移

**场景**：发布新版本后需要修改表结构

**解决方案**：
```typescript
// RdbClient.ets
static readonly DB_VERSION = 2  // 版本号 +1

private static async onUpgrade(store: RdbStore, oldVersion: number, newVersion: number) {
  if (oldVersion < 2) {
    // 添加新字段
    await store.executeSql('ALTER TABLE tasks ADD COLUMN priority INTEGER DEFAULT 0')
  }
}
```

---

## 🚀 性能优化建议

### 1. 启动优化
- [ ] RDB 延迟初始化（首次使用时连接）
- [ ] 任务列表分页加载
- [ ] 图片资源压缩

### 2. 运行时优化
- [ ] 计时器只刷新数字组件
- [ ] 列表使用虚拟滚动
- [ ] 避免频繁 DB 查询（使用缓存）

### 3. 内存优化
- [ ] 页面销毁释放监听器
- [ ] 大对象及时置空
- [ ] 避免循环引用

---

## 📞 获取帮助

### 官方文档
- [HarmonyOS 开发者文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V13/application-dev-guide-V13)
- [ArkTS API 参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V13/development-intro-V13)

### 社区支持
- [HarmonyOS 开发者论坛](https://developer.huawei.com/consumer/cn/forum/home?fid=0101303901010230000)
- [DevEco Studio 问题反馈](https://developer.huawei.com/consumer/cn/support/)

---

## 🛠️ 快速修复脚本

```bash
#!/bin/bash
# fix_common_issues.sh

# 1. 清理构建缓存
echo "清理构建缓存..."
rm -rf entry/build/
rm -rf .hvigor/

# 2. 重新同步依赖
echo "同步依赖..."
hvigorw clean

# 3. 卸载旧版本
echo "卸载旧版本..."
hdc uninstall com.example.testing_app

# 4. 重新编译
echo "重新编译..."
hvigorw assembleHap

# 5. 安装新版本
echo "安装新版本..."
hdc install entry/build/default/outputs/default/entry-default-signed.hap

echo "修复完成！"
```

---

**提示**：遇到问题时，优先查看日志并搜索关键错误信息。大多数问题都能通过日志定位根因。
