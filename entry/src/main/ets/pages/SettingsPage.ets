/**
 * 设置页面 - 精致现代风格
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { BottomNav } from '../components/BottomNav'
import { Theme } from '../common/theme'
import { SettingsService } from '../services/SettingsService'

@Component
struct NumberSelector {
  @Link value: number
  @Prop min: number = 0
  @Prop max: number = 0
  @Prop step: number = 1
  @Prop unit: string = ''
  onChange?: (val: number) => void

  private updateValue(next: number) {
    this.value = next
    if (this.onChange) {
      this.onChange(next)
    }
  }

  build() {
    Row({ space: 8 }) {
      // 减少按钮
      Button({ type: ButtonType.Circle }) {
        Text('-')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.value <= this.min ? Theme.COLOR_TEXT_TERTIARY : Theme.COLOR_PRIMARY)
      }
      .width(42)
      .height(42)
      .backgroundColor(this.value <= this.min ? Theme.COLOR_BACKGROUND : Theme.COLOR_PRIMARY_BG)
      .enabled(this.value > this.min)
      .onClick(() => {
        if (this.value > this.min) {
          this.updateValue(this.value - this.step)
        }
      })

      // 数值显示
      Column() {
        Text(`${this.value}`)
          .fontSize(Theme.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_PRIMARY)
      }
      .width(56)
      .justifyContent(FlexAlign.Center)

      // 增加按钮
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.value >= this.max ? Theme.COLOR_TEXT_TERTIARY : Theme.COLOR_PRIMARY)
      }
      .width(42)
      .height(42)
      .backgroundColor(this.value >= this.max ? Theme.COLOR_BACKGROUND : Theme.COLOR_PRIMARY_BG)
      .enabled(this.value < this.max)
      .onClick(() => {
        if (this.value < this.max) {
          this.updateValue(this.value + this.step)
        }
      })
    }
  }
}

@Entry
@Component
struct SettingsPage {
  @State notifyOn: boolean = true
  @State allowRest: boolean = true
  @State restMinutes: number = 5
  @State restIntervalHours: number = 0
  @State restIntervalMinutes: number = 25
  @State focusDuration: number = 25
  @State initialRestMinutes: number = 5
  @State initialRestIntervalHours: number = 0
  @State initialRestIntervalMinutes: number = 25
  @State togglesReady: boolean = false
  @State headerOpacity: number = 0
  @State contentOpacity: number = 0

  async aboutToAppear() {
    // 初始化设置服务并加载设置
    await SettingsService.init(getContext(this))
    const settings = SettingsService.getSettings()
    this.notifyOn = settings.notificationsEnabled
    this.allowRest = settings.restEnabled
    this.restMinutes = settings.defaultRestDuration
    this.focusDuration = settings.defaultFocusDuration
    // 将休息间隔分解为小时和分钟
    const totalMinutes = settings.defaultRestInterval
    this.restIntervalHours = Math.floor(totalMinutes / 60)
    this.restIntervalMinutes = totalMinutes % 60
    this.initialRestMinutes = this.restMinutes
    this.initialRestIntervalHours = this.restIntervalHours
    this.initialRestIntervalMinutes = this.restIntervalMinutes
    this.togglesReady = true

    // 入场动画
    setTimeout(() => {
      this.headerOpacity = 1
    }, 100)
    setTimeout(() => {
      this.contentOpacity = 1
    }, 200)
  }

  build() {
    Column() {
      // 顶部标题 - 精致样式
      Row() {
        Column({ space: 2 }) {
          Text('⚙️')
            .fontSize(28)
          Text('设置')
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .alignItems(VerticalAlign.Center)
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

      // 可滚动内容
      Scroll() {
        Column({ space: 20 }) {
          // 卡片1：通知设置
          Column({ space: 16 }) {
            Row({ space: 8 }) {
              Text('🔔')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
              Text('通知设置')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            Row() {
              Column({ space: 4 }) {
                Text('通知提醒')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('在专注结束时发送提醒')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.notifyOn })
                .selectedColor(Theme.COLOR_PRIMARY)
                .width(52)
                .height(30)
                .onChange(async (val: boolean) => {
                  if (!this.togglesReady) {
                    this.notifyOn = val
                    return
                  }
                  if (!val) {
                    AlertDialog.show({
                      title: '关闭通知？',
                      message: '通知用于提醒你返回专注，是应用必要功能。',
                      primaryButton: {
                        value: '取消',
                        action: () => {
                          this.notifyOn = true
                        }
                      },
                      secondaryButton: {
                        value: '关闭',
                        fontColor: Theme.COLOR_ERROR,
                        action: async () => {
                          this.notifyOn = false
                          await SettingsService.setNotificationsEnabled(false)
                        }
                      }
                    })
                    return
                  }
                  this.notifyOn = true
                  await SettingsService.setNotificationsEnabled(true)
                  promptAction.showToast({ message: '已开启通知' })
                })
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            Row() {
              Column({ space: 4 }) {
                Text('允许休息')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('在专注过程中安排休息时间')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.allowRest })
                .selectedColor(Theme.COLOR_PRIMARY)
                .width(52)
                .height(30)
                .onChange(async (val: boolean) => {
                  if (!this.togglesReady) {
                    this.allowRest = val
                    return
                  }
                  if (!val) {
                    AlertDialog.show({
                      title: '关闭休息？',
                      message: '关闭休息后，专注过程中不会安排休息，但你仍可继续专注。',
                      primaryButton: {
                        value: '取消',
                        action: () => {
                          this.allowRest = true
                        }
                      },
                      secondaryButton: {
                        value: '关闭',
                        fontColor: Theme.COLOR_ERROR,
                        action: async () => {
                          this.allowRest = false
                          await SettingsService.setRestEnabled(false)
                        }
                      }
                    })
                    return
                  }
                  this.allowRest = true
                  await SettingsService.setRestEnabled(true)
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(22)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .shadow(Theme.SHADOW_MEDIUM)

          // 卡片2：专注设置
          Column({ space: 18 }) {
            Row({ space: 8 }) {
              Text('🎯')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
              Text('专注设置')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            // 默认专注时长
            Row() {
              Column({ space: 4 }) {
                Text('默认专注时长')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('分钟')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              NumberSelector({
                value: this.$focusDuration,
                min: 5,
                max: 120,
                step: 5,
                unit: 'min',
                onChange: async (val: number) => {
                  await SettingsService.setDefaultFocusDuration(val)
                }
              })
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            // 默认休息时长
            Row() {
              Column({ space: 4 }) {
                Text('默认休息时长')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('分钟')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              
              NumberSelector({
                value: this.$restMinutes,
                min: 1,
                max: 30,
                step: 1,
                unit: 'min',
              })
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            // 休息提醒间隔
            Column({ space: 12 }) {
              Column({ space: 4 }) {
                Text('休息提醒间隔')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('每隔此时间提醒你休息一下')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .width('100%')

              Row({ space: 16 }) {
                // 小时选择
                Row({ space: 6 }) {
                  NumberSelector({
                    value: this.$restIntervalHours,
                    min: 0,
                    max: 4,
                    step: 1,
                    unit: 'h',
                  })
                  Text('时')
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_TEXT_SECONDARY)
                }

                Text(':')
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  
                // 分钟选择
                Row({ space: 6 }) {
                  NumberSelector({
                    value: this.$restIntervalMinutes,
                    min: 0,
                    max: 55,
                    step: 5,
                    unit: 'min',
                  })
                  Text('分')
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_TEXT_SECONDARY)
                }
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)

              if (this.hasRestSettingsChanges()) {
                Button('保存更改')
                  .width('100%')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .height(48)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .backgroundColor(Theme.COLOR_PRIMARY)
                  .borderRadius(Theme.BORDER_RADIUS_LARGE)
                  .shadow(Theme.SHADOW_GLOW)
                  .margin({ top: 8 })
                  .onClick(async () => {
                    await this.saveRestSettings()
                  })
              }
            }
          }
          .width('100%')
          .padding(22)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .shadow(Theme.SHADOW_MEDIUM)

          // 卡片3：关于
          Column({ space: 16 }) {
            Row({ space: 8 }) {
              Text('ℹ️')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
              Text('关于')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            Row() {
              Column({ space: 4 }) {
                Text('版本号')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }
              .alignItems(HorizontalAlign.Start)
              
              Blank()
              
              Text('1.0.0')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.COLOR_PRIMARY)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(Theme.COLOR_PRIMARY_BG)
                .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            Row() {
              Row({ space: 8 }) {
                Text('📖')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                Text('使用指南')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_PRIMARY)
              }
              Blank()
              Text('›')
                .fontSize(Theme.FONT_SIZE_TITLE)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/GuidePage' })
            })
          }
          .width('100%')
          .padding(22)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .shadow(Theme.SHADOW_MEDIUM)
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 100 })
        .opacity(this.contentOpacity)
        .animation({
          duration: Theme.ANIMATION_NORMAL,
          curve: Curve.EaseOut
        })
      }
      .layoutWeight(1)

      // 底部导航栏
      BottomNav({ currentIndex: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  // 保存休息间隔设置
  private hasRestSettingsChanges(): boolean {
    return this.restMinutes !== this.initialRestMinutes
      || this.restIntervalHours !== this.initialRestIntervalHours
      || this.restIntervalMinutes !== this.initialRestIntervalMinutes
  }

  private async saveRestSettings() {
    const totalMinutes = this.restIntervalHours * 60 + this.restIntervalMinutes
    await SettingsService.setDefaultRestDuration(this.restMinutes)
    await SettingsService.setDefaultRestInterval(totalMinutes)
    this.initialRestMinutes = this.restMinutes
    this.initialRestIntervalHours = this.restIntervalHours
    this.initialRestIntervalMinutes = this.restIntervalMinutes
    promptAction.showToast({ message: '设置已保存' })
  }
}
