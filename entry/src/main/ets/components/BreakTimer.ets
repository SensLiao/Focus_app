/**
 * 休息计时器组件
 */

import { Theme } from '../common/theme'

@Component
export struct BreakTimer {
  @Prop elapsedMs: number = 0
  @Prop plannedDurationMs: number = 300000

  build() {
    Column() {
      Text('休息时间')
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)

      // 进度条
      Progress({
        value: Math.min(this.elapsedMs, this.plannedDurationMs),
        total: this.plannedDurationMs,
        type: ProgressType.Ring
      })
        .width(200)
        .height(200)
        .margin({ top: Theme.SPACE_LARGE, bottom: Theme.SPACE_LARGE })
        .color(Theme.COLOR_SUCCESS)

      // 倒计时显示
      Text(this.formatCountdown(this.plannedDurationMs - this.elapsedMs))
        .fontSize(48)
        .fontColor(Theme.COLOR_SUCCESS)
        .fontWeight(FontWeight.Bold)
        .fontFamily('monospace')

      Text('剩余时间')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .margin({ top: Theme.SPACE_SMALL })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  private formatCountdown(ms: number): string {
    const remaining = Math.max(0, ms)
    const totalSeconds = Math.floor(remaining / 1000)
    const minutes = Math.floor(totalSeconds / 60)
    const seconds = totalSeconds % 60

    return `${this.pad(minutes)}:${this.pad(seconds)}`
  }

  private pad(num: number): string {
    return num < 10 ? `0${num}` : `${num}`
  }
}
