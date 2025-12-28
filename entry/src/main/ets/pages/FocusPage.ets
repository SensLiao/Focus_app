/**
 * Timer page - 精致现代风格 (Inspired by Flocus)
 */
import router from '@ohos.router'
import inputMethod from '@ohos.inputMethod'
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
import { SuccessAnimation } from '../components/SuccessAnimation'

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
  @State countdownInput: string = '25'
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
  @State isFinishing: boolean = false
  @StorageLink('breakEndPromptPending') pendingBreakEndPrompt: boolean = false
  @StorageLink('startRestPromptPending') pendingStartRestPrompt: boolean = false
  @State restIntervalMs: number = 0
  @State restDurationMs: number = 0
  @State restEnabled: boolean = true
  @State nextRestDueAtMs: number = 0
  // 动画相关状态
  @State showSuccessAnimation: boolean = false
  @State successAnimationType: 'create' | 'complete' = 'complete'
  @State successMessage: string = ''
  @State timerScale: number = 1
  @State headerOpacity: number = 0
  @State contentOpacity: number = 0
  private timerInterval: number = -1
  private restPromptTimeoutId: number = -1
  private lifecycleListener: ((event: 'foreground' | 'background' | 'destroy') => void) | null = null
  private modeTransitionTimer: number = -1

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))
    this.loadRestSettings()
    // 入场动画
    this.headerOpacity = 0
    this.contentOpacity = 0
    setTimeout(() => {
      this.headerOpacity = 1
    }, 100)
    setTimeout(() => {
      this.contentOpacity = 1
    }, 200)
    await TaskStore.loadTasks()

    const params = router.getParams() as RouterParams
    this.pendingTaskId = params?.pendingTaskId ?? null
    this.startAnonymous = params?.startAnonymous === true

    this.focusState = FocusStore.getState()
    this.displayIsBreaking = this.focusState.isBreaking
    this.countdownInput = this.countdownMinutes.toString()
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

  onPageShow() {
    this.focusState = FocusStore.getState()
    this.displayIsBreaking = this.focusState.isBreaking
    if (this.focusState.currentSession) {
      this.syncTaskMeta()
    }
    this.headerOpacity = 1
    this.contentOpacity = 1
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
    this.restIntervalMs = Math.max(0, settings.defaultRestInterval) * 60 * 1000
    this.restDurationMs = Math.max(0, settings.defaultRestDuration) * 60 * 1000
    this.restEnabled = settings.restEnabled
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
    if (this.isFinishing) {
      return
    }
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
    if (this.isFinishing) {
      return
    }
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
    if (this.isFinishing) {
      return
    }
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
    if (this.isFinishing) {
      return
    }
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
    if (this.isFinishing) {
      return
    }
    // Show feedback immediately, but wait for completion before leaving.
    this.isFinishing = true
    this.successAnimationType = 'complete'
    this.successMessage = `Great job! Completed ${this.formatTime(this.getElapsedMs())} focus.`
    this.showSuccessAnimation = true

    await new Promise<void>((resolve) => setTimeout(resolve, 0))
    const finishPromise = FocusStore.finishFocus()
    const animationDelay = new Promise<void>((resolve) => setTimeout(resolve, 2000))
    const result = await finishPromise
    if (result.ok) {
      await animationDelay
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
      this.showSuccessAnimation = false
      this.isFinishing = false
      promptAction.showToast({ message: result.message ?? 'Complete failed' })
    }
    this.focusState = FocusStore.getState()
  }



  private goBack() {
    if (this.isFinishing) {
      return
    }
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

  private getCurrentFocusMs(): number {
    if (this.viewingOtherTask || !this.focusState.currentSession) {
      return 0
    }
    const base = this.focusState.currentSession.actualFocusDuration ?? 0
    if (this.focusState.isBreaking || this.focusState.currentSession.status !== SessionStatus.RUNNING) {
      return base
    }
    return base + this.focusState.elapsedTime
  }

  private getTotalFocusMs(): number {
    return this.completedFocusOffset + this.getCurrentFocusMs()
  }

  private getSecondaryTimerLabel(): string {
    if (this.displayIsBreaking) {
      return `专注时长: ${this.formatTime(this.getCurrentFocusMs())}`
    }
    if (this.restIntervalMs > 0 && !this.viewingOtherTask && this.isRunning()) {
      return `下次休息: ${this.formatTime(this.getNextRestRemainingMs())}`
    }
    return ''
  }

  private getControlAreaHeight(): number {
    if (this.isIdle || !this.focusState.currentSession) {
      return 110
    }
    if (this.focusState.isBreaking) {
      return 60
    }
    return 60
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

  private hideKeyboard() {
    try {
      inputMethod.getController().hideTextInput()
    } catch (e) {
      // Ignore when keyboard is not available.
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏 - 更精致
        Row({ space: 16 }) {
          Button({ type: ButtonType.Circle }) {
            Text('←')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          .width(44)
          .height(44)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .translate({ x: 0, y: -2 })
          .onClick(() => {
            this.goBack()
          })

          Column({ space: 2 }) {
            Text(this.taskTitle || '专注时间')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text('')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_WARNING)
              .height(Theme.FONT_SIZE_SMALL + 4)
              .opacity(0)
          }
          .layoutWeight(1)
          .padding({ top: 8 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ left: 16, right: 20, top: 4, bottom: 0 })
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({ width: { bottom: 1 }, color: Theme.COLOR_BORDER })
        .opacity(this.headerOpacity)
        .animation({
          duration: Theme.ANIMATION_NORMAL,
          curve: Curve.EaseOut
        })

        Scroll() {
          Column() {
            Blank()
              .height(12)
            Column({ space: 24 }) {
              // 超大计时器显示区域
              Column() {
                Stack() {
              // 外层装饰环
              Circle()
                .width(320)
                .height(320)
                .fill(Color.Transparent)
                .stroke(this.displayIsBreaking ? '#FFF1E6' : Theme.COLOR_PRIMARY_BG)
                .strokeWidth(24)

              // 中层进度环背景
              Circle()
                .width(280)
                .height(280)
                .fill(Color.Transparent)
                .stroke(this.displayIsBreaking ? '#FFEDD5' : '#E9D5FF')
                .strokeWidth(8)

              // 进度环
              if (this.getProgress() > 0) {
                Progress({
                  value: this.getProgress() * 100,
                  total: 100,
                  type: ProgressType.Ring
                })
                  .width(280)
                  .height(280)
                  .color(this.displayIsBreaking ? Theme.COLOR_WARNING : Theme.COLOR_PRIMARY)
                  .style({ strokeWidth: 8 })
              }

              // 内层白色圆
              Circle()
                .width(240)
                .height(240)
                .fill(Theme.COLOR_CARD_BACKGROUND)
                .shadow(Theme.SHADOW_MEDIUM)

              // 时间和状态显示
              Column({ space: 8 }) {
                // 模式标签
                Row({ space: 6 }) {
                  Circle()
                    .width(10)
                    .height(10)
                    .fill(this.displayIsBreaking ? Theme.COLOR_WARNING :
                      (this.isRunning() ? Theme.COLOR_SUCCESS : Theme.COLOR_PRIMARY))
                  Text(this.displayIsBreaking ? '休息中' :
                    (this.isRunning() ? '专注中' : '准备开始'))
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(this.displayIsBreaking ? Theme.COLOR_WARNING :
                      (this.isRunning() ? Theme.COLOR_SUCCESS : Theme.COLOR_TEXT_SECONDARY))
                }
                .padding({ left: 14, right: 14, top: 6, bottom: 6 })
                .backgroundColor(this.displayIsBreaking ? Theme.COLOR_WARNING_BG :
                  (this.isRunning() ? Theme.COLOR_SUCCESS_BG : Theme.COLOR_BACKGROUND))
                .borderRadius(Theme.BORDER_RADIUS_FULL)

                // 超大时间数字
                Text(this.getDisplayTime())
                  .fontSize(Theme.FONT_SIZE_HERO)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                  .opacity(this.isModeAnimating ? 0.3 : 1)
                  .scale({ x: this.timerScale, y: this.timerScale })
                  .animation({
                    duration: Theme.ANIMATION_NORMAL,
                    curve: Curve.EaseInOut
                  })

                // 辅助信息
                Column({ space: 4 }) {
                  Text(`总专注: ${this.formatTime(this.getTotalFocusMs())}`)
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)

                  Text(this.getSecondaryTimerLabel() === '' ? ' ' : this.getSecondaryTimerLabel())
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    .opacity(this.getSecondaryTimerLabel() === '' ? 0 : 1)
                }
              }
            }
            .margin({ top: 0 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .opacity(this.contentOpacity)
          .animation({
            duration: Theme.ANIMATION_SLOW,
            curve: Curve.EaseOut
          })

          // 控制按钮区域
          Column() {
            if (this.isIdle || !this.focusState.currentSession) {
              Column({ space: 10 }) {
                // 倒计时模式切换
                Row() {
                  Row({ space: 12 }) {
                    Toggle({ type: ToggleType.Switch, isOn: this.isCountdownMode })
                      .selectedColor(Theme.COLOR_PRIMARY)
                      .width(52)
                      .height(28)
                      .enabled(!this.isFinishing)
                      .onChange((isOn: boolean) => {
                        this.isCountdownMode = isOn
                      })
                    Text('倒计时模式')
                      .fontSize(Theme.FONT_SIZE_MEDIUM)
                      .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  }

                if (this.isCountdownMode) {
                  Row({ space: 8 }) {
                    TextInput({ placeholder: '分钟', text: this.countdownInput })
                      .width(80)
                      .height(36)
                      .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                      .backgroundColor(Theme.COLOR_BACKGROUND)
                      .border({ width: 1, color: Theme.COLOR_BORDER })
                      .padding({ left: 8, right: 8 })
                      .textAlign(TextAlign.Center)
                      .fontSize(Theme.FONT_SIZE_MEDIUM)
                      .enabled(!this.isFinishing)
                      .onChange((value: string) => {
                        const digits = value.replace(/[^\d]/g, '')
                        this.countdownInput = digits
                        const minutes = Number(digits)
                        if (Number.isFinite(minutes) && minutes > 0) {
                          this.countdownMinutes = minutes
                        }
                      })
                    Text('分钟')
                      .fontSize(Theme.FONT_SIZE_SMALL)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  }
                }
                }
                .width('100%')
                .padding({ left: 12, right: 12 })
                .justifyContent(FlexAlign.SpaceBetween)

                // 启动按钮 - 更大更醒目
                Button('开始专注')
                  .width('85%')
                  .height(60)
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .backgroundColor(Theme.COLOR_PRIMARY)
                  .borderRadius(Theme.BORDER_RADIUS_XLARGE)
                  .shadow(Theme.SHADOW_GLOW)
                  .enabled(!this.isFinishing)
                  .onClick(() => {
                    this.startSession()
                  })
              }
              .width('100%')
              .padding({ left: 12, right: 12 })
            } else if (this.focusState.isBreaking) {
              Column() {
                Button('结束休息')
                  .width('85%')
                  .height(60)
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .backgroundColor(Theme.COLOR_WARNING)
                  .borderRadius(Theme.BORDER_RADIUS_XLARGE)
                  .shadow({
                    radius: 20,
                    color: '#F9731640',
                    offsetX: 0,
                    offsetY: 4
                  })
                  .enabled(!this.isFinishing)
                  .onClick(() => {
                    this.onFinishBreak()
                  })
              }
              .width('100%')
              .padding({ left: 12, right: 12 })
            } else {
              Column({ space: 9 }) {
                Row({ space: 14 }) {
                  if (this.restEnabled) {
                    // 休息按钮
                    Button({ type: ButtonType.Circle }) {
                      Text('☕').fontSize(24)
                    }
                    .width(60)
                    .height(60)
                    .backgroundColor(Theme.COLOR_WARNING_BG)
                    .enabled(!this.isFinishing)
                    .onClick(() => {
                      this.onStartBreak(false)
                    })
                  }

                  // 暂停按钮
                  Button({ type: ButtonType.Circle }) {
                    Text('⏸').fontSize(24)
                  }
                  .width(60)
                  .height(60)
                  .backgroundColor(Theme.COLOR_BACKGROUND)
                  .enabled(!this.isFinishing)
                  .onClick(() => {
                    if (this.isRunning()) {
                      this.onPause()
                    }
                  })

                  // 完成按钮 - 主要操作
                  Button('完成专注')
                    .layoutWeight(1)
                    .height(60)
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                    .backgroundColor(Theme.COLOR_PRIMARY)
                    .borderRadius(Theme.BORDER_RADIUS_XLARGE)
                    .shadow(Theme.SHADOW_GLOW)
                    .enabled(!this.isFinishing)
                    .onClick(() => {
                      this.onFinish()
                    })
                }
                .justifyContent(FlexAlign.Center)
              }
              .width('100%')
              .padding({ left: 20, right: 20 })
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('100%')
          .height(this.getControlAreaHeight())
          .justifyContent(FlexAlign.Start)
          .animation({
            duration: Theme.ANIMATION_NORMAL,
            curve: Curve.EaseInOut
          })

          // 统计卡片
          Row() {
            Column({ space: 4 }) {
              Text('休息次数')
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
              Text(this.getRestCount().toString())
                .fontSize(Theme.FONT_SIZE_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)

            Column()
              .width(1)
              .height(40)
              .backgroundColor(Theme.COLOR_BORDER)

            Column({ space: 4 }) {
              Text('休息时长')
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
              Text(this.formatTime(this.getTotalRestTime()))
                .fontSize(Theme.FONT_SIZE_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 18, bottom: 18 })
          .margin({ left: 16, right: 16, bottom: 0 })
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .shadow(Theme.SHADOW_SMALL)

          // 专注记录卡片
          Row({ space: 10 }) {
            Column() {
              Text('📊')
                .fontSize(24)
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .backgroundColor(Theme.COLOR_PRIMARY_BG)
            .justifyContent(FlexAlign.Center)

            Column({ space: 2 }) {
              Text('专注记录')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
              Text(`共 ${this.sessionDetails.length} 次专注`)
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button('查看')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .height(36)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .fontColor(Color.White)
              .borderRadius(Theme.BORDER_RADIUS_FULL)
              .padding({ left: 18, right: 18 })
              .onClick(() => {
                this.openSessionDetails()
              })
          }
          .width('100%')
          .padding({ left: 18, right: 18, top: 16, bottom: 16 })
          .margin({ left: 16, right: 16, top: 0 })
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .shadow(Theme.SHADOW_SMALL)
            }
          }
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .width('100%')
          .padding({ left: 0, right: 0, bottom: 0 })
        }
        .layoutWeight(1)
        .width('100%')
      }
      .width('100%')
      .height('100%')

      // 成功动画
      SuccessAnimation({
        visible: $showSuccessAnimation,
        type: this.successAnimationType,
        message: this.successMessage
      })

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

      if (this.isFinishing) {
        Column() {
          LoadingProgress()
            .width(52)
            .height(52)
            .color(Theme.COLOR_TEXT_ON_PRIMARY)
          Text('处理中...')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_ON_PRIMARY)
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#555555CC')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {})
      }
    }
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.hideKeyboard()
      }
    })
    .width('100%')
    .height('100%')
  }

  @Builder
  StartRestDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)

      Column({ space: Theme.SPACE_MEDIUM }) {
      // 图标
      Column() {
        Text('☕')
          .fontSize(48)
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(Theme.COLOR_WARNING_BG)
      .justifyContent(FlexAlign.Center)

      Text('休息时间到了')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('适当休息能让你更加专注高效！')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)

      Row({ space: 14 }) {
        Button('跳过')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .onClick(() => {
            this.showStartRestPrompt = false
            this.pendingStartRestPrompt = false
            void NotificationService.cancelRestInterval()
            this.resetNextRestCountdown()
          })

        Button('开始休息')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_WARNING)
          .fontColor(Color.White)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .onClick(async () => {
            this.showStartRestPrompt = false
            await this.onStartBreak(true)
          })
      }
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
  BreakEndDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)

      Column({ space: Theme.SPACE_MEDIUM }) {
      Column() {
        Text('⏰')
          .fontSize(48)
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(Theme.COLOR_PRIMARY_BG)
      .justifyContent(FlexAlign.Center)

      Text('休息结束')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('准备好继续专注了吗？')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)

      Button('继续专注')
        .width('100%')
        .height(52)
        .fontSize(Theme.FONT_SIZE_MEDIUM)
        .backgroundColor(Theme.COLOR_PRIMARY)
        .fontColor(Color.White)
        .borderRadius(Theme.BORDER_RADIUS_LARGE)
        .shadow(Theme.SHADOW_GLOW)
        .onClick(async () => {
          await this.onFinishBreak()
        })
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
  PauseWarningDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {
          this.showPauseWarning = false
        })

      Column({ space: Theme.SPACE_MEDIUM }) {
      Column() {
        Text('⏸')
          .fontSize(48)
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(Theme.COLOR_ERROR_BG)
      .justifyContent(FlexAlign.Center)

      Text('暂停专注')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('暂停将结束并保存此次专注记录。')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)

      Row({ space: 10 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.neverShowPauseWarning })
          .selectedColor(Theme.COLOR_PRIMARY)
          .onChange((checked: boolean) => {
            this.neverShowPauseWarning = checked
          })
        Text('不再显示')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontColor(Theme.COLOR_TEXT_TERTIARY)
      }

      Row({ space: 14 }) {
        Button('取消')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .onClick(() => {
            this.showPauseWarning = false
          })

        Button('暂停')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_ERROR)
          .fontColor(Color.White)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .onClick(async () => {
            this.showPauseWarning = false
            await this.performPause()
          })
      }
    }
    .width('85%')
    .padding(Theme.SPACE_XLARGE)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_XLARGE)
    .shadow(Theme.SHADOW_LARGE)
    .position({ x: '7.5%', y: '28%' })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  LeaveWarningDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {
          this.showLeaveWarning = false
        })

      Column({ space: Theme.SPACE_MEDIUM }) {
      Column() {
        Text('🚪')
          .fontSize(48)
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(Theme.COLOR_WARNING_BG)
      .justifyContent(FlexAlign.Center)

      Text('离开专注')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('离开将暂停并保存当前专注记录。')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)

      Row({ space: 14 }) {
        Button('取消')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .onClick(() => {
            this.showLeaveWarning = false
          })

        Button('离开')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_ERROR)
          .fontColor(Color.White)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .onClick(async () => {
            this.showLeaveWarning = false
            await FocusStore.endSessionByPause()
            this.isIdle = true
            router.back()
          })
      }
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
  ActiveTaskDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {
          this.showActiveTaskWarning = false
        })

      Column({ space: Theme.SPACE_MEDIUM }) {
      Column() {
        Text('⚠️')
          .fontSize(48)
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(Theme.COLOR_WARNING_BG)
      .justifyContent(FlexAlign.Center)

      Text('任务进行中')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('另一个任务正在进行中。\n请先完成或暂停它再开始新的专注。')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)
        .lineHeight(24)

      Button('我知道了')
        .width('100%')
        .height(52)
        .fontSize(Theme.FONT_SIZE_MEDIUM)
        .backgroundColor(Theme.COLOR_PRIMARY)
        .fontColor(Color.White)
        .borderRadius(Theme.BORDER_RADIUS_LARGE)
        .onClick(() => {
          this.showActiveTaskWarning = false
        })
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
  TaskLoadErrorDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {
          this.showTaskLoadError = false
        })

      Column({ space: Theme.SPACE_MEDIUM }) {
      Column() {
        Text('❌')
          .fontSize(48)
      }
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor(Theme.COLOR_ERROR_BG)
      .justifyContent(FlexAlign.Center)

      Text('加载失败')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text(this.taskLoadErrorMessage)
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Button('返回')
        .width('100%')
        .height(52)
        .fontSize(Theme.FONT_SIZE_MEDIUM)
        .backgroundColor(Theme.COLOR_PRIMARY)
        .fontColor(Color.White)
        .borderRadius(Theme.BORDER_RADIUS_LARGE)
        .onClick(() => {
          this.showTaskLoadError = false
          router.back()
        })
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
  SessionDetailsDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Theme.COLOR_OVERLAY)
        .opacity(this.sessionSheetOpacity)
        .animation({ duration: 220, curve: Curve.EaseInOut })
        .onClick(() => {
          this.closeSessionDetails()
        })

      Column({ space: Theme.SPACE_MEDIUM }) {
      Row() {
        Text('专注详情')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
        Blank()
        Button({ type: ButtonType.Circle }) {
          Text('✕')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .width(40)
        .height(40)
        .backgroundColor(Theme.COLOR_BACKGROUND)
        .onClick(() => {
          this.closeSessionDetails()
        })
      }

      if (this.sessionDetails.length === 0) {
        Column({ space: 12 }) {
          Text('📭')
            .fontSize(48)
          Text('暂无专注记录')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 10 }) {
          ForEach(this.sessionDetails, (item: SessionSummary) => {
            ListItem() {
              Row({ space: 14 }) {
                Column() {
                  Text(item.status === SessionStatus.FINISHED ? '✓' : '⏳')
                    .fontSize(20)
                    .fontColor(item.status === SessionStatus.FINISHED ? Theme.COLOR_SUCCESS : Theme.COLOR_WARNING)
                }
                .width(44)
                .height(44)
                .borderRadius(22)
                .backgroundColor(item.status === SessionStatus.FINISHED ? Theme.COLOR_SUCCESS_BG : Theme.COLOR_WARNING_BG)
                .justifyContent(FlexAlign.Center)

                Column({ space: 4 }) {
                  Text(this.formatSessionDate(item.date))
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  Row({ space: 16 }) {
                    Text(`专注 ${item.status === SessionStatus.FINISHED ? this.formatTime(item.focusDuration) : '进行中'}`)
                      .fontSize(Theme.FONT_SIZE_MEDIUM)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    Text(`休息 ${item.status === SessionStatus.FINISHED ? this.formatTime(item.restDuration) : '-'}`)
                      .fontSize(Theme.FONT_SIZE_MEDIUM)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')
              .padding({ left: 14, right: 14, top: 12, bottom: 12 })
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
              .shadow(Theme.SHADOW_SMALL)
            }
          }, (item: SessionSummary) => item.id.toString())
        }
        .width('100%')
        .height(340)
      }
      }
      .width('100%')
      .height('60%')
      .padding(Theme.SPACE_LARGE)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .borderRadius({ topLeft: Theme.BORDER_RADIUS_XLARGE, topRight: Theme.BORDER_RADIUS_XLARGE })
      .shadow(Theme.SHADOW_LARGE)
      .position({ x: 0, y: '40%' })
      .translate({ x: 0, y: this.sessionSheetOffset })
      .animation({ duration: 260, curve: Curve.EaseInOut })
    }
    .width('100%')
    .height('100%')
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
