/**
 * 引导页 - 系统专注模式教学
 */

import router from '@ohos.router'
import common from '@ohos.app.ability.common'
import { Theme } from '../common/theme'
import { Logger } from '../common/logger'

@Entry
@Component
struct GuidePage {
  build() {
    Column() {
      // 顶部导航
      Row() {
        Button('< 返回')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .onClick(() => {
            router.back()
          })

        Text('使用引导')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(60)
      }
      .width('100%')
      .padding(Theme.SPACE_MEDIUM)

      // 内容区
      Scroll() {
        Column({ space: Theme.SPACE_LARGE }) {
          // 标题
          Text('如何获得更好的专注体验？')
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)

          // 说明卡片
          Column({ space: Theme.SPACE_MEDIUM }) {
            Text('1. 开启系统专注模式')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)

            Text('为了最大化专注效果，建议您手动开启系统级专注模式。这将：')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)

            Text('• 屏蔽来电和通知干扰\n• 减少其他应用的打断\n• 营造专注氛围')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .lineHeight(24)

            Button('前往系统设置')
              .width('100%')
              .height(48)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .onClick(() => {
                this.openSystemSettings()
              })
          }
          .width('100%')
          .padding(Theme.SPACE_MEDIUM)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

          // 应用说明
          Column({ space: Theme.SPACE_MEDIUM }) {
            Text('2. 本应用的专注机制')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)

            Text('本应用采用"软专注"策略：')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)

            Text('• 在应用内开始专注计时\n• 切换到其他应用时自动暂停\n• 5分钟后提醒您继续专注\n• 记录每次专注和打断')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .lineHeight(24)
          }
          .width('100%')
          .padding(Theme.SPACE_MEDIUM)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

          // 使用建议
          Column({ space: Theme.SPACE_MEDIUM }) {
            Text('3. 使用建议')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)

            Text('• 每次专注 25 分钟，休息 5 分钟\n• 专注时保持在应用内\n• 完成后查看历史记录和统计\n• 坚持使用，养成专注习惯')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .lineHeight(24)
          }
          .width('100%')
          .padding(Theme.SPACE_MEDIUM)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
        }
        .width('100%')
        .padding(Theme.SPACE_LARGE)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  private openSystemSettings() {
    try {
      const context = getContext(this) as common.UIAbilityContext
      // 尝试跳转到系统设置（DND/专注模式）
      // 注意：实际路径依赖于系统版本
      context.startAbility({
        bundleName: 'com.huawei.settings',
        abilityName: 'com.huawei.settings.MainAbility'
      })
      Logger.info('Navigated to system settings')
    } catch (error) {
      Logger.error('Failed to open system settings', JSON.stringify(error))
    }
  }
}
