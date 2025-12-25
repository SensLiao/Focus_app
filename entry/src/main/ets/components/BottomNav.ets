/**
 * 底部导航栏组件 - 基于 Sample_Frontend BottomNav 设计
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
      // History 按钮 (左侧)
      Column({ space: 2 }) {
        Text('📊')
          .fontSize(22)
        Text('历史')
          .fontSize(11)
          .fontColor(this.currentIndex === 1 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 10, bottom: 10 })
      .borderRadius(12)
      .backgroundColor(this.currentIndex === 1 ? Theme.COLOR_PRIMARY_BG : Color.Transparent)
      .onClick(() => {
        if (this.currentIndex !== 1) {
          router.replaceUrl({ url: 'pages/HistoryPage' })
        }
      })

      // Home 按钮 (中间)
      Column({ space: 2 }) {
        Text('🏠')
          .fontSize(22)
        Text('首页')
          .fontSize(11)
          .fontColor(this.currentIndex === 0 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 10, bottom: 10 })
      .borderRadius(12)
      .backgroundColor(this.currentIndex === 0 ? Theme.COLOR_PRIMARY_BG : Color.Transparent)
      .onClick(() => {
        if (this.currentIndex !== 0) {
          router.replaceUrl({ url: 'pages/Index' })
        }
      })

      // Settings 按钮 (右侧)
      Column({ space: 2 }) {
        Text('⚙️')
          .fontSize(22)
        Text('设置')
          .fontSize(11)
          .fontColor(this.currentIndex === 2 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 10, bottom: 10 })
      .borderRadius(12)
      .backgroundColor(this.currentIndex === 2 ? Theme.COLOR_PRIMARY_BG : Color.Transparent)
      .onClick(() => {
        if (this.currentIndex !== 2) {
          router.replaceUrl({ url: 'pages/SettingsPage' })
        }
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .border({
      width: { top: 1 },
      color: Theme.COLOR_BORDER
    })
  }
}
