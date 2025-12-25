/**
 * Timer page - adapted to sample_frontend layout & flow
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import power from '@ohos.power'
import { FocusStore, FocusState } from '../store/focusStore'
import { TaskStore } from '../store/taskStore'
import { SessionStatus } from '../model/SessionStatus'
import { SessionType } from '../model/FocusSession'
import { SessionRepo } from '../data/SessionRepo'
import { BreakRepo } from '../data/BreakRepo'
import { SettingsService } from '../services/SettingsService'
import { AppLifecycleService } from '../services/AppLifecycleService'
import { NotificationService } from '../services/NotificationService'
import { Theme } from '../common/theme'

interface SessionSummary {
  id: number
  date: number
  focusDuration: number
  restDuration: number
  status: SessionStatus
}

interface RouterParams {
  pendingTaskId?: number
  resumeTaskId?: number
  startAnonymous?: boolean
}

@Entry
@Component
struct FocusPage {
  @State focusState: FocusState = FocusStore.getState()
  @State taskTitle: string = ''
  @State taskDescription: string = ''
  @State taskTotalFocusTime: number = 0
  @State completedFocusOffset: number = 0
  @State isIdle: boolean = false
  @State isCountdownMode: boolean = false
  @State countdownMinutes: number = 25
  @State pendingTaskId: number | null = null
  @State startAnonymous: boolean = false
  @State showPauseWarning: boolean = false
  @State neverShowPauseWarning: boolean = false
  @State showLeaveWarning: boolean = false
  @State showActiveTaskWarning: boolean = false
  @State viewingOtherTask: boolean = false
  @State showTaskLoadError: boolean = false
  @State taskLoadErrorMessage: string = ''
  @State sessionDetails: SessionSummary[] = []
  @State sessionSheetVisible: boolean = false
  @State sessionSheetOffset: number = 380
  @State sessionSheetOpacity: number = 0
  @State displayIsBreaking: boolean = false
  @State isModeAnimating: boolean = false
  @State showStartRestPrompt: boolean = false
  @State showBreakEndPrompt: boolean = false
  @StorageLink('breakEndPromptPending') pendingBreakEndPrompt: boolean = false
  @StorageLink('startRestPromptPending') pendingStartRestPrompt: boolean = false
  @State allowRest: boolean = true
  @State restIntervalMs: number = 0
  @State restDurationMs: number = 0
  @State nextRestDueAtMs: number = 0
  private timerInterval: number = -1
  private restPromptTimeoutId: number = -1
  private lifecycleListener: ((event: 'foreground' | 'background' | 'destroy') => void) | null = null
  private modeTransitionTimer: number = -1

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))
    this.loadRestSettings()
    await TaskStore.loadTasks()

    const params = router.getParams() as RouterParams
    this.pendingTaskId = params?.pendingTaskId ?? null
    this.startAnonymous = params?.startAnonymous === true

    this.focusState = FocusStore.getState()
    this.displayIsBreaking = this.focusState.isBreaking
    if (this.focusState.currentSession && this.nextRestDueAtMs === 0) {
      this.resetNextRestCountdown()
    }
    if (this.focusState.currentSession) {
      if (this.pendingTaskId !== null && this.pendingTaskId !== this.focusState.currentTaskId) {
        if (!this.applyTaskMetaById(this.pendingTaskId)) {
          return
        }
        await this.loadSessionDetails(this.pendingTaskId)
        this.isIdle = true
        this.viewingOtherTask = true
        return
      }
      if (!this.syncTaskMeta()) {
        return
      }
      this.startTimer()
      await this.loadSessionDetails(this.focusState.currentTaskId ?? undefined)
      this.viewingOtherTask = false
      return
    }

    if (params?.resumeTaskId !== undefined) {
      const recoverResult = await FocusStore.checkAndRecoverSession()
      if (recoverResult.ok && recoverResult.data) {
        await FocusStore.recoverSession(recoverResult.data)
        this.focusState = FocusStore.getState()
        this.syncTaskMeta()
        this.startTimer()
        await this.loadSessionDetails(this.focusState.currentTaskId ?? undefined)
        return
      }
    }

    if (this.pendingTaskId !== null) {
      if (!this.applyTaskMetaById(this.pendingTaskId)) {
        return
      }
      await this.loadSessionDetails(this.pendingTaskId)
    } else if (this.startAnonymous) {
      this.taskTitle = 'Anonymous'
      this.taskTotalFocusTime = 0
    } else {
      this.taskTitle = ''
      this.taskDescription = ''
      this.taskTotalFocusTime = 0
      this.taskLoadErrorMessage = 'No task was provided for this page.'
      this.showTaskLoadError = true
      return
    }

    this.isIdle = true
    this.viewingOtherTask = false

    this.lifecycleListener = (event) => {
      if (event === 'foreground') {
        this.focusState = FocusStore.getState()
        void this.loadSessionDetails(this.pendingTaskId ?? this.focusState.currentTaskId ?? undefined)
      }
    }
    AppLifecycleService.register(this.lifecycleListener)
  }

  aboutToDisappear() {
    if (this.lifecycleListener) {
      AppLifecycleService.unregister(this.lifecycleListener)
      this.lifecycleListener = null
    }
    if (this.modeTransitionTimer !== -1) {
      clearTimeout(this.modeTransitionTimer)
      this.modeTransitionTimer = -1
    }
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
      this.timerInterval = -1
    }
    if (this.restPromptTimeoutId !== -1) {
      clearTimeout(this.restPromptTimeoutId)
      this.restPromptTimeoutId = -1
    }
  }

  private startTimer() {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
    }
    this.timerInterval = setInterval(() => {
      const nextState = FocusStore.getState()
      this.focusState = nextState
      this.handleModeTransition(nextState.isBreaking)
      this.checkRestIntervalPrompt()
      this.checkBreakEndPrompt()
    }, 1000)
    this.isIdle = false
  }

  private syncTaskMeta(): boolean {
    if (this.focusState.currentTaskId !== null) {
      return this.applyTaskMetaById(this.focusState.currentTaskId)
    }
    if (this.startAnonymous) {
      this.taskTitle = 'Anonymous'
      this.taskTotalFocusTime = 0
      return true
    }
    this.taskTitle = ''
    this.taskDescription = ''
    this.taskTotalFocusTime = 0
    this.taskLoadErrorMessage = 'No task was provided for this page.'
    this.showTaskLoadError = true
    return false
  }

  private applyTaskMetaById(taskId: number): boolean {
    const task = TaskStore.findTask(taskId)
    if (task) {
      this.taskTitle = task.title
      this.taskDescription = task.description ?? ''
      this.taskTotalFocusTime = task.totalFocusTime ?? 0
      return true
    }
    this.taskTitle = ''
    this.taskDescription = ''
    this.taskTotalFocusTime = 0
    this.taskLoadErrorMessage = 'Unable to load the selected task. Please return to the list and try again.'
    this.showTaskLoadError = true
    return false
  }

  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    if (minutes >= 60) {
      const hours = Math.floor(minutes / 60)
      const remainMinutes = minutes % 60
      return `${hours}:${remainMinutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    }
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  private loadRestSettings() {
    const settings = SettingsService.getSettings()
    this.allowRest = settings.restEnabled
    if (!this.allowRest) {
      this.restIntervalMs = 0
      this.restDurationMs = 0
      this.showStartRestPrompt = false
      this.pendingStartRestPrompt = false
      void NotificationService.cancelRestInterval()
      return
    }
    this.restIntervalMs = Math.max(0, settings.defaultRestInterval) * 60 * 1000
    this.restDurationMs = Math.max(0, settings.defaultRestDuration) * 60 * 1000
  }

  private resetNextRestCountdown() {
    if (this.restIntervalMs > 0 && this.focusState.currentSession && !this.viewingOtherTask) {
      this.nextRestDueAtMs = this.getElapsedMs() + this.restIntervalMs
    } else {
      this.nextRestDueAtMs = 0
    }
  }

  private getNextRestRemainingMs(): number {
    if (this.restIntervalMs <= 0 || this.nextRestDueAtMs <= 0) {
      return 0
    }
    if (this.viewingOtherTask || !this.focusState.currentSession) {
      return 0
    }
    const remaining = this.nextRestDueAtMs - this.getElapsedMs()
    return Math.max(0, remaining)
  }

  private checkRestIntervalPrompt() {
    if (!this.allowRest) {
      return
    }
    if (this.pendingStartRestPrompt && !this.showStartRestPrompt) {
      this.pendingStartRestPrompt = false
      this.showStartRestPrompt = true
      this.startRestPromptTimeout()
      void NotificationService.cancelRestInterval()
      return
    }
    if (this.showStartRestPrompt) {
      return
    }
    if (!this.focusState.currentSession || this.viewingOtherTask) {
      return
    }
    if (this.focusState.isBreaking || this.focusState.currentSession.status !== SessionStatus.RUNNING) {
      return
    }
    if (this.restIntervalMs <= 0 || this.nextRestDueAtMs <= 0) {
      return
    }
    if (this.getElapsedMs() >= this.nextRestDueAtMs) {
      void this.handleRestIntervalReached()
    }
  }

  private async handleRestIntervalReached() {
    this.nextRestDueAtMs = 0
    let screenOn = true
    try {
      screenOn = await power.isScreenOn()
    } catch (error) {
      screenOn = true
    }
    if (screenOn) {
      this.showStartRestPrompt = true
      this.startRestPromptTimeout()
      await NotificationService.playRestIntervalSound()
      return
    }
    this.pendingStartRestPrompt = true
    await NotificationService.publishRestInterval()
  }

  private startRestPromptTimeout() {
    if (this.restPromptTimeoutId !== -1) {
      clearTimeout(this.restPromptTimeoutId)
    }
    this.restPromptTimeoutId = setTimeout(() => {
      this.restPromptTimeoutId = -1
      if (!this.showStartRestPrompt) {
        return
      }
      this.showStartRestPrompt = false
      this.pendingStartRestPrompt = false
      void NotificationService.cancelRestInterval()
      this.resetNextRestCountdown()
    }, 20000)
  }

  private checkBreakEndPrompt() {
    if (this.showBreakEndPrompt) {
      return
    }
    if (this.pendingBreakEndPrompt) {
      this.pendingBreakEndPrompt = false
      this.showBreakEndPrompt = true
      return
    }
    if (!this.focusState.isBreaking || !this.focusState.currentSession) {
      return
    }
    if (!this.focusState.breakIsOver) {
      return
    }
    this.pendingBreakEndPrompt = false
    this.showBreakEndPrompt = true
  }

  private async startSession() {
    const timeLimitMs = this.isCountdownMode ? this.countdownMinutes * 60 * 1000 : undefined
    const sessionType = this.isCountdownMode ? SessionType.COUNTDOWN : SessionType.NORMAL
    this.loadRestSettings()
    const result = await FocusStore.startFocus(this.pendingTaskId ?? undefined, timeLimitMs, sessionType, this.restIntervalMs, undefined)
    if (result.ok) {
      this.focusState = FocusStore.getState()
      if (!this.syncTaskMeta()) {
        return
      }
      this.startTimer()
      this.showBreakEndPrompt = false
      this.showStartRestPrompt = false
      this.resetNextRestCountdown()
      this.viewingOtherTask = false
      await this.loadSessionDetails(this.focusState.currentTaskId ?? undefined)
      promptAction.showToast({ message: 'Focus started' })
    } else {
      if (result.code === 'HAS_ACTIVE_SESSION') {
        this.showActiveTaskWarning = true
      } else {
        promptAction.showToast({ message: result.message ?? 'Unable to start focus' })
      }
    }
  }

  private async onPause() {
    if (!this.neverShowPauseWarning) {
      this.showPauseWarning = true
      return
    }
    await this.performPause()
  }

  private async performPause() {
    const result = await FocusStore.endSessionByPause()
    if (result.ok) {
      promptAction.showToast({ message: 'Paused and saved' })
      this.isIdle = true
      this.showBreakEndPrompt = false
      this.showStartRestPrompt = false
      this.pendingStartRestPrompt = false
      if (this.restPromptTimeoutId !== -1) {
        clearTimeout(this.restPromptTimeoutId)
        this.restPromptTimeoutId = -1
      }
      await NotificationService.cancelRestInterval()
      this.nextRestDueAtMs = 0
      this.focusState = FocusStore.getState()
      await this.loadSessionDetails(this.pendingTaskId ?? this.focusState.currentTaskId ?? undefined)
    } else {
      promptAction.showToast({ message: result.message ?? 'Pause failed' })
    }
  }

  private async onStartBreak(autoEnd: boolean) {
    this.handleModeTransition(true)
    if (this.restPromptTimeoutId !== -1) {
      clearTimeout(this.restPromptTimeoutId)
      this.restPromptTimeoutId = -1
    }
    this.showStartRestPrompt = false
    this.pendingStartRestPrompt = false
    await NotificationService.cancelRestInterval()
    if (this.restDurationMs <= 0) {
      this.loadRestSettings()
    }
    const duration = this.restDurationMs
    const result = await FocusStore.startBreak(duration, undefined, autoEnd)
    if (result.ok) {
      promptAction.showToast({ message: 'Break started' })
      this.resetNextRestCountdown()
    } else {
      promptAction.showToast({ message: result.message ?? 'Break failed' })
    }
    this.focusState = FocusStore.getState()
  }

  private async onFinishBreak() {
    this.handleModeTransition(false)
    const result = await FocusStore.finishBreak()
    if (result.ok) {
      promptAction.showToast({ message: 'Break finished' })
      this.showBreakEndPrompt = false
      this.resetNextRestCountdown()
    } else {
      promptAction.showToast({ message: result.message ?? 'Finish break failed' })
    }
    this.focusState = FocusStore.getState()
  }

  private async onFinish() {
    const result = await FocusStore.finishFocus()
    if (result.ok) {
      promptAction.showToast({ message: 'Focus completed' })
      router.back()
      this.isIdle = true
      this.showBreakEndPrompt = false
      this.showStartRestPrompt = false
      this.pendingStartRestPrompt = false
      if (this.restPromptTimeoutId !== -1) {
        clearTimeout(this.restPromptTimeoutId)
        this.restPromptTimeoutId = -1
      }
      await NotificationService.cancelRestInterval()
      this.nextRestDueAtMs = 0
      await this.loadSessionDetails(this.pendingTaskId ?? this.focusState.currentTaskId ?? undefined)
    } else {
      promptAction.showToast({ message: result.message ?? 'Complete failed' })
    }
    this.focusState = FocusStore.getState()
  }

  private goBack() {
    if (this.focusState.currentSession && this.focusState.currentSession.status === SessionStatus.RUNNING) {
      this.showLeaveWarning = true
    } else {
      router.back()
    }
  }

  private getElapsedMs(): number {
    if (this.viewingOtherTask || !this.focusState.currentSession) {
      return 0
    }
    const base = this.focusState.currentSession.actualFocusDuration ?? 0
    return base + this.focusState.elapsedTime
  }

  private getRestCount(): number {
    if (this.viewingOtherTask) {
      return 0
    }
    return this.focusState.currentSession?.breakCount ?? 0
  }

  private getTotalRestTime(): number {
    if (this.viewingOtherTask || !this.focusState.currentSession) {
      return 0
    }
    const total = this.focusState.currentSession.restDurationMs ?? 0
    return this.focusState.isBreaking ? total + this.focusState.breakElapsedTime : total
  }

  private isRunning(): boolean {
    if (this.viewingOtherTask) {
      return false
    }
    return this.focusState.currentSession?.status === SessionStatus.RUNNING
  }

  private getProgress(): number {
    if (this.viewingOtherTask) {
      return 0
    }
    if (this.focusState.currentSession && this.focusState.currentSession.sessionType === SessionType.COUNTDOWN && this.focusState.currentSession.timeLimitMs) {
      return Math.min(this.getElapsedMs() / this.focusState.currentSession.timeLimitMs, 1)
    }
    return 0
  }

  private getDisplayTime(): string {
    if (this.viewingOtherTask) {
      return this.formatTime(0)
    }
    if (this.focusState.isBreaking) {
      if (this.focusState.breakAutoEnd) {
        const remaining = Math.max(0, this.focusState.breakDuration - this.focusState.breakElapsedTime)
        return this.formatTime(remaining)
      }
      return this.formatTime(this.focusState.breakElapsedTime)
    }
    const remaining = this.focusState.remainingTime > 0 ? this.focusState.remainingTime : this.getElapsedMs()
    return this.formatTime(remaining)
  }

  private getSecondaryFocusInfo(): string {
    if (this.viewingOtherTask) {
      return `Focus time: ${this.formatTime(0)}`
    }
    const session = this.focusState.currentSession
    if (session && session.sessionType === SessionType.COUNTDOWN && session.timeLimitMs) {
      return `Time left: ${this.formatTime(Math.max(this.focusState.remainingTime, 0))}`
    }
    return `Focus time: ${this.formatTime(this.getElapsedMs())}`
  }

  private handleModeTransition(nextIsBreaking: boolean) {
    if (this.isModeAnimating) {
      return
    }
    if (nextIsBreaking === this.displayIsBreaking) {
      return
    }
    if (this.modeTransitionTimer !== -1) {
      clearTimeout(this.modeTransitionTimer)
    }
    this.isModeAnimating = true
    this.modeTransitionTimer = setTimeout(() => {
      this.displayIsBreaking = nextIsBreaking
      this.isModeAnimating = false
      this.modeTransitionTimer = -1
    }, 300)
  }

  private async loadSessionDetails(taskId?: number) {
    const targetId = taskId ?? this.focusState.currentTaskId ?? this.pendingTaskId ?? null
    if (targetId === null || targetId === undefined) {
      this.sessionDetails = []
      return
    }

    const sessionsResult = await SessionRepo.findByTaskId(getContext(this), targetId)
    if (!sessionsResult.ok || !sessionsResult.data) {
      this.sessionDetails = []
      return
    }

    const summaries: SessionSummary[] = []
    let completedFocus = 0
    for (const session of sessionsResult.data) {
      let restDuration = 0
      const breaksResult = await BreakRepo.findBySessionId(getContext(this), session.id)
      if (breaksResult.ok && breaksResult.data) {
        restDuration = breaksResult.data.reduce((sum, b) => sum + (b.actualDuration ?? 0), 0)
      }
      if (session.status === SessionStatus.FINISHED) {
        completedFocus += session.actualFocusDuration
      }
      summaries.push({
        id: session.id,
        date: session.startAt,
        focusDuration: session.actualFocusDuration,
        restDuration: restDuration,
        status: session.status
      })
    }
    this.sessionDetails = summaries
    this.completedFocusOffset = completedFocus
  }

  private formatSessionDate(ts: number): string {
    const d = new Date(ts)
    const y = d.getFullYear()
    const m = (d.getMonth() + 1).toString().padStart(2, '0')
    const day = d.getDate().toString().padStart(2, '0')
    const h = d.getHours().toString().padStart(2, '0')
    const mi = d.getMinutes().toString().padStart(2, '0')
    return `${y}-${m}-${day} ${h}:${mi}`
  }

  build() {
    Stack() {
      Column() {
        Row({ space: 12 }) {
          Text('←')
            .fontSize(24)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .onClick(() => {
              this.goBack()
            })
          Text(this.taskTitle)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(60)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({ width: { bottom: 1 }, color: Theme.COLOR_BORDER })

        if (this.taskDescription !== '') {
          Column() {
            Text('描述')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
            Text(this.taskDescription)
              .fontSize(13)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .margin({ left: 16, right: 16, top: 12 })
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .shadow({
            radius: 4,
            color: '#0000000A',
            offsetX: 0,
            offsetY: 2
          })
        }

        Column({ space: 24 }) {
          Column() {
            Stack() {
              // 外层蓝紫色环
              Circle()
                .width(300)
                .height(300)
                .fill(Color.Transparent)
                .stroke(this.displayIsBreaking ? '#FFE8D8' : '#E4E0F8')
                .strokeWidth(20)

              // 内层白色圆
              Circle()
                .width(260)
                .height(260)
                .fill('#FFFFFF')

              if (this.getProgress() > 0) {
                Progress({
                  value: this.getProgress() * 100,
                  total: 100,
                  type: ProgressType.Ring
                })
                  .width(290)
                  .height(290)
                  .color(this.displayIsBreaking ? '#F97316' : '#3B82F6')
                  .style({ strokeWidth: 6 })
              }

              Column({ space: 4 }) {
                Column({ space: 4 }) {
                  if (this.displayIsBreaking) {
                    Column({ space: 4 }) {
                      Text('休息中')
                        .fontSize(14)
                        .fontColor(Theme.COLOR_WARNING)
                      Text(this.getDisplayTime())
                        .fontSize(48)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    }
                  } else {
                    Column({ space: 4 }) {
                      Text('专注时间')
                        .fontSize(14)
                        .fontColor(Theme.COLOR_TEXT_SECONDARY)
                      Text(this.getDisplayTime())
                        .fontSize(48)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    }
                  }
                }
                .opacity(this.isModeAnimating ? 0 : 1)
                .animation({ duration: 300, curve: Curve.EaseInOut })

                if (this.displayIsBreaking) {
                  Column({ space: 2 }) {
                    Text(this.getSecondaryFocusInfo())
                      .fontSize(12)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                    Text(`总专注: ${this.formatTime(this.completedFocusOffset + this.getElapsedMs())}`)
                      .fontSize(12)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  }
                } else {
                  Column({ space: 2 }) {
                    if (this.allowRest && this.restIntervalMs > 0 && !this.viewingOtherTask) {
                      Text(`下次休息: ${this.formatTime(this.getNextRestRemainingMs())}`)
                        .fontSize(12)
                        .fontColor(Theme.COLOR_TEXT_TERTIARY)
                    } else {
                      Text('')
                        .fontSize(12)
                        .fontColor(Theme.COLOR_TEXT_TERTIARY)
                    }
                    Text(`总专注: ${this.formatTime(this.completedFocusOffset + this.getElapsedMs())}`)
                      .fontSize(12)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  }
                }
              }
            }
            .margin({ top: 20 })
            .align(Alignment.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          if (this.isIdle || !this.focusState.currentSession) {
            Column({ space: 16 }) {
              // 倒计时模式切换
              Row({ space: 8 }) {
                Toggle({ type: ToggleType.Switch, isOn: this.isCountdownMode })
                  .selectedColor(Theme.COLOR_PRIMARY)
                  .width(44)
                  .height(24)
                  .onChange((isOn: boolean) => {
                    this.isCountdownMode = isOn
                  })
                Text('倒计时模式')
                  .fontSize(14)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)

                if (this.isCountdownMode) {
                  Row({ space: 6 }) {
                    Button({ type: ButtonType.Circle }) {
                      Text('-').fontSize(16).fontColor(Theme.COLOR_TEXT_SECONDARY)
                    }
                    .width(32)
                    .height(32)
                    .backgroundColor(Theme.COLOR_BACKGROUND)
                    .onClick(() => {
                      if (this.countdownMinutes > 1) {
                        this.countdownMinutes -= 1
                      }
                    })
                    Text(`${this.countdownMinutes}`)
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.COLOR_TEXT_PRIMARY)
                      .width(36)
                      .textAlign(TextAlign.Center)
                    Button({ type: ButtonType.Circle }) {
                      Text('+').fontSize(16).fontColor(Theme.COLOR_TEXT_SECONDARY)
                    }
                    .width(32)
                    .height(32)
                    .backgroundColor(Theme.COLOR_BACKGROUND)
                    .onClick(() => {
                      this.countdownMinutes += 1
                    })
                    Text('分钟')
                      .fontSize(12)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  }
                }
              }
              .padding({ left: 20, right: 20 })
              .justifyContent(FlexAlign.Center)

              // 启动按钮
              Button('开始专注')
                .width('90%')
                .height(52)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .backgroundColor(Theme.COLOR_PRIMARY)
                .borderRadius(26)
                .shadow({ radius: 16, color: '#2563EB30', offsetX: 0, offsetY: 4 })
                .onClick(() => {
                  this.startSession()
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          } else if (this.focusState.isBreaking) {
            Button('结束休息')
              .width('90%')
              .height(52)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(Theme.COLOR_WARNING)
              .borderRadius(26)
              .shadow({ radius: 16, color: '#F9731630', offsetX: 0, offsetY: 4 })
              .onClick(() => {
                this.onFinishBreak()
              })
          } else {
            Column({ space: 16 }) {
              Row({ space: 12 }) {
                // Rest 按钮
                if (this.allowRest) {
                  Button({ type: ButtonType.Circle }) {
                    Text('☕').fontSize(20)
                  }
                  .width(52)
                  .height(52)
                  .backgroundColor(Theme.COLOR_BACKGROUND)
                  .onClick(() => {
                    void this.onStartBreak(false)
                  })
                }

                // Pause 按钮
                Button({ type: ButtonType.Circle }) {
                  Text('⏸️').fontSize(18)
                }
                .width(52)
                .height(52)
                .backgroundColor(Theme.COLOR_BACKGROUND)
                .onClick(() => {
                  if (this.isRunning()) {
                    this.onPause()
                  }
                })

                // Complete 按钮
                Button('完成')
                  .layoutWeight(1)
                  .height(52)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                  .backgroundColor(Theme.COLOR_PRIMARY)
                  .borderRadius(26)
                  .shadow({ radius: 12, color: '#2563EB30', offsetX: 0, offsetY: 4 })
                  .onClick(() => {
                    this.onFinish()
                  })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }

          // 统计卡片 - Rest Count 和 Rest Time
          if (this.allowRest) {
            Row() {
              Row({ space: 8 }) {
                Text('休息次数:')
                  .fontSize(14)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                Text(this.getRestCount().toString())
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)

              Divider()
                .vertical(true)
                .height(20)
                .color(Theme.COLOR_BORDER)

              Row({ space: 8 }) {
                Text('休息时长:')
                  .fontSize(14)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                Text(this.formatTime(this.getTotalRestTime()))
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 14, bottom: 14 })
            .margin({ left: 16, right: 16 })
            .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
            .borderRadius(14)
            .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 })
          }

          // Focus Sessions 卡片
          Row({ space: 8 }) {
            Text('专注次数:')
              .fontSize(14)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
            Text(this.sessionDetails.length.toString())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_PRIMARY)
            Blank()
            Button('查看详情')
              .fontSize(13)
              .height(32)
              .backgroundColor(Theme.COLOR_PRIMARY_BG)
              .fontColor(Theme.COLOR_PRIMARY)
              .borderRadius(16)
              .onClick(() => {
                this.openSessionDetails()
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .margin({ left: 16, right: 16 })
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(14)
          .shadow({ radius: 4, color: '#0000000A', offsetX: 0, offsetY: 2 })
        }
        .layoutWeight(1)
        .backgroundColor(Theme.COLOR_BACKGROUND)
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .height('100%')

      if (this.showPauseWarning) {
        this.PauseWarningDialog()
      }

      if (this.showStartRestPrompt) {
        this.StartRestDialog()
      }

      if (this.showBreakEndPrompt) {
        this.BreakEndDialog()
      }

      if (this.showLeaveWarning) {
        this.LeaveWarningDialog()
      }

      if (this.showActiveTaskWarning) {
        this.ActiveTaskDialog()
      }

      if (this.showTaskLoadError) {
        this.TaskLoadErrorDialog()
      }

      if (this.sessionSheetVisible) {
        this.SessionDetailsDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StartRestDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Text('休息时间到了')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('休息间隔已到，开始休息或跳过。')
        .fontSize(14)
        .fontColor('#6B7280')

      Row({ space: 12 }) {
        Button('跳过休息')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(16)
          .onClick(() => {
            this.showStartRestPrompt = false
            this.pendingStartRestPrompt = false
            void NotificationService.cancelRestInterval()
            this.resetNextRestCountdown()
          })

        Button('开始休息')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#2F54EB')
          .fontColor(Color.White)
          .borderRadius(16)
          .onClick(async () => {
            this.showStartRestPrompt = false
            await this.onStartBreak(true)
          })
      }
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '35%' })
  }

  @Builder
  BreakEndDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Text('休息结束')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('点击确认继续专注。')
        .fontSize(14)
        .fontColor('#6B7280')

      Button('确认')
        .width('100%')
        .height(48)
        .backgroundColor('#2F54EB')
        .fontColor(Color.White)
        .borderRadius(16)
        .onClick(async () => {
          await this.onFinishBreak()
        })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '35%' })
  }

  @Builder
  PauseWarningDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          this.showPauseWarning = false
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Text('暂停任务')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('暂停将结束并保存此次专注。')
        .fontSize(14)
        .fontColor('#6B7280')

      Row({ space: 8 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.neverShowPauseWarning })
          .selectedColor('#2F54EB')
          .onChange((checked: boolean) => {
            this.neverShowPauseWarning = checked
          })
        Text('不再显示')
          .fontSize(12)
          .fontColor('#4B5563')
      }

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(16)
          .onClick(() => {
            this.showPauseWarning = false
          })

        Button('暂停并保存')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#EF4444')
          .fontColor(Color.White)
          .borderRadius(16)
          .onClick(async () => {
            this.showPauseWarning = false
            await this.performPause()
          })
      }
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '35%' })
  }

  @Builder
  LeaveWarningDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          this.showLeaveWarning = false
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Text('离开任务')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('离开将暂停并保存当前专注。')
        .fontSize(14)
        .fontColor('#6B7280')

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(16)
          .onClick(() => {
            this.showLeaveWarning = false
          })

        Button('离开')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#EF4444')
          .fontColor(Color.White)
          .borderRadius(16)
          .onClick(async () => {
            this.showLeaveWarning = false
            await FocusStore.endSessionByPause()
            this.isIdle = true
            router.back()
          })
      }
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '35%' })
  }

  @Builder
  ActiveTaskDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          this.showActiveTaskWarning = false
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Text('活动任务警告')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('另一个任务正在进行中。请先暂停或完成它再开始新的专注。')
        .fontSize(14)
        .fontColor('#6B7280')

      Button('确定')
        .width('100%')
        .height(48)
        .backgroundColor('#2F54EB')
        .fontColor(Color.White)
        .borderRadius(16)
        .onClick(() => {
          this.showActiveTaskWarning = false
        })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '35%' })
  }

  @Builder
  TaskLoadErrorDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          this.showTaskLoadError = false
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Text('任务加载错误')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text(this.taskLoadErrorMessage)
        .fontSize(14)
        .fontColor('#6B7280')

      Button('确定')
        .width('100%')
        .height(48)
        .backgroundColor('#2F54EB')
        .fontColor(Color.White)
        .borderRadius(16)
        .onClick(() => {
          this.showTaskLoadError = false
          router.back()
        })
    }
    .width('85%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '35%' })
  }

  @Builder
  SessionDetailsDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .opacity(this.sessionSheetOpacity)
        .animation({ duration: 220, curve: Curve.EaseInOut })
        .onClick(() => {
          this.closeSessionDetails()
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 12 }) {
      Row() {
        Text('专注详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        Button('关闭')
          .fontSize(14)
          .height(32)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(16)
          .onClick(() => {
            this.closeSessionDetails()
          })
      }

      if (this.sessionDetails.length === 0) {
        Text('暂无已完成的专注。')
          .fontSize(13)
          .fontColor('#6B7280')
      } else {
        List({ space: 8 }) {
          ForEach(this.sessionDetails, (item: SessionSummary) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(this.formatSessionDate(item.date))
                  .fontSize(13)
                  .fontColor('#6B7280')
                      Row({ space: 12 }) {
                        Text(`专注: ${item.status === SessionStatus.FINISHED ? this.formatTime(item.focusDuration) : '进行中'}`)
                          .fontSize(14)
                          .fontColor('#111827')
                        Text(`休息: ${item.status === SessionStatus.FINISHED ? this.formatTime(item.restDuration) : '进行中'}`)
                          .fontSize(14)
                          .fontColor('#111827')
                      }
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
              .borderRadius(12)
              .shadow({ radius: 4, color: '#1118270f', offsetX: 0, offsetY: 1 })
            }
          }, (item: SessionSummary) => item.id.toString())
        }
        .width('100%')
        .height(320)
      }
    }
    .width('100%')
    .height('60%')
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: 0, y: '40%' })
    .translate({ x: 0, y: this.sessionSheetOffset })
    .animation({ duration: 260, curve: Curve.EaseInOut })
  }

  private openSessionDetails() {
    if (this.sessionSheetVisible) {
      return
    }
    this.sessionSheetOffset = 500
    this.sessionSheetOpacity = 0
    this.sessionSheetVisible = true
    setTimeout(() => {
      this.sessionSheetOffset = 0
      this.sessionSheetOpacity = 1
    }, 10)
  }

  private closeSessionDetails() {
    if (!this.sessionSheetVisible) {
      return
    }
    this.sessionSheetOffset = 500
    this.sessionSheetOpacity = 0
    setTimeout(() => {
      this.sessionSheetVisible = false
    }, 260)
  }

  onBackPress(): boolean {
    this.goBack()
    return true
  }
}
