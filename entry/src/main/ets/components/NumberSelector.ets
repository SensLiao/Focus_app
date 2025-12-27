
/**
 * 数字选择器组件
 */
import { Theme } from '../common/theme'

@Component
export struct NumberSelector {
  @Prop value: number
  @Prop min: number = 0
  @Prop max: number = 0
  @Prop step: number = 1
  @Prop unit: string = ''
  @Prop compact: boolean = false
  onChange?: (val: number) => void

  private updateValue(next: number) {
    const clamped = Math.max(this.min, Math.min(this.max, next))
    this.value = clamped
    if (this.onChange) {
      this.onChange(clamped)
    }
  }
  build() {
    Row({ space: this.compact ? 4 : 8 }) {
      // 减少按钮
      Button({ type: ButtonType.Circle }) {
        Text('-')
          .fontSize(this.compact ? Theme.FONT_SIZE_MEDIUM : Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.value > this.min ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .width(this.compact ? 32 : 42)
      .height(this.compact ? 32 : 42)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .border({ width: 1, color: Theme.COLOR_BORDER })
      .enabled(this.value > this.min)
      .onClick(() => {
        if (this.value > this.min) {
          this.updateValue(this.value - this.step)
        }
      })

      // 数值显示
      Column() {
        Text(`${this.value}`)
          .fontSize(this.compact ? Theme.FONT_SIZE_MEDIUM : Theme.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
      }
      .width(this.compact ? 36 : 56)
      .height(this.compact ? 32 : 42)
      .justifyContent(FlexAlign.Center)

      // 增加按钮
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(this.compact ? Theme.FONT_SIZE_MEDIUM : Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.value < this.max ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .width(this.compact ? 32 : 42)
      .height(this.compact ? 32 : 42)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .border({ width: 1, color: Theme.COLOR_BORDER })
      .enabled(this.value < this.max)
      .onClick(() => {
        if (this.value < this.max) {
          this.updateValue(this.value + this.step)
        }
      })
    }
    .alignItems(VerticalAlign.Center)
  }
}