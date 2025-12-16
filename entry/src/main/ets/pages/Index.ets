/**
 * 首页 - 任务列表（基于 Figma Design）
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore, TaskState } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { Task } from '../model/Task'
import { TaskItem } from '../components/TaskItem'
import { BottomNav } from '../components/BottomNav'
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
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部标题
        Row() {
          Text('Focus')
            .fontSize(Theme.FONT_SIZE_TITLE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .width('100%')
        .padding(Theme.SPACE_MEDIUM)

        // 任务列表或空状态
        if (this.taskState.loading) {
          Column() {
            Text('加载中...')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.taskState.tasks.length === 0) {
          // 空状态
          Column() {
            Text('No tasks yet. Add your first task to get started!')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
              .textAlign(TextAlign.Center)
              .width('80%')
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 任务列表
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
          .padding({ 
            left: Theme.SPACE_MEDIUM, 
            right: Theme.SPACE_MEDIUM, 
            top: Theme.SPACE_SMALL,
            bottom: Theme.SPACE_MEDIUM 
          })
        }

        // 底部导航栏
        BottomNav({ currentIndex: 0 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.COLOR_BACKGROUND)

      // 浮动添加按钮
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(32)
          .fontColor(Color.White)
      }
      .width(56)
      .height(56)
      .backgroundColor(Theme.COLOR_PRIMARY)
      .margin({ right: Theme.SPACE_MEDIUM, bottom: 80 })
      .onClick(() => {
        router.pushUrl({ url: 'pages/TaskEditPage' })
      })
    }
    .width('100%')
    .height('100%')
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
