/**
 * 首页 - 任务列表
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore, TaskState } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { Task } from '../model/Task'
import { TaskItem } from '../components/TaskItem'
import { Theme } from '../common/theme'
import { Logger } from '../common/logger'

@Entry
@Component
struct Index {
  @State taskState: TaskState = TaskStore.getState()
  @State showRecoverDialog: boolean = false
  @State recoveredTaskTitle: string = ''

  async aboutToAppear() {
    // 初始化 Store
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))

    // 检查未完成的会话
    const recoverResult = await FocusStore.checkAndRecoverSession()
    if (recoverResult.ok && recoverResult.data !== null && recoverResult.data !== undefined) {
      const session = recoverResult.data
      // 查找任务标题
      if (session.taskId) {
        const tasks = TaskStore.getState().tasks
        const task = tasks.find(t => t.id === session.taskId)
        this.recoveredTaskTitle = task?.title ?? '匿名专注'
      } else {
        this.recoveredTaskTitle = '匿名专注'
      }
      this.showRecoverDialog = true
    }

    // 加载任务列表
    await TaskStore.loadTasks()
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('Focus 专注')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Blank()

        Button('引导')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(32)
          .onClick(() => {
            router.pushUrl({ url: 'pages/GuidePage' })
          })

        Button('历史')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(32)
          .margin({ left: Theme.SPACE_SMALL })
          .onClick(() => {
            router.pushUrl({ url: 'pages/HistoryPage' })
          })
      }
      .width('100%')
      .padding(Theme.SPACE_MEDIUM)

      // 快速开始按钮
      Button('快速开始专注（无任务）')
        .width('90%')
        .height(50)
        .fontSize(Theme.FONT_SIZE_MEDIUM)
        .backgroundColor(Theme.COLOR_SUCCESS)
        .margin({ top: Theme.SPACE_MEDIUM })
        .onClick(() => {
          this.startFocusWithoutTask()
        })

      // 新建任务按钮
      Button('+ 新建任务')
        .width('90%')
        .height(50)
        .fontSize(Theme.FONT_SIZE_MEDIUM)
        .backgroundColor(Theme.COLOR_PRIMARY)
        .margin({ top: Theme.SPACE_MEDIUM })
        .onClick(() => {
          router.pushUrl({ url: 'pages/TaskEditPage' })
        })

      // 任务列表
      if (this.taskState.loading) {
        Text('加载中...')
          .margin({ top: Theme.SPACE_LARGE })
      } else if (this.taskState.tasks.length === 0) {
        Text('暂无任务，点击上方按钮新建')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .margin({ top: Theme.SPACE_LARGE })
      } else {
        List({ space: Theme.SPACE_MEDIUM }) {
          ForEach(this.taskState.tasks, (task: Task) => {
            ListItem() {
              TaskItem({
                task: task,
                onStart: (t: Task) => {
                  this.startFocusWithTask(t)
                },
                onDelete: (t: Task) => {
                  this.deleteTask(t)
                }
              })
            }
          }, (task: Task) => task.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM, top: Theme.SPACE_MEDIUM })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  // 无任务开始专注
  private async startFocusWithoutTask() {
    const result = await FocusStore.startFocus()
    if (result.ok) {
      router.pushUrl({ url: 'pages/FocusPage' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 有任务开始专注
  private async startFocusWithTask(task: Task) {
    const result = await FocusStore.startFocus(task.id)
    if (result.ok) {
      router.pushUrl({ url: 'pages/FocusPage' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 删除任务
  private async deleteTask(task: Task) {
    const result = await TaskStore.deleteTask(task.id)
    if (result.ok) {
      promptAction.showToast({ message: '任务已删除' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }
}
