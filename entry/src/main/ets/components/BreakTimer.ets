/**
 * 休息计时器组件
 */

import { Theme } from '../common/theme'

@Component
export struct BreakTimer {
  @Prop elapsedMs: number = 0
  @Prop plannedDurationMs: number = 300000
  onSkip?: () => void // 跳过休息回调
  onExtend?: () => void // 延长休息回调

  build() {
    Column() {
      // 卡片容器
      Column() {
        Text('休息时间')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: Theme.SPACE_MEDIUM })

        // 进度环容器
        Stack() {
          // 进度环
          Progress({
            value: Math.min(this.elapsedMs, this.plannedDurationMs),
            total: this.plannedDurationMs,
            type: ProgressType.Ring
          })
            .width(240)
            .height(240)
            .color(Theme.COLOR_SUCCESS)
            .style({ strokeWidth: 12 })

          // 中心时间显示
          Column() {
            Text(this.formatCountdown(this.plannedDurationMs - this.elapsedMs))
              .fontSize(56)
              .fontColor(Theme.COLOR_SUCCESS)
              .fontWeight(FontWeight.Bold)
              .fontFamily('monospace')

            Text('剩余时间')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .margin({ top: Theme.SPACE_TINY })
          }
        }
        .margin({ top: Theme.SPACE_LARGE, bottom: Theme.SPACE_LARGE })

        // 操作按钮
        Row({ space: Theme.SPACE_MEDIUM }) {
          Button('跳过休息')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .backgroundColor(Theme.COLOR_WARNING)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .height(48)
            .layoutWeight(1)
            .shadow({
              radius: Theme.SHADOW_SMALL.radius,
              color: Theme.SHADOW_SMALL.color,
              offsetX: Theme.SHADOW_SMALL.offsetX,
              offsetY: Theme.SHADOW_SMALL.offsetY
            })
            .onClick(() => {
              if (this.onSkip) {
                this.onSkip()
              }
            })

          Button('延长 5 分钟')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .backgroundColor(Theme.COLOR_PRIMARY)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .height(48)
            .layoutWeight(1)
            .shadow({
              radius: Theme.SHADOW_SMALL.radius,
              color: Theme.SHADOW_SMALL.color,
              offsetX: Theme.SHADOW_SMALL.offsetX,
              offsetY: Theme.SHADOW_SMALL.offsetY
            })
            .onClick(() => {
              if (this.onExtend) {
                this.onExtend()
              }
            })
        }
        .width('100%')
        .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM })
      }
      .width('90%')
      .constraintSize({ maxWidth: 400 })
      .padding(Theme.SPACE_XLARGE)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .borderRadius(Theme.BORDER_RADIUS_LARGE)
      .shadow({
        radius: Theme.SHADOW_LARGE.radius,
        color: Theme.SHADOW_LARGE.color,
        offsetX: Theme.SHADOW_LARGE.offsetX,
        offsetY: Theme.SHADOW_LARGE.offsetY
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Theme.COLOR_BACKGROUND)
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
