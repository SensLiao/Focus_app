/**
 * 引导页 - 系统专注模式教学
 */

import router from '@ohos.router'
import common from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'
import { Theme } from '../common/theme'
import { Logger } from '../common/logger'
import promptAction from '@ohos.promptAction'

@Entry
@Component
struct GuidePage {
  @State showSettingsDialog: boolean = false

  build() {
    Stack() {
      Column() {
        // 顶部导航
        Row() {
          Button('< 返回')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .backgroundColor(Theme.COLOR_PRIMARY)
            .borderRadius(20)
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
                .borderRadius(24)
                .onClick(() => {
                  this.showSettingsDialog = true
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

      // 跳转确认对话框
      if (this.showSettingsDialog) {
        this.SettingsConfirmDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SettingsConfirmDialog() {
    Column() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#00000060')
        .onClick(() => {
          this.showSettingsDialog = false
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 16 }) {
      Text('跳转到系统设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('即将打开本应用的系统设置页面，您可以在那里：')
        .fontSize(14)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)

      Column({ space: 8 }) {
        Text('• 管理应用通知权限')
          .fontSize(14)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
        Text('• 查看应用存储和缓存')
          .fontSize(14)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
        Text('• 配置应用权限设置')
          .fontSize(14)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Row({ space: 12 }) {
        Button('取消')
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F3F4F6')
          .fontColor('#4B5563')
          .borderRadius(24)
          .onClick(() => {
            this.showSettingsDialog = false
          })

        Button('前往设置')
          .layoutWeight(1)
          .height(48)
          .backgroundColor(Theme.COLOR_PRIMARY)
          .fontColor(Color.White)
          .borderRadius(24)
          .onClick(() => {
            this.showSettingsDialog = false
            this.openAppSettings()
          })
      }
      .width('100%')
    }
    .width('85%')
    .padding(24)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(16)
    .shadow({ radius: 16, color: '#11182726', offsetX: 0, offsetY: 8 })
    .position({ x: '7.5%', y: '30%' })
  }

  private openAppSettings() {
    try {
      const context = getContext(this) as common.UIAbilityContext
      const bundleName = context.abilityInfo.bundleName

      // 跳转到本应用的系统设置页面
      const want: Want = {
        action: 'action.settings.app.info',
        uri: 'application_info_entry',
        parameters: {
          pushParams: bundleName
        }
      }

      context.startAbility(want).then(() => {
        Logger.info('成功跳转到应用设置页面')
      }).catch((err: Error) => {
        Logger.error('跳转失败，尝试备用方式', JSON.stringify(err))
        // 备用方式：尝试直接打开系统设置
        this.openSystemSettingsFallback(context)
      })
    } catch (error) {
      Logger.error('打开系统设置失败', JSON.stringify(error))
      promptAction.showToast({ message: '无法打开系统设置，请手动前往' })
    }
  }

  private openSystemSettingsFallback(context: common.UIAbilityContext) {
    try {
      // 备用方式：打开系统设置主页
      const want: Want = {
        bundleName: 'com.huawei.hmos.settings',
        abilityName: 'com.huawei.hmos.settings.MainAbility'
      }
      context.startAbility(want).then(() => {
        Logger.info('成功打开系统设置主页')
        promptAction.showToast({ message: '请在设置中找到本应用进行配置' })
      }).catch((err: Error) => {
        Logger.error('备用方式也失败', JSON.stringify(err))
        promptAction.showToast({ message: '无法打开系统设置，请手动前往设置 > 应用' })
      })
    } catch (error) {
      Logger.error('备用方式异常', JSON.stringify(error))
      promptAction.showToast({ message: '请手动前往 设置 > 应用 > 专注' })
    }
  }
}
