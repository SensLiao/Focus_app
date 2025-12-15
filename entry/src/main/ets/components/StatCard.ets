/**
 * 统计卡片组件
 */

import { Theme } from '../common/theme'

@Component
export struct StatCard {
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop icon: string = ''

  build() {
    Column() {
      Text(this.title)
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)

      Text(this.value)
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: Theme.SPACE_SMALL })
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
    .justifyContent(FlexAlign.Center)
  }
}
