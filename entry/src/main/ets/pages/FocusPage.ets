/**
 * Timer page - adapted to sample_frontend layout & flow
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { FocusStore, FocusState } from '../store/focusStore'
import { TaskStore } from '../store/taskStore'
import { SessionStatus } from '../model/SessionStatus'
import { SessionType } from '../model/FocusSession'
import { SessionRepo } from '../data/SessionRepo'
import { BreakRepo } from '../data/BreakRepo'
import { SettingsService } from '../services/SettingsService'

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
  private timerInterval: number = -1

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))
    await SettingsService.init(getContext(this))
    await TaskStore.loadTasks()

    const params = router.getParams() as RouterParams
    this.pendingTaskId = params?.pendingTaskId ?? null
    this.startAnonymous = params?.startAnonymous === true

    this.focusState = FocusStore.getState()
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
  }

  aboutToDisappear() {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
      this.timerInterval = -1
    }
  }

  private startTimer() {
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
    }
    this.timerInterval = setInterval(() => {
      this.focusState = FocusStore.getState()
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

  private async startSession() {
    const timeLimitMs = this.isCountdownMode ? this.countdownMinutes * 60 * 1000 : undefined
    const sessionType = this.isCountdownMode ? SessionType.COUNTDOWN : SessionType.NORMAL

    const result = await FocusStore.startFocus(this.pendingTaskId ?? undefined, timeLimitMs, sessionType)
    if (result.ok) {
      this.focusState = FocusStore.getState()
      if (!this.syncTaskMeta()) {
        return
      }
      this.startTimer()
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
      this.focusState = FocusStore.getState()
      await this.loadSessionDetails(this.pendingTaskId ?? this.focusState.currentTaskId ?? undefined)
    } else {
      promptAction.showToast({ message: result.message ?? 'Pause failed' })
    }
  }

  private async onResume() {
    const result = await FocusStore.resumeFocus()
    if (result.ok) {
      promptAction.showToast({ message: 'Resumed' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Resume failed' })
    }
    this.focusState = FocusStore.getState()
  }

  private async onStartBreak() {
    const settings = SettingsService.getSettings()
    const duration = settings.defaultRestDuration * 60 * 1000
    const result = await FocusStore.startBreak(duration)
    if (result.ok) {
      promptAction.showToast({ message: 'Break started' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Break failed' })
    }
    this.focusState = FocusStore.getState()
  }

  private async onFinishBreak() {
    const result = await FocusStore.finishBreak()
    if (result.ok) {
      promptAction.showToast({ message: 'Break finished' })
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
      return this.formatTime(this.focusState.breakElapsedTime)
    }
    const remaining = this.focusState.remainingTime > 0 ? this.focusState.remainingTime : this.getElapsedMs()
    return this.formatTime(remaining)
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
          Text('<')
            .fontSize(24)
            .fontColor('#111827')
            .onClick(() => {
              this.goBack()
            })
          Text(this.taskTitle)
            .fontSize(22)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111827')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(64)
        .padding({ left: 16, right: 16 })
        .alignItems(VerticalAlign.Center)
        .backgroundColor(Color.White)
        .border({ width: { bottom: 1 }, color: '#E5E7EB' })

        if (this.taskDescription !== '') {
          Column() {
            Text('Description')
              .fontSize(14)
              .fontColor('#374151')
            Text(this.taskDescription)
              .fontSize(13)
              .fontColor('#6B7280')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 14, bottom: 14 })
          .backgroundColor(Color.White)
          .border({ width: { bottom: 1 }, color: '#E5E7EB' })
        }

        Column({ space: 24 }) {
          Column() {
            Stack() {
              Circle()
                .width(280)
                .height(280)
                .fill('#EEF2FF')
                .shadow({ radius: 18, color: '#3B66F520', offsetX: 0, offsetY: 8 })

              if (this.getProgress() > 0) {
                Progress({
                  value: this.getProgress() * 100,
                  total: 100,
                  type: ProgressType.Ring
                })
                  .width(280)
                  .height(280)
                  .color('#2F54EB')
                  .style({ strokeWidth: 8 })
              }

              Column({ space: 8 }) {
                Text(this.viewingOtherTask ? 'Focus time' : (this.focusState.isBreaking ? 'Resting' : 'Focus time'))
                  .fontSize(15)
                  .fontColor('#6B7280')
                Text(this.getDisplayTime())
                  .fontSize(64)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#111827')
                Text(`Total focus: ${this.formatTime(this.completedFocusOffset + this.getElapsedMs())}`)
                  .fontSize(12)
                  .fontColor('#9CA3AF')
              }
            }
            .margin({ top: 24 })
            .align(Alignment.Center)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          if (this.isIdle || !this.focusState.currentSession) {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                Toggle({ type: ToggleType.Switch, isOn: this.isCountdownMode })
                  .selectedColor('#2F54EB')
                  .onChange((isOn: boolean) => {
                    this.isCountdownMode = isOn
                  })
                Text('Countdown Mode')
                  .fontSize(15)
                  .fontColor('#111827')

                if (this.isCountdownMode) {
                  Row({ space: 8 }) {
                    Button('-')
                      .width(36)
                      .height(36)
                      .backgroundColor('#F3F4F6')
                      .onClick(() => {
                        if (this.countdownMinutes > 1) {
                          this.countdownMinutes -= 1
                        }
                      })
                    Text(`${this.countdownMinutes} min`)
                      .fontSize(14)
                      .fontColor('#111827')
                    Button('+')
                      .width(36)
                      .height(36)
                      .backgroundColor('#F3F4F6')
                      .onClick(() => {
                        this.countdownMinutes += 1
                      })
                  }
                }
              }
              .padding({ left: 24, right: 24 })

              Button('Start Focus Session')
                .width('100%')
                .height(56)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .backgroundColor('#2F54EB')
                .borderRadius(28)
                .shadow({ radius: 12, color: '#2F54EB40', offsetX: 0, offsetY: 4 })
                .onClick(() => {
                  this.startSession()
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          } else if (this.focusState.isBreaking) {
            Button('End Break')
              .width('100%')
              .height(56)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor('#2F54EB')
              .borderRadius(28)
              .shadow({ radius: 12, color: '#2F54EB40', offsetX: 0, offsetY: 4 })
              .onClick(() => {
                this.onFinishBreak()
              })
              .padding({ left: 16, right: 16 })
          } else {
            Column({ space: 12 }) {
              Row({ space: 12 }) {
                Button({ type: ButtonType.Circle }) {
                  Text('Rest')
                    .fontSize(14)
                }
                .width(56)
                .height(56)
                .backgroundColor('#F3F4F6')
                .onClick(() => {
                  this.onStartBreak()
                })

                Button({ type: ButtonType.Circle }) {
                  Text(this.isRunning() ? 'Pause' : 'Play')
                    .fontSize(14)
                }
                .width(56)
                .height(56)
                .backgroundColor('#F3F4F6')
                .onClick(() => {
                  if (this.isRunning()) {
                    this.onPause()
                  } else {
                    this.onResume()
                  }
                })

                Button('Complete')
                  .layoutWeight(1)
                  .height(56)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                  .backgroundColor('#2F54EB')
                  .borderRadius(28)
                  .shadow({ radius: 12, color: '#2F54EB40', offsetX: 0, offsetY: 4 })
                  .onClick(() => {
                    this.onFinish()
                  })
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          }

          Column() {
            Row({ space: 16 }) {
              Column() {
                Text('Rest Count')
                  .fontSize(13)
                  .fontColor('#6B7280')
                Text(this.getRestCount().toString())
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111827')
              }
              .layoutWeight(1)

              Column() {
                Text('Rest Time')
                  .fontSize(13)
                  .fontColor('#6B7280')
                Text(this.formatTime(this.getTotalRestTime()))
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#111827')
              }
              .layoutWeight(1)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor(Color.White)
          .borderRadius(14)
          .shadow({ radius: 6, color: '#11182710', offsetX: 0, offsetY: 2 })

          Column() {
            Row({ space: 8 }) {
              Text('Focus sessions')
                .fontSize(15)
                .fontColor('#111827')
              Text(this.sessionDetails.length.toString())
                .fontSize(15)
                .fontColor('#2F54EB')
              Blank()
              Button('View Detail')
                .fontSize(14)
                .height(32)
                .backgroundColor('#E6F0FF')
                .fontColor('#2F54EB')
                .borderRadius(16)
                .onClick(() => {
                  this.openSessionDetails()
                })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor(Color.White)
          .borderRadius(14)
          .shadow({ radius: 6, color: '#11182710', offsetX: 0, offsetY: 2 })
        }
        .layoutWeight(1)
        .backgroundColor('#F7F8FA')
        .width('100%')
      }
      .width('100%')
      .height('100%')

      if (this.showPauseWarning) {
        this.PauseWarningDialog()
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
      Text('Pause Task')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('Pausing will end and save this focus session.')
        .fontSize(14)
        .fontColor('#6B7280')

      Row({ space: 8 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.neverShowPauseWarning })
          .selectedColor('#2F54EB')
          .onChange((checked: boolean) => {
            this.neverShowPauseWarning = checked
          })
        Text("Don't show this again")
          .fontSize(12)
          .fontColor('#4B5563')
      }

      Row({ space: 12 }) {
        Button('Cancel')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(16)
          .onClick(() => {
            this.showPauseWarning = false
          })

        Button('Pause & Save')
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
      Text('Leave Task')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('Leaving will pause and save the current session.')
        .fontSize(14)
        .fontColor('#6B7280')

      Row({ space: 12 }) {
        Button('Cancel')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(16)
          .onClick(() => {
            this.showLeaveWarning = false
          })

        Button('Leave')
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
      Text('Active Task Warning')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text('Another task is currently active. Please pause or complete it before starting a new session.')
        .fontSize(14)
        .fontColor('#6B7280')

      Button('OK')
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
      Text('Task Load Error')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')

      Text(this.taskLoadErrorMessage)
        .fontSize(14)
        .fontColor('#6B7280')

      Button('OK')
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
        Text('Session Details')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Blank()
        Button('Close')
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
        Text('No completed sessions yet.')
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
                        Text(`Focus: ${item.status === SessionStatus.FINISHED ? this.formatTime(item.focusDuration) : 'In progress'}`)
                          .fontSize(14)
                          .fontColor('#111827')
                        Text(`Rest: ${item.status === SessionStatus.FINISHED ? this.formatTime(item.restDuration) : 'In progress'}`)
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
    this.sessionSheetVisible = true
    this.sessionSheetOffset = 500
    this.sessionSheetOpacity = 0
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
}
