/**
 * 引导页 - 系统专注模式教学 - 精致现代风格
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
  @State headerOpacity: number = 0
  @State contentOpacity: number = 0

  aboutToAppear() {
    // 入场动画
    setTimeout(() => {
      this.headerOpacity = 1
    }, 100)
    setTimeout(() => {
      this.contentOpacity = 1
    }, 200)
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航
        Row({ space: 16 }) {
          Button({ type: ButtonType.Circle }) {
            Text('←')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          .width(44)
          .height(44)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .onClick(() => {
            router.back()
          })

          Text('使用指南')
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
            .layoutWeight(1)

          Text('📖')
            .fontSize(28)
        }
        .width('100%')
        .padding({ left: 16, right: 20, top: 12, bottom: 12 })
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })
        .opacity(this.headerOpacity)
        .animation({
          duration: Theme.ANIMATION_NORMAL,
          curve: Curve.EaseOut
        })

        // 内容区
        Scroll() {
          Column({ space: 20 }) {
            // 标题区域
            Column({ space: 8 }) {
              Text('🎯')
                .fontSize(48)
              Text('如何获得更好的专注体验？')
                .fontSize(Theme.FONT_SIZE_TITLE)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
                .textAlign(TextAlign.Center)
              Text('按照以下步骤设置，开启高效专注之旅')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding({ top: 16, bottom: 8 })

            // 说明卡片1
            Column({ space: 14 }) {
              Row({ space: 10 }) {
                Column() {
                  Text('1')
                    .fontSize(Theme.FONT_SIZE_LARGE)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .backgroundColor(Theme.COLOR_PRIMARY)
                .justifyContent(FlexAlign.Center)

                Text('开启系统专注模式')
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }

              Text('为了最大化专注效果，建议您手动开启系统级专注模式。这将：')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)

              Column({ space: 10 }) {
                Row({ space: 10 }) {
                  Text('🔕')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('屏蔽来电和通知干扰')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('📵')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('减少其他应用的打断')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('🧘')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('营造专注氛围')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 8 })

              Button('前往系统设置')
                .width('100%')
                .height(52)
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .backgroundColor(Theme.COLOR_PRIMARY)
                .borderRadius(Theme.BORDER_RADIUS_LARGE)
                .shadow(Theme.SHADOW_GLOW)
                .margin({ top: 4 })
                .onClick(() => {
                  this.showSettingsDialog = true
                })
            }
            .width('100%')
            .padding(22)
            .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .shadow(Theme.SHADOW_MEDIUM)

            // 说明卡片2
            Column({ space: 14 }) {
              Row({ space: 10 }) {
                Column() {
                  Text('2')
                    .fontSize(Theme.FONT_SIZE_LARGE)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .backgroundColor(Theme.COLOR_SUCCESS)
                .justifyContent(FlexAlign.Center)

                Text('本应用的专注机制')
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }

              Text('本应用采用"软专注"策略：')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)

              Column({ space: 10 }) {
                Row({ space: 10 }) {
                  Text('⏱️')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('在应用内开始专注计时')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('⏸️')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('切换到其他应用时自动暂停')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('🔔')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('5分钟后提醒您继续专注')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('📊')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('记录每次专注和打断')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 8 })
            }
            .width('100%')
            .padding(22)
            .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .shadow(Theme.SHADOW_MEDIUM)

            // 使用建议卡片
            Column({ space: 14 }) {
              Row({ space: 10 }) {
                Column() {
                  Text('3')
                    .fontSize(Theme.FONT_SIZE_LARGE)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Color.White)
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .backgroundColor('#F59E0B')
                .justifyContent(FlexAlign.Center)

                Text('使用建议')
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }

              Column({ space: 10 }) {
                Row({ space: 10 }) {
                  Text('🍅')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('每次专注 25 分钟，休息 5 分钟')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('📱')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('专注时保持在应用内')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('📈')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('完成后查看历史记录和统计')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
                Row({ space: 10 }) {
                  Text('💪')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                  Text('坚持使用，养成专注习惯')
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                }
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
              .padding({ left: 8 })
            }
            .width('100%')
            .padding(22)
            .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
            .borderRadius(Theme.BORDER_RADIUS_LARGE)
            .shadow(Theme.SHADOW_MEDIUM)
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 40 })
          .opacity(this.contentOpacity)
          .animation({
            duration: Theme.ANIMATION_NORMAL,
            curve: Curve.EaseOut
          })
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
        .backgroundColor(Theme.COLOR_OVERLAY)
        .onClick(() => {
          this.showSettingsDialog = false
        })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })

    Column({ space: 20 }) {
      // 图标
      Column() {
        Text('⚙️')
          .fontSize(40)
      }
      .width(72)
      .height(72)
      .borderRadius(36)
      .backgroundColor(Theme.COLOR_PRIMARY_BG)
      .justifyContent(FlexAlign.Center)

      Text('跳转到系统设置')
        .fontSize(Theme.FONT_SIZE_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)

      Text('即将打开本应用的系统设置页面，您可以在那里：')
        .fontSize(Theme.FONT_SIZE_MEDIUM)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .textAlign(TextAlign.Center)

      Column({ space: 10 }) {
        Row({ space: 8 }) {
          Text('🔔')
            .fontSize(Theme.FONT_SIZE_SMALL)
          Text('管理应用通知权限')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        Row({ space: 8 }) {
          Text('💾')
            .fontSize(Theme.FONT_SIZE_SMALL)
          Text('查看应用存储和缓存')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        Row({ space: 8 }) {
          Text('🔐')
            .fontSize(Theme.FONT_SIZE_SMALL)
          Text('配置应用权限设置')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 16 })

      Row({ space: 14 }) {
        Button('取消')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .border({ width: 1, color: Theme.COLOR_BORDER })
          .onClick(() => {
            this.showSettingsDialog = false
          })

        Button('前往设置')
          .layoutWeight(1)
          .height(52)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(Theme.COLOR_PRIMARY)
          .fontColor(Color.White)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .shadow(Theme.SHADOW_GLOW)
          .onClick(() => {
            this.showSettingsDialog = false
            this.openAppSettings()
          })
      }
      .width('100%')
    }
    .width('88%')
    .padding(28)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_XLARGE)
    .shadow(Theme.SHADOW_LARGE)
    .position({ x: '6%', y: '25%' })
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
