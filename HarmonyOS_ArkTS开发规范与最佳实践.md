# HarmonyOS ArkTS 开发规范与最佳实践

本文档面向所有 **HarmonyOS ArkTS（Stage 模型）应用开发者**，提供完整的编码规范、项目结构、模块使用和最佳实践指导。  
适用于任何新建或现有的 ArkTS 项目，尤其推荐用于中大型、可长期维护的应用。

---

## 目录

1. 项目结构规范
2. 模块导入规范
3. 类型定义规范
4. 组件开发规范
5. UI 布局与样式规范
6. 代码格式化规范
7. 异步编程规范
8. 资源管理规范
9. 错误处理规范
10. 性能优化指南
11. 安全开发规范
12. 测试规范

---

## 0. 总则（默认规则）

- 统一遵循：**ArkTS Coding Style Guide + DevEco Studio Code Linter**（作为最终裁判）
- 规则优先级：
    1. 可读性与一致性
    2. 可维护性与可测试性
    3. 性能与安全
- 禁止“魔改式”全局状态
    - 跨页面数据必须 **可追踪 / 可落盘 / 可回放**
- 分层原则：
    - **UI 只做 UI**
    - **业务逻辑下沉到 Store / Service**
    - **持久化落到 Data（Repo）**

---

## 1. 项目结构规范

### 1.1 Stage 模型推荐目录结构

```text
AppScope/
  └─ app.json5

entry/
  └─ src/main/
     ├─ module.json5
     └─ ets/
        ├─ entryability/     # 入口 UIAbility
        ├─ pages/            # 页面
        ├─ components/       # 可复用组件
        ├─ common/           # 工具 / 常量 / 主题
        ├─ model/            # 实体 / DTO / enum
        ├─ store/            # 状态管理
        ├─ services/         # 系统能力封装
        └─ data/             # Repo / DAO / RDB
```
### 1.2 分层职责（强烈推荐）
pages

页面结构、导航、UI 组合

❌ 不写 DB / 重计算

components

纯 UI + 轻交互

❌ 不直接访问 DB

store

状态容器

仅暴露 actions / selectors

services

系统能力与外部依赖封装

data

RDB 持久化实现（Repo / DAO）

### 1.3 命名约定（全项目统一）
Page：FocusSessionPage.ets

Component：FocusTimerCard.ets

Service：ReminderService.ets

Store：focusStore.ets

Model：Task.ets / FocusSession.ets

## 2. 模块导入规范
### 2.1 导入顺序
系统 / 平台包（@ohos.*）

第三方包

项目内模块（common / model / services / store / data）

同目录相对路径

### 2.2 禁止事项
循环依赖

隐式跨层引用（pages 直接 import RDB 实现）

大范围 barrel export 导致依赖不透明

### 2.3 推荐实践
使用路径别名：@/common/logger

对外只暴露门面 API

调用链固定：

powershell
复制代码
UI → Store → Service → Data
## 3. 类型定义规范
### 3.1 基本原则
所有业务对象必须强类型

跨模块数据必须定义 DTO

禁止 any（仅允许在边界层短暂出现）

### 3.2 类型选择建议
enum：状态 / 来源 / 原因

interface：DTO / 展示数据

class：含业务规则与不变量

### 3.3 示例（Focus App）
ts
复制代码
export enum SessionStatus {
  Running = 'RUNNING',
  Paused = 'PAUSED',
  Finished = 'FINISHED'
}

export interface Task {
  id: number
  title: string
  createdAt: number
  completedAt?: number
  isAnonymous: boolean
}

export interface FocusSegment {
  id: number
  sessionId: number
  taskId?: number
  startAt: number
  endAt?: number
  durationMs?: number
}
## 4. 组件开发规范
### 4.1 组件职责
只做一件事：展示 + 交互回调

业务逻辑下沉到 Store / Service

输入通过 props，输出通过回调

### 4.2 状态装饰器使用
@State：组件私有 UI 状态

@Prop：父传子只读

@Link：双向联动（慎用）

@Observed + @ObjectLink：对象级响应式

### 4.3 组件粒度
页面建议拆分为 3–7 个组件

列表项必须“纯渲染”

### 4.4 禁止事项
build() 中重计算 / DB / 网络

组件内直接 new RDB

计时器刷新整页

## 5. UI 布局与样式规范
### 5.1 布局策略
Row / Column / Flex + LayoutWeight

大列表使用 List + 懒加载

避免嵌套滚动

### 5.2 样式统一
颜色 / 字体 / 间距集中在 common/theme

文案统一使用资源文件

响应式使用断点判断

### 5.3 可用性细节
点击区域 ≥ 44×44

避免系统手势冲突

明确告知后台行为（如暂停计时）

## 6. 代码格式化规范
### 6.1 强制工具
DevEco Studio Code Linter

规则域：

stylistic

correctness

performance

security

typescript-eslint

### 6.2 统一风格
缩进 / 引号 / 分号统一

import 排序固定

行宽建议 100–120

### 6.3 PR 规范
Linter 不通过禁止合入

必须说明：变更内容 / 自测 / 影响面

timer / lifecycle / db 修改需回归用例

## 7. 异步编程规范
### 7.1 原则
UI 线程只做 UI

IO / DB / 重计算必须异步

async 必须有 loading / 超时 / 重试

### 7.2 推荐技术
async / await

TaskPool

Worker（慎用）

### 7.3 禁止事项
build() 内 await

递归 setTimeout 模拟精准计时

未处理 Promise rejection

## 8. 资源管理规范
### 8.1 资源分类
resources/：strings / colors / media

rawfile/：模板 / 默认配置

### 8.2 使用原则
UI 文案必须资源化

控制图片体积

避免重复资源

### 8.3 生命周期
页面销毁释放监听

单例提供 reset / close

## 9. 错误处理规范
### 9.1 三层错误策略
UI：提示 + 可恢复

Service：错误分类 + error code

Store：失败不污染状态

### 9.2 必做清单
关键入口 try/catch

统一错误日志

DB 操作返回 Result

### 9.3 Result 模式
ts
复制代码
export type Result<T> =
  | { ok: true; data: T }
  | { ok: false; code: string; message: string }

export function fail(code: string, message: string): Result<never> {
  return { ok: false, code, message }
}
## 10. 性能优化指南
### 10.1 UI 性能
列表项纯渲染

减少无意义状态变更

图片懒加载

计时器局部刷新

### 10.2 启动性能
冷启动最小化

DB 延迟初始化

统计后台执行

### 10.3 数据性能
避免 SELECT *

建索引

使用 daily_stats 缓存

## 11. 安全开发规范
### 11.1 权限最小化
只申请必需权限

权限拒绝可降级

### 11.2 数据安全
最小化本地存储

提供删除入口

日志不打印敏感信息

### 11.3 跳转安全
仅白名单跳转

校验外部 URL

## 12. 测试规范
### 12.1 测试分层
Unit Test：store / service

Integration Test：DB + service

UI Test：完整流程

### 12.2 必测用例（Focus App）
任务 CRUD

专注开始 / 暂停 / 恢复 / 结束

后台暂停与恢复

提醒触发（前后台）

统计聚合正确性

### 12.3 回归策略
timer / lifecycle / reminder / db 改动必须全量回归

性能回归：列表 / 统计页 / 冷启动

附录：参考资料
ArkTS Coding Style Guide（官方）

DevEco Code Linter & hw-stylistic

TaskPool / 并发任务

Background Tasks Kit / ReminderAgent

RDB Store API

Stage 模型工程结构