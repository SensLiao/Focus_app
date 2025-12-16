/**
 * 专注计时器组件
 */

import { Theme } from '../common/theme'

@Component
export struct FocusTimer {
  @Prop elapsedMs: number = 0
  @Prop remainingMs: number = 0 // 倒计时剩余时间
  @Prop isCountdown: boolean = false // 是否倒计时模式
  @Prop segmentIndex: number = 1
  @Prop taskTitle: string = '匿名专注'
  onExtend?: () => void // 延长时限回调
  onForceFinish?: () => void // 强制结束回调

  build() {
    Column() {
      // 任务标题
      Text(this.taskTitle)
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)

      // 段数提示
      Text(`第 ${this.segmentIndex} 段`)
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .margin({ top: Theme.SPACE_SMALL })

      // 计时器显示
      Text(this.isCountdown ? this.formatTime(this.remainingMs) : this.formatTime(this.elapsedMs))
        .fontSize(72)
        .fontColor(this.isCountdown && this.remainingMs < 60000 ? Theme.COLOR_ERROR : Theme.COLOR_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: Theme.SPACE_LARGE })
        .fontFamily('monospace')

      // 模式提示
      if (this.isCountdown) {
        Text('倒计时模式')
          .fontSize(Theme.FONT_SIZE_TINY)
          .fontColor(Theme.COLOR_TEXT_TERTIARY)
          .margin({ top: Theme.SPACE_TINY })
      }

      // 操作按钮（倒计时模式）
      if (this.isCountdown) {
        Row() {
          Button('延长 5 分钟')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .backgroundColor(Theme.COLOR_PRIMARY_LIGHT)
            .onClick(() => {
              if (this.onExtend) {
                this.onExtend()
              }
            })

          Button('强制结束')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .backgroundColor(Theme.COLOR_ERROR)
            .margin({ left: Theme.SPACE_MEDIUM })
            .onClick(() => {
              if (this.onForceFinish) {
                this.onForceFinish()
              }
            })
        }
        .margin({ top: Theme.SPACE_LARGE })
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    if (hours > 0) {
      return `${this.pad(hours)}:${this.pad(minutes)}:${this.pad(seconds)}`
    } else {
      return `${this.pad(minutes)}:${this.pad(seconds)}`
    }
  }

  private pad(num: number): string {
    return num < 10 ? `0${num}` : `${num}`
  }
}
