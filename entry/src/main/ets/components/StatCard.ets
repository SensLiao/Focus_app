/**
 * 统计卡片组件
 */
import { Theme } from '../common/theme'

interface GradientColor {
  color: string;
  offset: number;
}

@Component
export struct StatCard {
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop icon: string = ''

  build() {
    Column() {
      // 渐变色强调条
      Row()
        .width(40)
        .height(4)
        .borderRadius(2)
        .linearGradient({
          angle: 90,
          colors: Theme.GRADIENT_PRIMARY.map((grad: GradientColor) => [grad.color, grad.offset])
        })
        .margin({ bottom: Theme.SPACE_MEDIUM })

      Text(this.value)
        .fontSize(Theme.FONT_SIZE_TITLE)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)

      Text(this.title)
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .margin({ top: Theme.SPACE_TINY })
    }
    .width('100%')
    .padding(Theme.SPACE_LARGE)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .shadow({
      radius: Theme.SHADOW_MEDIUM.radius,
      color: Theme.SHADOW_MEDIUM.color,
      offsetX: Theme.SHADOW_MEDIUM.offsetX,
      offsetY: Theme.SHADOW_MEDIUM.offsetY
    })
  }
}
