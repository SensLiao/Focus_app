
/**
 * 首页 - 任务列表（基于Figma Design + UI 现代化）
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore, TaskState } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { Task } from '../model/Task'
import { FocusSession, SessionType } from '../model/FocusSession'
import { TaskItem } from '../components/TaskItem'
import { BottomNav } from '../components/BottomNav'
import { Theme } from '../common/theme'
import { Logger } from '../common/logger'
import { SettingsService } from '../services/SettingsService'

@Entry
@Component
struct Index {
  @State taskState: TaskState = TaskStore.getState()
  @State showRecoverDialog: boolean = false
  @State recoveredSession: FocusSession | null = null
  @State recoveredTaskTitle: string = ''
  async aboutToAppear() {
    // 初始化服务
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))

    // 加载任务列表
    await TaskStore.loadTasks()
    this.taskState = TaskStore.getState()

    // 检查未完成的会话
    const recoverResult = await FocusStore.checkAndRecoverSession()
    if (recoverResult.ok && recoverResult.data !== null && recoverResult.data !== undefined) {
      this.recoveredSession = recoverResult.data
      // 查找任务标题
      if (this.recoveredSession && this.recoveredSession.taskId) {
        const task = TaskStore.findTask(this.recoveredSession.taskId)
        this.recoveredTaskTitle = task?.title ?? '匿名专注'
      } else {
        this.recoveredTaskTitle = '匿名专注'
      }
      this.showRecoverDialog = true
    }
  }
  // 页面每次显示时刷新任务列�?
  async onPageShow() {
    await TaskStore.loadTasks()
    this.taskState = TaskStore.getState()
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部标题区（渐变背景 - UI 现代化）
        Row() {
          Text('Focus')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(80)
        .padding({ left: Theme.SPACE_LARGE, top: Theme.SPACE_XLARGE, bottom: Theme.SPACE_LARGE })
        .linearGradient({
          angle: 135,
          colors: [
            [Theme.COLOR_PRIMARY_LIGHT, 0],
            [Theme.COLOR_PRIMARY, 1]
          ]
        })
        .shadow({
          radius: Theme.SHADOW_MEDIUM.radius,
          color: Theme.SHADOW_MEDIUM.color,
          offsetX: 0,
          offsetY: 4
        })
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
          Column({ space: Theme.SPACE_LARGE }) {
            Text('📝')
              .fontSize(64)
            Text('还没有任务?')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
            
            Text('点击下方按钮添加你的第一个任务，\n或直接开始快速专注')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
              .textAlign(TextAlign.Center)

            Button('开始快速专注')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .height(48)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .borderRadius(Theme.BORDER_RADIUS_LARGE)
              .onClick(() => {
                this.startFocusWithoutTask()
              })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding(Theme.SPACE_LARGE)
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
            top: Theme.SPACE_MEDIUM,
            bottom: Theme.SPACE_MEDIUM 
          })
        }
        // 底部导航栏
        BottomNav({ currentIndex: 0 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.COLOR_BACKGROUND)

      // 浮动按钮区
      Column({ space: Theme.SPACE_SMALL }) {
        // 快速专注按钮
        Button({ type: ButtonType.Circle }) {
          Text('+')  
            .fontSize(22)
            .fontColor(Color.White)
        }
        .width(48)
        .height(48)
        .backgroundColor(Theme.COLOR_SUCCESS)
        .shadow({
          radius: Theme.SHADOW_MEDIUM.radius,
          color: Theme.SHADOW_MEDIUM.color,
          offsetX: Theme.SHADOW_MEDIUM.offsetX,
          offsetY: Theme.SHADOW_MEDIUM.offsetY
        })
        .onClick(() => {
          this.startFocusWithoutTask()
        })

        // 添加任务按钮（渐变色）
        Button({ type: ButtonType.Circle }) {
          Text('+')
            .fontSize(36)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .width(64)
        .height(64)
        .linearGradient({
          angle: 135,
          colors: [
            [Theme.COLOR_PRIMARY_LIGHT, 0],
            [Theme.COLOR_PRIMARY, 1]
          ]
        })
        .shadow({
          radius: Theme.SHADOW_LARGE.radius,
          color: Theme.SHADOW_LARGE.color,
          offsetX: Theme.SHADOW_LARGE.offsetX,
          offsetY: Theme.SHADOW_LARGE.offsetY
        })
        .onClick(() => {
          router.pushUrl({ url: 'pages/TaskEditPage' })
        })
      }
      .margin({ right: Theme.SPACE_LARGE, bottom: 90 })
      // 会话恢复对话框
      if (this.showRecoverDialog) {
        this.RecoverDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
  // 会话恢复对话框组件
  @Builder
  RecoverDialog() {
    Column() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          // 点击遮罩不关闭，必须选择
        })

      // 对话框内容
      Column({ space: Theme.SPACE_LARGE }) {
        Text('发现未完成的专注')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Column({ space: Theme.SPACE_SMALL }) {
          Text(`任务：${this.recoveredTaskTitle}`)
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)

          if (this.recoveredSession) {
            Text(`已专注：${this.formatDuration(this.recoveredSession.actualFocusDuration)}`)
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }

          Text('上次会话已暂停，是否继续？')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
            .margin({ top: Theme.SPACE_SMALL })
        }

        Row({ space: Theme.SPACE_MEDIUM }) {
          Button('放弃')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(48)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_TEXT_TERTIARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(async () => {
              // 放弃会话 - 将其标记为完成
              if (this.recoveredSession) {
                await FocusStore.finishFocus()
              }
              this.showRecoverDialog = false
              this.recoveredSession = null
            })

          Button('继续专注')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(48)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_PRIMARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(async () => {
              this.showRecoverDialog = false
              // 恢复会话并跳转
              if (this.recoveredSession) {
                await FocusStore.recoverSession(this.recoveredSession)
                router.pushUrl({ url: 'pages/FocusPage' })
              }
            })
        }
        .width('100%')
      }
      .width('85%')
      .padding(Theme.SPACE_XLARGE)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .borderRadius(Theme.BORDER_RADIUS_LARGE)
      .shadow({
        radius: Theme.SHADOW_LARGE.radius,
        color: Theme.SHADOW_LARGE.color,
        offsetX: 0,
        offsetY: 8
      })
      .position({ x: '7.5%', y: '35%' })
    }
  }

  // 格式化时间
  private formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    
    if (hours > 0) {
      return `${hours}小时${minutes % 60}分钟`
    } else if (minutes > 0) {
      return `${minutes}分钟`
    } else {
      return `${seconds}秒`
    }
  }

  // 无任务开始专注
  private async startFocusWithoutTask() {
    router.pushUrl({ url: 'pages/StartPage' })
  }

  // 有任务开始专注
  private async startFocusWithTask(task: Task) {
    router.pushUrl({ 
      url: 'pages/StartPage',
      params: { taskId: task.id, taskTitle: task.title }
    })
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
