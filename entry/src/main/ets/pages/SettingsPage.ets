/**
 * 设置页面 - 基于 Figma Design
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
    Row({ space: Theme.SPACE_TINY }) {
      // 减少按钮
      Button({ type: ButtonType.Circle }) {
        Text('-')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontColor(this.value <= this.min ? Theme.COLOR_TEXT_TERTIARY : Theme.COLOR_PRIMARY)
      }
      .width(36)
      .height(36)
      .backgroundColor(Theme.COLOR_BACKGROUND)
      .enabled(this.value > this.min)
      .onClick(() => {
        if (this.value > this.min) {
          this.updateValue(this.value - this.step)
        }
      })

      // 数值显示
      Text(`${this.value}`)
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .width(48)
        .textAlign(TextAlign.Center)

      // 增加按钮
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontColor(this.value >= this.max ? Theme.COLOR_TEXT_TERTIARY : Theme.COLOR_PRIMARY)
      }
      .width(36)
      .height(36)
      .backgroundColor(Theme.COLOR_BACKGROUND)
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
  @State restMinutes: number = 5
  @State restIntervalHours: number = 0
  @State restIntervalMinutes: number = 25
  @State focusDuration: number = 25
  @State initialRestMinutes: number = 5
  @State initialRestIntervalHours: number = 0
  @State initialRestIntervalMinutes: number = 25

  async aboutToAppear() {
    // 初始化设置服务并加载设置
    await SettingsService.init(getContext(this))
    const settings = SettingsService.getSettings()
    this.notifyOn = settings.notificationsEnabled
    this.restMinutes = settings.defaultRestDuration
    this.focusDuration = settings.defaultFocusDuration
    // 将休息间隔分解为小时和分钟
    const totalMinutes = settings.defaultRestInterval
    this.restIntervalHours = Math.floor(totalMinutes / 60)
    this.restIntervalMinutes = totalMinutes % 60
    this.initialRestMinutes = this.restMinutes
    this.initialRestIntervalHours = this.restIntervalHours
    this.initialRestIntervalMinutes = this.restIntervalMinutes
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .border({
        width: { bottom: 1 },
        color: Theme.COLOR_BORDER
      })

      // 可滚动内容
      Scroll() {
        Column({ space: 16 }) {
          // 卡片1：通知设置
          Column({ space: 12 }) {
            Row() {
              Text('通知')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.notifyOn })
                .selectedColor(Theme.COLOR_PRIMARY)
                .width(50)
                .height(28)
                .onChange(async (val: boolean) => {
                  this.notifyOn = val
                  await SettingsService.setNotificationsEnabled(val)
                  promptAction.showToast({ message: val ? '已开启通知' : '已关闭通知' })
                })
            }
            .width('100%')

            Text('休息结束或专注暂停时接收通知')
              .fontSize(13)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(16)
          .shadow({
            radius: 4,
            color: '#0000000A',
            offsetX: 0,
            offsetY: 2
          })

          // 卡片2：专注设置
          Column({ space: 16 }) {
            Text('专注设置')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            // 默认专注时长
            Row() {
              Text('默认专注时长')
                .fontSize(15)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
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
              Text('默认休息时长')
                .fontSize(15)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
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
            Column({ space: 8 }) {
              Text('休息提醒间隔')
                .fontSize(15)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
                .width('100%')

              Text('每隔此时间提醒你休息一下')
                .fontSize(13)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
                .width('100%')

              Row({ space: 12 }) {
                // 小时选择
                NumberSelector({
                  value: this.$restIntervalHours,
                  min: 0,
                  max: 4,
                  step: 1,
                  unit: 'h',
                })

                Text(':')
                  .fontSize(20)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                // 分钟选择
                NumberSelector({
                  value: this.$restIntervalMinutes,
                  min: 0,
                  max: 55,
                  step: 5,
                  unit: 'min',
                })
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)

              if (this.hasRestSettingsChanges()) {
                Row() {
                  Blank()
                  Button('保存更改')
                    .fontSize(14)
                    .height(36)
                    .fontColor(Color.White)
                    .backgroundColor(Theme.COLOR_PRIMARY)
                    .borderRadius(18)
                    .onClick(async () => {
                      await this.saveRestSettings()
                    })
                }
                .width('100%')
                .margin({ top: 8 })
              }
            }
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(16)
          .shadow({
            radius: 4,
            color: '#0000000A',
            offsetX: 0,
            offsetY: 2
          })

          // 卡片3：关于
          Column({ space: 12 }) {
            Text('关于')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            Row() {
              Text('版本')
                .fontSize(15)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
              Blank()
              Text('1.0.0')
                .fontSize(15)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_DIVIDER)

            Row() {
              Text('使用指南')
                .fontSize(15)
                .fontColor(Theme.COLOR_PRIMARY)
              Blank()
              Text('→')
                .fontSize(16)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
            }
            .width('100%')
            .onClick(() => {
              router.pushUrl({ url: 'pages/GuidePage' })
            })
          }
          .width('100%')
          .padding(20)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(16)
          .shadow({
            radius: 4,
            color: '#0000000A',
            offsetX: 0,
            offsetY: 2
          })
        }
        .padding({ left: 16, right: 16, top: 16, bottom: 80 })
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
    promptAction.showToast({ message: 'Settings saved' })
  }
}
