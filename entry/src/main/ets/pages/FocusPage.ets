/**
 * 计时页 TimerPage - 运行中的专注计时器（极简现代风格）
 * 注意：此页面仅在有活动会话时显示
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { FocusStore, FocusState } from '../store/focusStore'
import { TaskStore } from '../store/taskStore'
import { SessionStatus } from '../model/SessionStatus'
import { SessionType } from '../model/FocusSession'
import { SettingsService } from '../services/SettingsService'

@Entry
@Component
struct FocusPage {
  @State focusState: FocusState = FocusStore.getState()
  @State taskTitle: string = 'Anonymous'
  @State showInterruptionDialog: boolean = false
  @State interruptionReason: string = ''
  @State pendingAction: string = 'none' // 'pause' | 'finish' | 'none'
  private timerInterval: number = -1

  async aboutToAppear() {
    // 关键：检查是否有活动会话
    this.focusState = FocusStore.getState()
    if (!this.focusState.currentSession) {
      promptAction.showToast({ message: '无活动会话，请先启动专注' })
      router.back()
      return
    }

    // 获取任务标题
    if (this.focusState.currentTaskId !== null) {
      const task = TaskStore.findTask(this.focusState.currentTaskId)
      if (task) {
        this.taskTitle = task.title
      }
    }

    // 启动计时器订阅（每秒更新UI）
    this.startTimer()
  }

  aboutToDisappear() {
    // 清理计时器
    if (this.timerInterval !== -1) {
      clearInterval(this.timerInterval)
      this.timerInterval = -1
    }
  }

  // 启动计时器
  private startTimer() {
    this.timerInterval = setInterval(() => {
      this.focusState = FocusStore.getState()
    }, 1000)
  }

  // 格式化时间显示（mm:ss）
  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  }

  // 计算进度百分比（0-1）
  private getProgress(): number {
    if (!this.focusState.currentSession) return 0
    
    if (this.focusState.isBreaking) {
      // 休息进度
      const total = this.focusState.breakDuration
      const elapsed = this.focusState.breakElapsedTime
      return total > 0 ? Math.min(elapsed / total, 1) : 0
    } else {
      // 专注进度
      const session = this.focusState.currentSession
      if (session.sessionType === SessionType.COUNTDOWN && session.timeLimitMs) {
        // 倒计时模式：显示剩余时间占比
        const elapsed = this.focusState.elapsedTime
        return Math.min(elapsed / session.timeLimitMs, 1)
      } else {
        // 正计时模式：无进度环，只显示时间
        return 0
      }
    }
  }

  // 暂停专注
  private async onPause() {
    this.pendingAction = 'pause'
    this.showInterruptionDialog = true
  }

  // 继续专注
  private async onResume() {
    const result = await FocusStore.resumeFocus()
    if (result.ok) {
      promptAction.showToast({ message: '已继续' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 开始休息
  private async onStartBreak() {
    const settings = SettingsService.getSettings()
    const duration = settings.defaultRestDuration * 60 * 1000
    const result = await FocusStore.startBreak(duration)
    if (result.ok) {
      promptAction.showToast({ message: '开始休息' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 结束休息
  private async onFinishBreak() {
    const result = await FocusStore.finishBreak()
    if (result.ok) {
      promptAction.showToast({ message: '休息结束' })
      await this.onResume()
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 结束专注
  private async onFinish() {
    this.pendingAction = 'finish'
    this.showInterruptionDialog = true
  }

  // 执行暂停或结束操作
  private async executeAction() {
    // 记录原因
    if (this.interruptionReason) {
      await FocusStore.setInterruptionReason(this.interruptionReason)
    }

    if (this.pendingAction === 'pause') {
      const result = await FocusStore.pauseFocus()
      if (result.ok) {
        promptAction.showToast({ message: '已暂停' })
      } else {
        promptAction.showToast({ message: result.message ?? 'Unknown error' })
      }
    } else if (this.pendingAction === 'finish') {
      const result = await FocusStore.finishFocus()
      if (result.ok) {
        promptAction.showToast({ message: '专注已完成' })
        router.back()
      } else {
        promptAction.showToast({ message: result.message ?? 'Unknown error' })
      }
    }

    this.interruptionReason = ''
    this.pendingAction = 'none'
    this.showInterruptionDialog = false
  }

  // 返回首页（带警告）
  private goBack() {
    AlertDialog.show({
      title: '确认退出？',
      message: '退出将暂停当前会话',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确认退出',
        action: async () => {
          await FocusStore.pauseFocus()
          router.back()
        }
      }
    })
  }

  build() {
    Stack() {
      Column() {
        // ====== Header ======
        Row() {
          // 返回按钮
          Text('←')
            .fontSize(24)
            .fontColor('#FFFFFF')
            .onClick(() => {
              this.goBack()
            })

          Blank()

          // 状态标签
          Text(this.focusState.isBreaking ? '休息中' : 
               this.focusState.currentSession?.status === SessionStatus.PAUSED ? '已暂停' : '专注中')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#ffffff30')
            .borderRadius(20)
        }
        .width('100%')
        .height(56)
        .padding({ left: 20, right: 20 })
        .alignItems(VerticalAlign.Center)

        // ====== Main Timer Circle ======
        Column() {
          Stack() {
            // 背景圆环（淡紫色）
            Circle()
              .width(280)
              .height(280)
              .fill('#E0E0F5')
              .shadow({
                radius: 24,
                color: '#2F54EB20',
                offsetX: 0,
                offsetY: 8
              })

            // 进度圆环（仅倒计时/休息模式）
            if (this.getProgress() > 0) {
              Progress({
                value: this.getProgress() * 100,
                total: 100,
                type: ProgressType.Ring
              })
                .width(280)
                .height(280)
                .color('#2F54EB')
                .style({
                  strokeWidth: 8
                })
            }

            // 圆内内容
            Column({ space: 12 }) {
              Text(this.focusState.isBreaking ? 'Break time' : 'Focus time')
                .fontSize(14)
                .fontColor('#8F9098')

              Text(this.focusState.isBreaking 
                ? this.formatTime(this.focusState.breakElapsedTime)
                : this.formatTime(this.focusState.elapsedTime))
                .fontSize(64)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1A1A2E')

              Text(this.focusState.isBreaking
                ? `Planned: ${this.formatTime(this.focusState.breakDuration)}`
                : `Total focus: ${this.formatTime(this.focusState.elapsedTime)}`)
                .fontSize(12)
                .fontColor('#8F9098')
            }
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        // ====== Action Buttons ======
        Column({ space: 12 }) {
          if (this.focusState.isBreaking) {
            // 休息中的按钮
            Button('End Break')
              .width('100%')
              .height(56)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor('#2F54EB')
              .borderRadius(28)
              .shadow({
                radius: 12,
                color: '#2F54EB40',
                offsetX: 0,
                offsetY: 4
              })
              .onClick(() => {
                this.onFinishBreak()
              })
          } else {
            // 专注中的按钮
            Row({ space: 12 }) {
              if (this.focusState.currentSession?.status === SessionStatus.RUNNING) {
                Button('Pause')
                  .height(56)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#2F54EB')
                  .borderRadius(28)
                  .layoutWeight(1)
                  .shadow({
                    radius: 8,
                    color: '#2F54EB40',
                    offsetX: 0,
                    offsetY: 3
                  })
                  .onClick(() => {
                    this.onPause()
                  })
              } else {
                Button('Resume')
                  .height(56)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#2F54EB')
                  .borderRadius(28)
                  .layoutWeight(1)
                  .shadow({
                    radius: 8,
                    color: '#2F54EB40',
                    offsetX: 0,
                    offsetY: 3
                  })
                  .onClick(() => {
                    this.onResume()
                  })
              }

              Button('Rest')
                .height(56)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
                .backgroundColor('#8F9098')
                .borderRadius(28)
                .layoutWeight(1)
                .shadow({
                  radius: 8,
                  color: '#8F909820',
                  offsetX: 0,
                  offsetY: 3
                })
                .onClick(() => {
                  this.onStartBreak()
                })
            }
            .width('100%')

            Button('Complete')
              .width('100%')
              .height(56)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .backgroundColor('#1A1A2E')
              .borderRadius(28)
              .shadow({
                radius: 12,
                color: '#1A1A2E30',
                offsetX: 0,
                offsetY: 4
              })
              .onClick(() => {
                this.onFinish()
              })
          }
        }
        .width('100%')
        .padding({ left: 24, right: 24, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .linearGradient({
        angle: 180,
        colors: this.focusState.isBreaking
          ? [['#8F9098', 0], ['#1A1A2E', 1]]
          : [['#2F54EB', 0], ['#1A1A2E', 1]]
      })

      // 干扰原因输入对话框
      if (this.showInterruptionDialog) {
        this.InterruptionDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 干扰原因输入对话框
  @Builder
  InterruptionDialog() {
    Column() {
      // 遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          // 点击遮罩关闭
          this.showInterruptionDialog = false
          this.interruptionReason = ''
          this.pendingAction = 'none'
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 20 }) {
      Text(this.pendingAction === 'pause' ? 'Pause Focus' : 'Complete Focus')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A2E')

      Text('Record why you interrupted? (Optional)')
        .fontSize(14)
        .fontColor('#8F9098')

      TextInput({ placeholder: 'e.g., Phone call, Someone needs help...' })
        .width('100%')
        .height(48)
        .fontSize(14)
        .borderRadius(12)
        .backgroundColor('#F5F5F7')
        .onChange((value: string) => {
          this.interruptionReason = value
        })

      // 快捷原因按钮
      Row({ space: 8 }) {
        ForEach(['Phone call', 'Bathroom', 'Water'], (reason: string) => {
          Button(reason)
            .fontSize(12)
            .height(32)
            .padding({ left: 12, right: 12 })
            .backgroundColor(this.interruptionReason === reason ? '#2F54EB' : '#F5F5F7')
            .fontColor(this.interruptionReason === reason ? '#FFFFFF' : '#8F9098')
            .borderRadius(16)
            .onClick(() => {
              this.interruptionReason = reason
            })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Row({ space: 12 }) {
        Button('Cancel')
          .fontSize(16)
          .height(48)
          .layoutWeight(1)
          .backgroundColor('#F5F5F7')
          .fontColor('#8F9098')
          .borderRadius(24)
          .onClick(() => {
            this.showInterruptionDialog = false
            this.interruptionReason = ''
            this.pendingAction = 'none'
          })

        Button('Confirm')
          .fontSize(16)
          .height(48)
          .layoutWeight(1)
          .backgroundColor('#2F54EB')
          .fontColor('#FFFFFF')
          .borderRadius(24)
          .onClick(() => {
            this.executeAction()
          })
      }
      .width('100%')
    }
    .width('85%')
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({
      radius: 16,
      color: '#1A1A2E20',
      offsetX: 0,
      offsetY: 8
    })
    .position({ x: '7.5%', y: '30%' })
  }
}
