/**
 * 底部导航栏组件 - 基于 Figma Design
 */

import router from '@ohos.router'
import { Theme } from '../common/theme'

export interface BottomNavProps {
  currentIndex: number  // 0: Home, 1: History, 2: Settings
}

@Component
export struct BottomNav {
  @Prop currentIndex: number = 0

  build() {
    Row() {
      // Home 按钮
      Column() {
        Image($r('app.media.layered_image'))
          .width(24)
          .height(24)
          .fillColor(this.currentIndex === 0 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
        
        Text('Home')
          .fontSize(Theme.FONT_SIZE_TINY)
          .fontColor(this.currentIndex === 0 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ top: Theme.SPACE_SMALL, bottom: Theme.SPACE_SMALL })
      .onClick(() => {
        if (this.currentIndex !== 0) {
          router.replaceUrl({ url: 'pages/Index' })
        }
      })

      // History 按钮
      Column() {
        Image($r('app.media.layered_image'))
          .width(24)
          .height(24)
          .fillColor(this.currentIndex === 1 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
        
        Text('History')
          .fontSize(Theme.FONT_SIZE_TINY)
          .fontColor(this.currentIndex === 1 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ top: Theme.SPACE_SMALL, bottom: Theme.SPACE_SMALL })
      .onClick(() => {
        if (this.currentIndex !== 1) {
          router.replaceUrl({ url: 'pages/HistoryPage' })
        }
      })

      // Settings 按钮
      Column() {
        Image($r('app.media.layered_image'))
          .width(24)
          .height(24)
          .fillColor(this.currentIndex === 2 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
        
        Text('Settings')
          .fontSize(Theme.FONT_SIZE_TINY)
          .fontColor(this.currentIndex === 2 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ top: Theme.SPACE_SMALL, bottom: Theme.SPACE_SMALL })
      .onClick(() => {
        if (this.currentIndex !== 2) {
          router.replaceUrl({ url: 'pages/SettingsPage' })
        }
      })
    }
    .width('100%')
    .height(60)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .border({
      width: { top: 1 },
      color: Theme.COLOR_BORDER
    })
  }
}
