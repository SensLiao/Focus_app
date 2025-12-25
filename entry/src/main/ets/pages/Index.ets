/**
 * Home page - adapted to sample_frontend layout & flow
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore, TaskState } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { Task } from '../model/Task'
import { FocusSession } from '../model/FocusSession'
import { BottomNav } from '../components/BottomNav'
import { Theme } from '../common/theme'
import { Logger } from '../common/logger'
import { SettingsService } from '../services/SettingsService'
import { NotificationService } from '../services/NotificationService'
import common from '@ohos.app.ability.common'

@Entry
@Component
struct Index {
  @State taskState: TaskState = TaskStore.getState()
  @StorageLink('focusCurrentTaskId') storageCurrentTaskId: number = -1
  @StorageLink('focusIsBreaking') storageIsBreaking: boolean = false
  @StorageLink('breakEndPromptPending') pendingBreakEndPrompt: boolean = false
  @StorageLink('startRestPromptPending') pendingStartRestPrompt: boolean = false
  @State showRecoverDialog: boolean = false
  @State recoveredSession: FocusSession | null = null
  @State recoveredTaskTitle: string = ''
  @State isEditMode: boolean = false
  @State deleteTarget: Task | null = null
  @State showNotificationPermissionDialog: boolean = false

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))
    await this.ensureNotificationPermission()

    await TaskStore.loadTasks()
    this.taskState = TaskStore.getState()

    const recoverResult = await FocusStore.checkAndRecoverSession()
    if (recoverResult.ok && recoverResult.data !== null && recoverResult.data !== undefined) {
      this.recoveredSession = recoverResult.data
      if (this.recoveredSession && this.recoveredSession.taskId) {
        const task = TaskStore.findTask(this.recoveredSession.taskId)
        this.recoveredTaskTitle = task?.title ?? 'Anonymous focus'
      } else {
        this.recoveredTaskTitle = 'Anonymous focus'
      }
      //this.showRecoverDialog = true
      // NOT USED 目前不需要在主页跳转的功能
    }
  }

  async onPageShow() {
    await TaskStore.loadTasks()
    this.taskState = TaskStore.getState()
    this.routeToBreakEndIfNeeded()
    this.routeToStartRestIfNeeded()
  }

  private async ensureNotificationPermission() {
    const enabled = await NotificationService.isEnabled()
    if (!enabled) {
      this.showNotificationPermissionDialog = true
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Text('待办任务')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })

        if (this.taskState.loading) {
          Column() {
            Text('加载中...')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.taskState.tasks.length === 0) {
          Column({ space: 16 }) {
            Text('📝')
              .fontSize(56)
            Text('暂无任务')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
            Text('添加你的第一个任务开始专注吧！')
              .fontSize(14)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .textAlign(TextAlign.Center)
              .margin({ top: -8 })

            Button('无任务专注')
              .height(52)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(Theme.COLOR_BACKGROUND)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .borderRadius(14)
              .margin({ top: 8 })
              .onClick(() => {
                this.startFocusWithoutTask()
              })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ left: 24, right: 24 })
        } else {
          List({ space: 12 }) {
            ForEach(this.taskState.tasks, (task: Task) => {
              ListItem() {
                Row({ space: 12 }) {
                  Column({ space: 4 }) {
                    Text(task.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.COLOR_TEXT_PRIMARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (task.description) {
                      Text(task.description)
                        .fontSize(13)
                        .fontColor(Theme.COLOR_TEXT_SECONDARY)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    Text(`专注时长: ${this.formatDuration(task.totalFocusTime)}`)
                      .fontSize(13)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  if (this.isEditMode) {
                    Row({ space: 8 }) {
                      Button({ type: ButtonType.Normal }) {
                        Text('✏️').fontSize(18)
                      }
                      .width(44)
                      .height(44)
                      .backgroundColor(Theme.COLOR_PRIMARY_BG)
                      .borderRadius(12)
                      .onClick(() => {
                        this.goToTaskForm(task)
                      })
                      Button({ type: ButtonType.Normal }) {
                        Text('🗑️').fontSize(18)
                      }
                      .width(44)
                      .height(44)
                      .backgroundColor(Theme.COLOR_ERROR_BG)
                      .borderRadius(12)
                      .onClick(() => {
                        this.deleteTarget = task
                        this.confirmDelete()
                      })
                    }
                  } else if (this.isActiveTask(task)) {
                    Button({ type: ButtonType.Circle }) {
                      Text(this.isRestingTask(task) ? '☕' : '▶️')
                        .fontSize(20)
                    }
                    .width(44)
                    .height(44)
                    .backgroundColor(this.isRestingTask(task) ? Theme.COLOR_PURPLE_BG : Theme.COLOR_SUCCESS_BG)
                    .onClick(() => {
                      this.resumeActiveTask(task)
                    })
                  } else {
                    Button({ type: ButtonType.Circle }) {
                      Text('▶️')
                        .fontSize(20)
                    }
                    .width(44)
                    .height(44)
                    .backgroundColor(Theme.COLOR_SUCCESS_BG)
                    .onClick(() => {
                      this.startFocusWithTask(task)
                    })
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .borderRadius(16)
                .shadow({
                  radius: 4,
                  color: '#0000000A',
                  offsetX: 0,
                  offsetY: 2
                })
              }
            }, (task: Task) => task.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 16, right: 16, top: 12, bottom: 80 })
        }

        BottomNav({ currentIndex: 0 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.COLOR_BACKGROUND)

      Column({ space: 12 }) {
        Button({ type: ButtonType.Circle }) {
          Text(this.isEditMode ? '✕' : '✏️')
            .fontSize(this.isEditMode ? 24 : 22)
            .fontColor(Color.White)
        }
        .width(56)
        .height(56)
        .backgroundColor(this.isEditMode ? Theme.COLOR_WARNING : '#6B7280')
        .shadow({
          radius: 12,
          color: this.isEditMode ? '#F9731640' : '#6B728040',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.isEditMode = !this.isEditMode
        })

        Button({ type: ButtonType.Circle }) {
          Text('+')
            .fontSize(32)
            .fontWeight(FontWeight.Normal)
            .fontColor(Color.White)
        }
        .width(56)
        .height(56)
        .backgroundColor(Theme.COLOR_PRIMARY)
        .shadow({
          radius: 12,
          color: '#2563EB40',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          this.goToTaskForm()
        })
      }
      .margin({ right: 16, bottom: 88 })

      if (this.showRecoverDialog) {
        this.RecoverDialog()
      }

      if (this.showNotificationPermissionDialog) {
        this.NotificationPermissionDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  RecoverDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {})

      Column({ space: Theme.SPACE_LARGE }) {
        Text('发现未完成的专注')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Column({ space: Theme.SPACE_SMALL }) {
          Text(`任务: ${this.recoveredTaskTitle}`)
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)

          if (this.recoveredSession) {
            Text(`专注时长: ${this.formatDuration(this.recoveredSession.actualFocusDuration)}`)
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }

          Text('上次专注已暂停，是否继续？')
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
              if (this.recoveredSession) {
                await FocusStore.finishFocus()
              }
              this.showRecoverDialog = false
              this.recoveredSession = null
            })

          Button('继续')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(48)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_PRIMARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(async () => {
              this.showRecoverDialog = false
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

  @Builder
  NotificationPermissionDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {})

      Column({ space: Theme.SPACE_LARGE }) {
        Text('开启通知')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Text('应用需要通知权限来提醒你休息时间到了。')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)

        Row({ space: Theme.SPACE_MEDIUM }) {
          Button('取消')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(48)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_TEXT_TERTIARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(() => {
              const context = getContext(this) as common.UIAbilityContext
              this.showNotificationPermissionDialog = false
              context.terminateSelf()
            })

          Button('Set')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(48)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_PRIMARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(async () => {
              const context = getContext(this) as common.UIAbilityContext
              await NotificationService.requestEnable(context)
              this.showNotificationPermissionDialog = false
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

  private formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)

    if (hours > 0) {
      if (minutes % 60 > 0) {
        return `${hours}h ${minutes % 60}m`
      }
      return `${hours}h`
    }
    return `${minutes}m`
  }

  private async startFocusWithoutTask() {
    router.pushUrl({ url: 'pages/FocusPage', params: { startAnonymous: true } })
  }

  private async startFocusWithTask(task: Task) {
    router.pushUrl({
      url: 'pages/FocusPage',
      params: { pendingTaskId: task.id }
    })
  }

  private async resumeActiveTask(task: Task) {
    Logger.info(`Resuming active task: ${task.id}`)
    router.pushUrl({
      url: 'pages/FocusPage',
      params: { resumeTaskId: task.id }
    })
  }

  private isRestingTask(task: Task): boolean {
    return this.storageIsBreaking && this.storageCurrentTaskId === task.id
  }

  private isActiveTask(task: Task): boolean {
    return this.storageCurrentTaskId === task.id
  }

  private routeToBreakEndIfNeeded() {
    if (!this.pendingBreakEndPrompt) {
      return
    }
    const focusState = FocusStore.getState()
    if (!focusState.currentSession || !focusState.isBreaking) {
      return
    }
    router.pushUrl({ url: 'pages/FocusPage' })
  }

  private routeToStartRestIfNeeded() {
    if (!this.pendingStartRestPrompt) {
      return
    }
    const focusState = FocusStore.getState()
    if (!focusState.currentSession || focusState.isBreaking) {
      return
    }
    router.pushUrl({ url: 'pages/FocusPage' })
  }

  private async deleteTask(task: Task) {
    const result = await TaskStore.deleteTask(task.id)
    if (result.ok) {
      promptAction.showToast({ message: 'Task deleted' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  private confirmDelete() {
    if (!this.deleteTarget) {
      return
    }
    AlertDialog.show({
      title: 'Delete Task?',
      message: `Are you sure you want to delete "${this.deleteTarget.title}"?`,
      primaryButton: {
        value: 'Cancel',
        action: () => {}
      },
      secondaryButton: {
        value: 'Delete',
        fontColor: Theme.COLOR_ERROR,
        action: async () => {
          if (this.deleteTarget) {
            await this.deleteTask(this.deleteTarget)
            this.deleteTarget = null
          }
        }
      }
    })
  }

  private goToTaskForm(task?: Task) {
    if (task) {
      router.pushUrl({
        url: 'pages/StartPage',
        params: { taskId: task.id }
      })
    } else {
      router.pushUrl({ url: 'pages/StartPage' })
    }
  }
}
