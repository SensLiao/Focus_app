/**
 * 底部导航栏组件 - 精致现代风格
 */

import router from '@ohos.router'
import { Theme } from '../common/theme'
import { OnboardingRect } from '../onboarding/OnboardingFlow'

export interface BottomNavProps {
  currentIndex: number  // 0: Home, 1: History, 2: Settings
}

@Component
export struct BottomNav {
  @Prop currentIndex: number = 0
  @StorageLink('onboardingHistoryRectX') onboardingHistoryRectX: number = 0
  @StorageLink('onboardingHistoryRectY') onboardingHistoryRectY: number = 0
  @StorageLink('onboardingHistoryRectW') onboardingHistoryRectW: number = 0
  @StorageLink('onboardingHistoryRectH') onboardingHistoryRectH: number = 0

  build() {
    Row() {
      // History 按钮 (左侧)
      Column({ space: 4 }) {
        Column() {
          Text('📊')
            .fontSize(24)
        }
        .width(48)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .borderRadius(16)
        .backgroundColor(this.currentIndex === 1 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_CARD_BACKGROUND)
        .border({ width: this.currentIndex === 1 ? 0 : 1, color: Theme.COLOR_BORDER })
        
        Text('历史')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontWeight(this.currentIndex === 1 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.currentIndex === 1 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 8 })
      .onAreaChange((_, newArea) => {
        const rect = this.areaToRect(newArea)
        this.onboardingHistoryRectX = rect.x
        this.onboardingHistoryRectY = rect.y
        this.onboardingHistoryRectW = rect.width
        this.onboardingHistoryRectH = rect.height
      })
      .onClick(() => {
        if (this.currentIndex !== 1) {
          router.replaceUrl({ url: 'pages/HistoryPage' })
        }
      })

      // Home 按钮 (中间) - 突出显示
      Column({ space: 4 }) {
        Column() {
          Text('🏠')
            .fontSize(26)
        }
        .width(56)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .borderRadius(18)
        .backgroundColor(this.currentIndex === 0 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_CARD_BACKGROUND)
        .border({ width: this.currentIndex === 0 ? 0 : 1, color: Theme.COLOR_BORDER })
        .shadow(Theme.SHADOW_SMALL)
        
        Text('首页')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontWeight(this.currentIndex === 0 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.currentIndex === 0 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 6, bottom: 8 })
      .onClick(() => {
        if (this.currentIndex !== 0) {
          router.replaceUrl({ url: 'pages/Index' })
        }
      })

      // Settings 按钮 (右侧)
      Column({ space: 4 }) {
        Column() {
          Text('⚙️')
            .fontSize(24)
        }
        .width(48)
        .height(32)
        .justifyContent(FlexAlign.Center)
        .borderRadius(16)
        .backgroundColor(this.currentIndex === 2 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_CARD_BACKGROUND)
        .border({ width: this.currentIndex === 2 ? 0 : 1, color: Theme.COLOR_BORDER })
        
        Text('设置')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontWeight(this.currentIndex === 2 ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.currentIndex === 2 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 8 })
      .onClick(() => {
        if (this.currentIndex !== 2) {
          router.replaceUrl({ url: 'pages/SettingsPage' })
        }
      })
    }
    .width('100%')
    .height(72)
    .padding({ left: 12, right: 12 })
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .border({
      width: { top: 1 },
      color: Theme.COLOR_BORDER
    })
    .shadow({
      radius: 8,
      color: '#00000008',
      offsetX: 0,
      offsetY: -2
    })
  }

  private parseLength(value: Length | undefined): number {
    if (value === undefined) {
      return 0
    }
    if (typeof value === 'number') {
      return value
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value)
      return Number.isNaN(parsed) ? 0 : parsed
    }
    return 0
  }

  private areaToRect(newArea: Area): OnboardingRect {
    return {
      x: this.parseLength(newArea.position?.x),
      y: this.parseLength(newArea.position?.y),
      width: this.parseLength(newArea.width),
      height: this.parseLength(newArea.height)
    }
  }
}
