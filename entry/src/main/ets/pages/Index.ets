/**
 * Home page - 精致现代风格 (Inspired by Flocus)
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore, TaskState } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { Task } from '../model/Task'
import { FocusSession } from '../model/FocusSession'
import { BottomNav } from '../components/BottomNav'
import { OnboardingOverlay } from '../components/OnboardingOverlay'
import { Theme } from '../common/theme'
import { Logger } from '../common/logger'
import { SettingsService } from '../services/SettingsService'
import { NotificationService } from '../services/NotificationService'
import { AppLifecycleService } from '../services/AppLifecycleService'
import common from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'
import {
  DEMO_TASK_DESCRIPTION,
  DEMO_TASK_TITLE,
  getFirstOnboardingStepId,
  getOnboardingStep,
  getOnboardingTarget,
  OnboardingRect,
  OnboardingTargets,
  shouldShowOnboarding,
  updateOnboardingTargets
} from '../onboarding/OnboardingFlow'

@Entry
@Component
struct Index {
  @State taskState: TaskState = TaskStore.getState()
  @StorageLink('focusCurrentTaskId') storageCurrentTaskId: number = -1
  @StorageLink('focusIsBreaking') storageIsBreaking: boolean = false
  @StorageLink('breakEndPromptPending') pendingBreakEndPrompt: boolean = false
  @StorageLink('startRestPromptPending') pendingStartRestPrompt: boolean = false
  @StorageLink('onboardingHistoryRectX') onboardingHistoryRectX: number = 0
  @StorageLink('onboardingHistoryRectY') onboardingHistoryRectY: number = 0
  @StorageLink('onboardingHistoryRectW') onboardingHistoryRectW: number = 0
  @StorageLink('onboardingHistoryRectH') onboardingHistoryRectH: number = 0
  @StorageLink('onboardingAdvanceTick') onboardingAdvanceTick: number = 0
  @StorageLink('onboardingSkipTick') onboardingSkipTick: number = 0
  @StorageLink('onboardingSkipped') onboardingSkipped: boolean = false
  @State lastAdvanceTick: number = 0
  @State lastSkipTick: number = 0
  private onboardingTickTimer: number = -1
  @State showRecoverDialog: boolean = false
  @State recoveredSession: FocusSession | null = null
  @State recoveredTaskTitle: string = ''
  @State isEditMode: boolean = false
  @State deleteTarget: Task | null = null
  @State showNotificationPermissionDialog: boolean = false
  @StorageLink('pendingNotificationPermission') pendingNotificationPermission: boolean = false
  // 动画相关状�?
  @State headerOpacity: number = 0
  @State listItemsLoaded: boolean = false
  // 滑动手势相关
  @State panOffsetX: number = 0
  private readonly swipeThreshold: number = 80
  @StorageLink('hasSeenOnboarding') hasSeenOnboarding: boolean = false
  @StorageLink('onboardingDisabled') onboardingDisabled: boolean = false
  @StorageLink('onboardingStepId') onboardingStepId: string = ''
  @StorageLink('onboardingDemoTaskId') onboardingDemoTaskId: number = -1
  @State onboardingTargets: OnboardingTargets = new OnboardingTargets()

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))
    await this.ensureNotificationPermission()

    await TaskStore.loadTasks()
    this.taskState = TaskStore.getState()
    await this.ensureOnboardingSetup()
    this.startOnboardingTickMonitor()

    const recoverResult = await FocusStore.checkAndRecoverSession()
    if (recoverResult.ok && recoverResult.data !== null && recoverResult.data !== undefined) {
      this.recoveredSession = recoverResult.data
      if (this.recoveredSession && this.recoveredSession.taskId) {
        const task = TaskStore.findTask(this.recoveredSession.taskId)
        this.recoveredTaskTitle = task?.title ?? '匿名专注'
      } else {
        this.recoveredTaskTitle = '匿名专注'
      }
    }

    // 入场动画
    setTimeout(() => {
      this.headerOpacity = 1
    }, 100)
    setTimeout(() => {
      this.listItemsLoaded = true
    }, 200)
  }

  async onPageShow() {
    await TaskStore.loadTasks()
    this.taskState = TaskStore.getState()
    this.routeToBreakEndIfNeeded()
    this.routeToStartRestIfNeeded()
    this.showPendingNotificationPermissionIfNeeded()
  }

  aboutToDisappear() {
    this.stopOnboardingTickMonitor()
  }

  private async ensureNotificationPermission() {
    const enabled = await NotificationService.isEnabled()
    if (!enabled) {
      if (shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)) {
        this.pendingNotificationPermission = true
        return
      }
      this.showNotificationPermissionDialog = true
    }
  }

  private handleSwipeGesture(offsetX: number, velocity: number) {
    if (this.isOnboardingActive()) {
      return
    }
    const absOffset = Math.abs(offsetX)
    const absVelocity = Math.abs(velocity)
    
    // 快速滑动或滑动距离足够
    if (absVelocity > 500 || absOffset > this.swipeThreshold) {
      if (offsetX > 0) {
        // 向右滑动 - 切换到历史页�?
        router.replaceUrl({ url: 'pages/HistoryPage' })
      } else if (offsetX < 0) {
        // 向左滑动 - 切换到设置页�?
        router.replaceUrl({ url: 'pages/SettingsPage' })
      }
    }
  }

  private startOnboardingTickMonitor() {
    if (this.onboardingTickTimer !== -1) {
      return
    }
    this.lastAdvanceTick = this.onboardingAdvanceTick
    this.lastSkipTick = this.onboardingSkipTick
    this.onboardingTickTimer = setInterval(() => {
      if (!this.shouldShowOnboardingForRoute('HOME')) {
        this.lastAdvanceTick = this.onboardingAdvanceTick
        this.lastSkipTick = this.onboardingSkipTick
        return
      }
      if (this.onboardingAdvanceTick !== this.lastAdvanceTick) {
        this.lastAdvanceTick = this.onboardingAdvanceTick
        this.handleOnboardingAdvance()
      }
      if (this.onboardingSkipTick !== this.lastSkipTick) {
        this.lastSkipTick = this.onboardingSkipTick
        void this.handleOnboardingSkip()
      }
    }, 150)
  }

  private stopOnboardingTickMonitor() {
    if (this.onboardingTickTimer === -1) {
      return
    }
    clearInterval(this.onboardingTickTimer)
    this.onboardingTickTimer = -1
  }

  private async handleOnboardingSkip() {
    this.onboardingSkipped = true
    this.endOnboarding()
    await this.cleanupDemoTask()
    router.replaceUrl({ url: 'pages/Index' })
  }

  private async cleanupDemoTask() {
    let demoId = this.onboardingDemoTaskId
    if (demoId <= 0) {
      const existing = this.findDemoTaskByTitle()
      if (existing) {
        demoId = existing.id
      }
    }
    if (demoId > 0) {
      await TaskStore.deleteTask(demoId)
    }
    if (demoId > 0) {
      this.onboardingDemoTaskId = demoId
    }
  }

  private parseLength(value: Length | undefined): number {
    if (value === undefined) {
      return 0
    }
    if (typeof value === 'number') {
      return value
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value)
      return Number.isNaN(parsed) ? 0 : parsed
    }
    return 0
  }

  private areaToRect(newArea: Area): OnboardingRect {
    const pos = newArea.globalPosition ?? newArea.position
    return {
      x: this.parseLength(pos?.x),
      y: this.parseLength(pos?.y) - 40,
      width: this.parseLength(newArea.width),
      height: this.parseLength(newArea.height)
    }
  }

  private updateOnboardingTarget(targetId: string, newArea: Area) {
    const rect = this.areaToRect(newArea)
    this.updateOnboardingRect(targetId, rect)
  }

  private updateOnboardingRect(targetId: string, rect: OnboardingRect) {
    this.onboardingTargets = updateOnboardingTargets(this.onboardingTargets, targetId, rect)
  }

  private getCurrentOnboardingStep() {
    return getOnboardingStep(this.onboardingStepId)
  }

  private getCurrentOnboardingTarget(): OnboardingRect | undefined {
    const step = this.getCurrentOnboardingStep()
    if (!step?.targetId) {
      return undefined
    }
    if (step.targetId === 'home_history_icon') {
      return {
        x: this.onboardingHistoryRectX,
        y: this.onboardingHistoryRectY,
        width: this.onboardingHistoryRectW,
        height: this.onboardingHistoryRectH
      }
    }
    return getOnboardingTarget(this.onboardingTargets, step.targetId)
  }

  private shouldShowOnboardingForRoute(route: string): boolean {
    const step = this.getCurrentOnboardingStep()
    if (!step) {
      return false
    }
    if (step.isSetup) {
      return false
    }
    if (!shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)) {
      return false
    }
    return step.route === route
  }

  private isOnboardingActive(): boolean {
    if (this.onboardingStepId === '') {
      return false
    }
    return shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)
  }

  private handleOnboardingAdvance() {
    const step = this.getCurrentOnboardingStep()
    if (!step) {
      return
    }
    switch (step.id) {
      case 's1_home_list_intro':
        this.onboardingStepId = 's2_select_demo_task'
        return
      case 's2_select_demo_task': {
        const demoId = this.getDemoTaskId()
        if (demoId <= 0) {
          return
        }
        router.pushUrl({ url: 'pages/FocusPage', params: { pendingTaskId: demoId } })
        this.onboardingStepId = 's3_start_focus'
        return
      }
      case 's8_history_entry':
        router.pushUrl({ url: 'pages/HistoryPage' })
        this.onboardingStepId = 'end_history_page'
        return
      default:
        return
    }
  }

  private endOnboarding() {
    this.hasSeenOnboarding = true
    this.onboardingDisabled = true
    this.onboardingStepId = ''
    this.showPendingNotificationPermissionIfNeeded()
  }

  private showPendingNotificationPermissionIfNeeded() {
    if (!this.pendingNotificationPermission) {
      return
    }
    if (shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)) {
      return
    }
    if (this.showNotificationPermissionDialog) {
      return
    }
    this.pendingNotificationPermission = false
    this.showNotificationPermissionDialog = true
  }

  private async ensureOnboardingSetup() {
    if (!shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)) {
      return
    }
    if (this.onboardingStepId === '') {
      this.onboardingStepId = getFirstOnboardingStepId()
    }
    if (this.onboardingStepId !== 'setup_demo_task') {
      return
    }
    const demoId = await this.ensureDemoTask()
    if (demoId !== null) {
      this.onboardingDemoTaskId = demoId
      this.taskState = TaskStore.getState()
      this.onboardingStepId = 's1_home_list_intro'
    }
  }

  private getDemoTaskId(): number {
    if (this.onboardingDemoTaskId > 0) {
      return this.onboardingDemoTaskId
    }
    const existing = this.findDemoTaskByTitle()
    if (existing) {
      this.onboardingDemoTaskId = existing.id
      return existing.id
    }
    return -1
  }

  private findDemoTaskByTitle(): Task | undefined {
    const tasks = TaskStore.getState().tasks
    return tasks.find((task) => task.title === DEMO_TASK_TITLE && task.description === DEMO_TASK_DESCRIPTION)
  }

  private async ensureDemoTask(): Promise<number | null> {
    if (this.onboardingDemoTaskId > 0) {
      const existing = TaskStore.findTask(this.onboardingDemoTaskId)
      if (existing) {
        return existing.id
      }
    }
    const existingByTitle = this.findDemoTaskByTitle()
    if (existingByTitle) {
      return existingByTitle.id
    }
    const result = await TaskStore.createTask({
      title: DEMO_TASK_TITLE,
      description: DEMO_TASK_DESCRIPTION
    })
    if (result.ok && result.data !== undefined) {
      return result.data
    }
    return null
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // 顶部标题�?- 更大字体和优雅渐�?
        Column() {
          Row() {
            Text('待办任务')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)

            Blank()

            Text(this.getGreeting())
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        }
        .width('100%')
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })
        .opacity(this.headerOpacity)
        .animation({
          duration: Theme.ANIMATION_NORMAL,
          curve: Curve.EaseOut
        })

        Stack({ alignContent: Alignment.BottomEnd }) {
          Column() {
            if (this.taskState.loading) {
              Column() {
                LoadingProgress()
                  .width(48)
                  .height(48)
                  .color(Theme.COLOR_TEXT_PRIMARY)
                Text('???...')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  .margin({ top: 16 })
              }
              .height('100%')
              .justifyContent(FlexAlign.Center)
            } else if (this.taskState.tasks.length === 0) {
              // ??? - ??????
              Column({ space: 20 }) {
                // ???
                Column() {
                  Text('📝')
                    .fontSize(80)
                }
                .width(140)
                .height(140)
                .borderRadius(70)
                .backgroundColor(Theme.COLOR_DIVIDER)
                .justifyContent(FlexAlign.Center)

                Text('暂无任务')
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)

                Text('添加你的第一个任务\n开始专注之旅吧?')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  .textAlign(TextAlign.Center)
                  .lineHeight(28)

                Button('无任务专注')
                  .height(56)
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .backgroundColor(Theme.COLOR_BACKGROUND)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  .borderRadius(Theme.BORDER_RADIUS_LARGE)
                  .border({ width: 1, color: Theme.COLOR_BORDER })
                  .margin({ top: 12 })
                  .onClick(() => {
                    this.startFocusWithoutTask()
                  })
              }
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ left: 32, right: 32 })
            } else {
              List({ space: 10 }) {
                ForEach(this.taskState.tasks, (task: Task, index: number) => {
                  ListItem() {
                    Row({ space: 10 }) {
                      Column({ space: 4 }) {
                        Row({ space: 8 }) {
                          Text(task.title)
                            .fontSize(Theme.FONT_SIZE_MEDIUM)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(Theme.COLOR_TEXT_PRIMARY)
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)

                          // Active status
                          if (this.isActiveTask(task) && !this.isRestingTask(task)) {
                            Row({ space: 4 }) {
                              Circle()
                                .width(8)
                                .height(8)
                                .fill(Theme.COLOR_TEXT_TERTIARY)
                              Text('专注中')
                                .fontSize(Theme.FONT_SIZE_TINY)
                                .fontColor(Theme.COLOR_TEXT_SECONDARY)
                            }
                            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                            .backgroundColor(Theme.COLOR_DIVIDER)
                            .borderRadius(Theme.BORDER_RADIUS_FULL)
                          }
                        }

                        Row({ space: 6 }) {
                          Text('⏱')
                            .fontSize(Theme.FONT_SIZE_TINY)
                          Text(`专注时长: ${this.formatDuration(task.totalFocusTime)}`)
                            .fontSize(Theme.FONT_SIZE_SMALL)
                            .fontColor(Theme.COLOR_TEXT_TERTIARY)
                        }
                      }
                      .layoutWeight(1)
                      .alignItems(HorizontalAlign.Start)

                      if (this.isEditMode) {
                        Row({ space: 10 }) {
                          Button({ type: ButtonType.Normal }) {
                            Image($r('app.media.sub_task_change'))
                              .width(24)
                              .height(24)
                          }
                          .width(44)
                          .height(44)
                          .backgroundColor(Theme.COLOR_DIVIDER)
                          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                          .onClick(() => {
                            this.goToTaskForm(task)
                          })

                          Button({ type: ButtonType.Normal }) {
                            Image($r('app.media.delete_icon'))
                              .width(24)
                              .height(24)
                          }
                          .width(44)
                          .height(44)
                          .backgroundColor(Theme.COLOR_DIVIDER)
                          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                          .onClick(() => {
                            this.deleteTarget = task
                            this.confirmDelete()
                          })
                        }
                      } else {
                        // ???? - ??????
                        Button({ type: ButtonType.Circle }) {
                          if (this.isRestingTask(task)) {
                            Text('\u2615')
                              .fontSize(22)
                              .fontColor(Color.White)
                          } else {
                            Image($r('app.media.start_button'))
                              .width(28)
                              .height(28)
                          }
                        }
                        .width(52)
                        .height(52)
                        .backgroundColor(this.isRestingTask(task) ? Theme.COLOR_WARNING : Theme.COLOR_CARD_BACKGROUND)
                        .border({ width: this.isRestingTask(task) ? 0 : 1, color: Theme.COLOR_BORDER })
                        .shadow(Theme.SHADOW_SMALL)
                        .onClick(() => {
                          if (this.isActiveTask(task)) {
                            this.resumeActiveTask(task)
                          } else {
                            this.startFocusWithTask(task)
                          }
                        })
                      }
                    }
                    .width('100%')
                    .padding({ left: 28, right: 28, top: 20, bottom: 20 })
                    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                    .shadow(Theme.SHADOW_SMALL)
                    .onAreaChange((_, newArea) => {
                      if (task.id === this.onboardingDemoTaskId) {
                        const rect = this.areaToRect(newArea)
                        //rect.y += 80  //task
                        //rect.x += 15
                        this.updateOnboardingRect('home_demo_task_row', rect)
                      }
                    })
                    .onClick(() => {
                      if (this.isEditMode) {
                        return
                      }
                      if (this.isActiveTask(task)) {
                        this.resumeActiveTask(task)
                      } else {
                        this.startFocusWithTask(task)
                      }
                    })
                    .opacity(this.listItemsLoaded ? 1 : 0)
                    .translate({ y: this.listItemsLoaded ? 0 : 20 })
                    .animation({
                      duration: Theme.ANIMATION_NORMAL,
                      delay: index * 50,
                      curve: Curve.EaseOut
                    })
                  }
                }, (task: Task) => task.id.toString())
              }
              .width('100%')
              .height('100%')
              .padding({ left: 16, right: 16, top: 0, bottom: 0 })
            }
          }
          .width('100%')
          .height('100%')
          .onAreaChange((_, newArea) => {
            const rect2 = this.areaToRect(newArea)
            rect2.width = Math.max(0, rect2.width - 10)
            rect2.x += 5
            //rect2.y += 10 //to do list
            //rect2.height += 30
            this.updateOnboardingRect('home_list_area', rect2)
          })
          .position({ x: 0, y: 0 })
      Column({ space: 12 }) {
        // 编辑模式按钮
        Button({ type: ButtonType.Circle }) {
          if (this.isEditMode) {
            Text('�?')
              .fontSize(34)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
          } else {
            Image($r('app.media.editor_task'))
              .width(40)
              .height(40)
          }
        }
        .width(78)
        .height(78)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({ width: 1, color: Theme.COLOR_BORDER })
        .shadow(Theme.SHADOW_MEDIUM)
        .onClick(() => {
          this.isEditMode = !this.isEditMode
        })

        // 添加任务按钮
        Button({ type: ButtonType.Circle }) {
          Text('+')
            .fontSize(48)
            .fontWeight(FontWeight.Normal)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .width(86)
        .height(86)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({ width: 1, color: Theme.COLOR_BORDER })
        .shadow(Theme.SHADOW_MEDIUM)
        .onClick(() => {
          this.goToTaskForm()
        })
      }
      .margin({ right: 20, bottom: 16 })
        }
        .layoutWeight(1)
        .width('100%')


        BottomNav({ currentIndex: 0 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.COLOR_BACKGROUND)

      if (this.showRecoverDialog) {
        this.RecoverDialog()
      }

      if (this.showNotificationPermissionDialog) {
        this.NotificationPermissionDialog()
      }

      if (this.shouldShowOnboardingForRoute('HOME')) {
        OnboardingOverlay({
          visible: true,
          body: this.getCurrentOnboardingStep()?.body ?? '',
          rule: this.getCurrentOnboardingStep()?.rule ?? 'TAP_ANYWHERE_EXCEPT_SKIP',
          target: this.getCurrentOnboardingTarget(),
          showSkip: true
        })
      }
    }
    .width('100%')
    .height('100%')
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionUpdate((event: GestureEvent) => {
          this.panOffsetX = event.offsetX
        })
        .onActionEnd((event: GestureEvent) => {
          this.handleSwipeGesture(event.offsetX, event.velocityX)
          this.panOffsetX = 0
        })
    )
  }

  private getGreeting(): string {
    const hour = new Date().getHours()
    if (hour < 6) return '夜深了，注意休息 🌙'
    if (hour < 12) return '早上好，开始新的一天 ☀️'
    if (hour < 14) return '中午好，别忘了休息 🌤️'
    if (hour < 18) return '下午好，保持专注 💪'
    return '晚上好，今天辛苦了 🌟'
  }

  @Builder
  RecoverDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {})

      Column({ space: Theme.SPACE_LARGE }) {
        // 图标
        Column() {
          Text('�?')
            .fontSize(48)
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor(Theme.COLOR_DIVIDER)
        .justifyContent(FlexAlign.Center)
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

          Text('上次专注已暂停，是否继续�?')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
            .margin({ top: Theme.SPACE_SMALL })
        }

        Row({ space: Theme.SPACE_MEDIUM }) {
          Button('放弃')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(52)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_BACKGROUND)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(async () => {
              const session = this.recoveredSession
              if (session) {
                await FocusStore.finishFocus()
              }
              this.showRecoverDialog = false
              this.recoveredSession = null
            })

          Button('继续')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(52)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_TEXT_PRIMARY)
            .fontColor(Theme.COLOR_TEXT_ON_PRIMARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .shadow(Theme.SHADOW_MEDIUM)
            .onClick(async () => {
              this.showRecoverDialog = false
              const session = this.recoveredSession
              if (session) {
                await FocusStore.recoverSession(session)
                router.pushUrl({ url: 'pages/FocusPage' })
              }
            })
        }
        .width('100%')
      }
      .width('85%')
      .padding(Theme.SPACE_XLARGE)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .borderRadius(Theme.BORDER_RADIUS_XLARGE)
      .shadow(Theme.SHADOW_LARGE)
      .position({ x: '7.5%', y: '30%' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  NotificationPermissionDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {})

      Column({ space: Theme.SPACE_LARGE }) {
        // 图标
        Column() {
          Text('🔔')
            .fontSize(48)
        }
        .width(80)
        .height(80)
        .borderRadius(40)
        .backgroundColor(Theme.COLOR_DIVIDER)
        .justifyContent(FlexAlign.Center)

        Text('开启通知')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Text('应用需要通知权限来提醒你休息时间到了，\n帮助你更好地管理专注与休息�?')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .textAlign(TextAlign.Center)
          .lineHeight(24)

        Row({ space: Theme.SPACE_MEDIUM }) {
          Button('取消')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(52)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_BACKGROUND)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .onClick(() => {
              const context = getContext(this) as common.UIAbilityContext
              this.showNotificationPermissionDialog = false
              context.terminateSelf()
            })

          Button('去设�?')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .height(52)
            .layoutWeight(1)
            .backgroundColor(Theme.COLOR_TEXT_PRIMARY)
            .fontColor(Theme.COLOR_TEXT_ON_PRIMARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .shadow(Theme.SHADOW_MEDIUM)
            .onClick(async () => {
              const context = getContext(this) as common.UIAbilityContext
              this.showNotificationPermissionDialog = false
              await this.requestNotificationPermissionWithFallback(context)
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
    .width('100%')
    .height('100%')
  }

  private async requestNotificationPermissionWithFallback(context: common.UIAbilityContext) {
    try {
      await NotificationService.requestEnable(context)
    } catch (error) {
      Logger.warn('Notification permission request failed', JSON.stringify(error))
    }
    const enabled = await NotificationService.isEnabled()
    if (enabled) {
      return
    }
    await this.openAppSettingsForNotifications(context)
  }

  private async openAppSettingsForNotifications(context: common.UIAbilityContext): Promise<void> {
    try {
      const bundleName = context.abilityInfo.bundleName
      const want: Want = {
        action: 'action.settings.app.info',
        uri: 'application_info_entry',
        parameters: {
          pushParams: bundleName
        }
      }
      const didBackground = await this.tryOpenSettingsWithLifecycle(context, want)
      if (didBackground) {
        Logger.info('Opened app settings for notifications')
        return
      }
      //this.openSystemSettingsFallback(context)
    } catch (error) {
      Logger.error('Failed to open app settings', JSON.stringify(error))
      //this.openSystemSettingsFallback(context)
    }
  }

  private openSystemSettingsFallback(context: common.UIAbilityContext) {
    try {
      const want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility'
      }
      context.startAbility(want).then(() => {
        Logger.info('Opened system settings main page')
      }).catch((err: Error) => {
        Logger.error('Fallback settings open failed', JSON.stringify(err))
      })
    } catch (error) {
      Logger.error('Fallback settings open error', JSON.stringify(error))
    }
  }

  private async tryOpenSettingsWithLifecycle(context: common.UIAbilityContext, want: Want): Promise<boolean> {
    return new Promise((resolve) => {
      let done = false
      const listener = (event: 'foreground' | 'background' | 'destroy') => {
        if (event !== 'background' || done) {
          return
        }
        done = true
        AppLifecycleService.unregister(listener)
        resolve(true)
      }
      AppLifecycleService.register(listener)
      context.startAbility(want).then(() => {
        if (done) {
          return
        }
        setTimeout(() => {
          if (done) {
            return
          }
          done = true
          AppLifecycleService.unregister(listener)
          resolve(false)
        }, 1200)
      }).catch(() => {
        if (done) {
          return
        }
        done = true
        AppLifecycleService.unregister(listener)
        resolve(false)
      })
    })
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
    const target = this.deleteTarget
    if (!target) {
      return
    }
    AlertDialog.show({
      title: 'Delete Task?',
      message: `Are you sure you want to delete "${target.title}"?`,
      primaryButton: {
        value: 'Cancel',
        action: () => {}
      },
      secondaryButton: {
        value: 'Delete',
        fontColor: Theme.COLOR_TEXT_PRIMARY,
        action: async () => {
          await this.deleteTask(target)
          this.deleteTarget = null
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

