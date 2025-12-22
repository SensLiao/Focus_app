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

@Entry
@Component
struct Index {
  @State taskState: TaskState = TaskStore.getState()
  @StorageLink('focusCurrentTaskId') storageCurrentTaskId: number = -1
  @StorageLink('focusIsBreaking') storageIsBreaking: boolean = false
  @State showRecoverDialog: boolean = false
  @State recoveredSession: FocusSession | null = null
  @State recoveredTaskTitle: string = ''
  @State isEditMode: boolean = false
  @State deleteTarget: Task | null = null

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))

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
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Text('To do List')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .width('100%')
        .height(64)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(Color.White)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })

        if (this.taskState.loading) {
          Column() {
            Text('Loading tasks...')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.taskState.tasks.length === 0) {
          Column({ space: Theme.SPACE_MEDIUM }) {
            Text('馃摑')
              .fontSize(48)
            Text('No tasks yet. Add your first task to get started!')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .textAlign(TextAlign.Center)

            Button('Start without a task')
              .height(48)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .fontColor(Color.White)
              .borderRadius(Theme.BORDER_RADIUS_LARGE)
              .onClick(() => {
                this.startFocusWithoutTask()
              })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .padding({ left: 24, right: 24 })
        } else {
          List({ space: Theme.SPACE_MEDIUM }) {
            ForEach(this.taskState.tasks, (task: Task) => {
              ListItem() {
                Row({ space: Theme.SPACE_MEDIUM }) {
                  Column({ space: 6 }) {
                    Text(task.title)
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.COLOR_TEXT_PRIMARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (task.description) {
                      Text(task.description)
                        .fontSize(14)
                        .fontColor(Theme.COLOR_TEXT_SECONDARY)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    Row({ space: Theme.SPACE_SMALL }) {
                      Text(`Focus time: ${this.formatDuration(task.totalFocusTime)}`)
                        .fontSize(12)
                        .fontColor(Theme.COLOR_TEXT_TERTIARY)
                    }
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  if (this.isEditMode) {
                    Row({ space: 8 }) {
                      Button('Edit')
                        .fontSize(14)
                        .height(40)
                        .backgroundColor('#E6F0FF')
                        .fontColor(Theme.COLOR_PRIMARY)
                        .borderRadius(12)
                        .onClick(() => {
                          this.goToTaskForm(task)
                        })
                      Button('Delete')
                        .fontSize(14)
                        .height(40)
                        .backgroundColor('#FFEAEA')
                        .fontColor(Theme.COLOR_ERROR)
                        .borderRadius(12)
                        .onClick(() => {
                          this.deleteTarget = task
                          this.confirmDelete()
                        })
                    }
                  } else if (this.isActiveTask(task)) {
                    Button({ type: ButtonType.Circle }) {
                      Text(this.isRestingTask(task) ? '☕' : '▶')
                        .fontSize(22)
                    }
                    .width(48)
                    .height(48)
                    .backgroundColor(this.isRestingTask(task) ? '#F0E5FF' : '#E6FFFB')
                    .onClick(() => {
                      this.resumeActiveTask(task)
                    })
                  } else {
                    Button({ type: ButtonType.Circle }) {
                      Text('▶')
                        .fontSize(20)
                    }
                    .width(48)
                    .height(48)
                    .backgroundColor('#E6FFFB')
                    .onClick(() => {
                      this.startFocusWithTask(task)
                    })
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor(Color.White)
                .borderRadius(16)
                .shadow({
                  radius: Theme.SHADOW_SMALL.radius,
                  color: Theme.SHADOW_SMALL.color,
                  offsetX: 0,
                  offsetY: 2
                })
              }
            }, (task: Task) => task.id.toString())
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 20, right: 20, top: 16, bottom: 80 })
        }

        BottomNav({ currentIndex: 0 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F7F8FA')

      Column({ space: 12 }) {
        Button({ type: ButtonType.Circle }) {
          Text(this.isEditMode ? '✓' : '✎')
            .fontSize(22)
            .fontColor(Color.White)
        }
        .width(64)
        .height(64)
        .backgroundColor(this.isEditMode ? '#FA8C16' : '#595959')
        .shadow({
          radius: Theme.SHADOW_MEDIUM.radius,
          color: Theme.SHADOW_MEDIUM.color,
          offsetX: 0,
          offsetY: 6
        })
        .onClick(() => {
          this.isEditMode = !this.isEditMode
        })

        Button({ type: ButtonType.Circle }) {
          Text('+')
            .fontSize(28)
            .fontColor(Color.White)
        }
        .width(64)
        .height(64)
        .backgroundColor(Theme.COLOR_PRIMARY)
        .shadow({
          radius: Theme.SHADOW_MEDIUM.radius,
          color: Theme.SHADOW_MEDIUM.color,
          offsetX: 0,
          offsetY: 6
        })
        .onClick(() => {
          this.goToTaskForm()
        })
      }
      .margin({ right: 20, bottom: 96 })

      if (this.showRecoverDialog) {
        this.RecoverDialog()
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
        Text('Unfinished focus session found')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Column({ space: Theme.SPACE_SMALL }) {
          Text(`Task: ${this.recoveredTaskTitle}`)
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)

          if (this.recoveredSession) {
            Text(`Focus time: ${this.formatDuration(this.recoveredSession.actualFocusDuration)}`)
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }

          Text('Last session was paused. Continue?')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
            .margin({ top: Theme.SPACE_SMALL })
        }

        Row({ space: Theme.SPACE_MEDIUM }) {
          Button('Discard')
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

          Button('Continue')
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



