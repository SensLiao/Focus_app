/**
 * 专注页 - 全屏专注计时
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { FocusStore, FocusState } from '../store/focusStore'
import { TaskStore } from '../store/taskStore'
import { SessionStatus } from '../model/SessionStatus'
import { SessionType } from '../model/FocusSession'
import { FocusTimer } from '../components/FocusTimer'
import { BreakTimer } from '../components/BreakTimer'
import { Theme } from '../common/theme'
import { Constants } from '../common/constants'

@Entry
@Component
struct FocusPage {
  @State focusState: FocusState = FocusStore.getState()
  @State taskTitle: string = '匿名专注'

  async aboutToAppear() {
    // 获取任务标题
    if (this.focusState.currentTaskId !== null) {
      const task = TaskStore.findTask(this.focusState.currentTaskId)
      if (task) {
        this.taskTitle = task.title
      }
    }
  }

  build() {
    Column() {
      // 返回按钮（仅休息时显示）
      if (this.focusState.isBreaking) {
        Row() {
          Button('< 返回')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .onClick(() => {
              this.showExitWarning()
            })
        }
        .width('100%')
        .padding(Theme.SPACE_MEDIUM)
      }

      // 主内容区
      Column() {
        if (this.focusState.isBreaking) {
          // 休息计时器
          BreakTimer({
            elapsedMs: this.focusState.breakElapsedTime,
            plannedDurationMs: this.focusState.breakDuration,
            onSkip: () => {
              this.skipBreak()
            },
            onExtend: () => {
              this.extendBreak()
            }
          })
        } else {
          // 专注计时器
          FocusTimer({
            elapsedMs: this.focusState.elapsedTime,
            remainingMs: this.focusState.remainingTime,
            isCountdown: this.focusState.currentSession?.sessionType === SessionType.COUNTDOWN,
            segmentIndex: this.focusState.currentSegment?.segmentIndex ?? 1,
            taskTitle: this.taskTitle,
            onExtend: () => {
              this.extendTimeLimit()
            },
            onForceFinish: () => {
              this.showForceFinishDialog()
            }
          })

          // 提示文本
          Text('切换到其他应用将自动暂停计时')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_WARNING)
            .margin({ top: Theme.SPACE_LARGE })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 底部操作区
      Column({ space: Theme.SPACE_MEDIUM }) {
        if (this.focusState.isBreaking) {
          // 休息中的操作
          Button('结束休息')
            .width('80%')
            .height(50)
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .backgroundColor(Theme.COLOR_SUCCESS)
            .onClick(() => {
              this.finishBreak()
            })
        } else {
          // 专注中的操作
          Row({ space: Theme.SPACE_MEDIUM }) {
            if (this.focusState.currentSession?.status === SessionStatus.RUNNING) {
              Button('暂停')
                .height(50)
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .backgroundColor(Theme.COLOR_WARNING)
                .layoutWeight(1)
                .onClick(() => {
                  this.pauseFocus()
                })
            } else {
              Button('继续')
                .height(50)
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .backgroundColor(Theme.COLOR_SUCCESS)
                .layoutWeight(1)
                .onClick(() => {
                  this.resumeFocus()
                })
            }

            Button('休息')
              .height(50)
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .layoutWeight(1)
              .onClick(() => {
                this.startBreak()
              })
          }
          .width('80%')

          Button('结束专注')
            .width('80%')
            .height(50)
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .backgroundColor(Theme.COLOR_ERROR)
            .onClick(() => {
              this.finishFocus()
            })
        }
      }
      .width('100%')
      .padding(Theme.SPACE_LARGE)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  // 暂停专注
  private async pauseFocus() {
    const result = await FocusStore.pauseFocus()
    if (result.ok) {
      promptAction.showToast({ message: '已暂停' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 继续专注
  private async resumeFocus() {
    const result = await FocusStore.resumeFocus()
    if (result.ok) {
      promptAction.showToast({ message: '已继续' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 开始休息
  private async startBreak() {
    const result = await FocusStore.startBreak(Constants.DEFAULT_BREAK_DURATION)
    if (result.ok) {
      promptAction.showToast({ message: '开始休息' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 结束休息
  private async finishBreak() {
    const result = await FocusStore.finishBreak()
    if (result.ok) {
      promptAction.showToast({ message: '休息结束' })
      // 自动继续专注
      await this.resumeFocus()
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 结束专注
  private async finishFocus() {
    const result = await FocusStore.finishFocus()
    if (result.ok) {
      promptAction.showToast({ message: '专注已完成' })
      router.back()
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 显示退出警告
  private showExitWarning() {
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

  // 延长时限
  private async extendTimeLimit() {
    const result = await FocusStore.extendTimeLimit(5 * 60 * 1000) // 延长 5 分钟
    if (result.ok) {
      promptAction.showToast({ message: '已延长 5 分钟' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 显示强制结束对话框（需要输入原因）
  private showForceFinishDialog() {
    AlertDialog.show({
      title: '强制结束专注',
      message: '请输入中断原因',
      confirm: {
        value: '确定',
        action: () => {
          // 简化版：使用默认原因
          this.finishFocusWithReason('用户强制结束')
        }
      },
      cancel: () => {}
    })
  }

  // 带原因结束专注
  private async finishFocusWithReason(reason: string) {
    await FocusStore.setInterruptionReason(reason)
    await this.finishFocus()
  }

  // 跳过休息
  private async skipBreak() {
    const result = await FocusStore.skipBreak()
    if (result.ok) {
      promptAction.showToast({ message: '已跳过休息' })
      await this.resumeFocus()
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }

  // 延长休息
  private async extendBreak() {
    const result = await FocusStore.extendBreak(5 * 60 * 1000) // 延长 5 分钟
    if (result.ok) {
      promptAction.showToast({ message: '休息时间已延长 5 分钟' })
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }
}
