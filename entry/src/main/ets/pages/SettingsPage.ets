/**
 * 设置页面 - 基于 Figma Design
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { BottomNav } from '../components/BottomNav'
import { Theme } from '../common/theme'
import { SettingsService } from '../services/SettingsService'

interface NumberSelectorParams {
  value: number
  min: number
  max: number
  step: number
  unit: string
  onChange: (val: number) => void
}

@Entry
@Component
struct SettingsPage {
  @State notifyOn: boolean = true
  @State restMinutes: number = 5
  @State restIntervalHours: number = 0
  @State restIntervalMinutes: number = 25
  @State focusDuration: number = 25

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
  }

  build() {
    Column() {
      // 顶部标题
      Row() {
        Text('Settings')
          .fontSize(Theme.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
      }
      .width('100%')
      .padding(Theme.SPACE_LARGE)

      // 可滚动内容
      Scroll() {
        Column({ space: Theme.SPACE_LARGE }) {
          // 卡片1：通知设置
          Column({ space: Theme.SPACE_MEDIUM }) {
            Row() {
              Text('Notifications')
                .fontSize(Theme.FONT_SIZE_LARGE)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
              Blank()
              Toggle({ type: ToggleType.Switch, isOn: this.notifyOn })
                .onChange(async (val: boolean) => {
                  this.notifyOn = val
                  await SettingsService.setNotificationsEnabled(val)
                  promptAction.showToast({ message: val ? '通知已开启' : '通知已关闭' })
                })
            }
            .width('100%')

            Text('启用后将在休息结束、专注暂停时收到通知')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
          }
          .width('100%')
          .padding(Theme.SPACE_LARGE)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
          .shadow({
            radius: Theme.SHADOW_SMALL.radius,
            color: Theme.SHADOW_SMALL.color,
            offsetX: Theme.SHADOW_SMALL.offsetX,
            offsetY: Theme.SHADOW_SMALL.offsetY
          })

          // 卡片2：专注设置
          Column({ space: Theme.SPACE_LARGE }) {
            Text('专注设置')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_BORDER)

            // 默认专注时长
            Row() {
              Text('默认专注时长')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
                .layoutWeight(1)
              this.NumberSelector({
                value: this.focusDuration,
                min: 5,
                max: 120,
                step: 5,
                unit: '分钟',
                onChange: async (val: number) => {
                  this.focusDuration = val
                  await SettingsService.setDefaultFocusDuration(val)
                }
              } as NumberSelectorParams)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_BORDER)

            // 默认休息时长
            Row() {
              Text('默认休息时长')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
                .layoutWeight(1)
              this.NumberSelector({
                value: this.restMinutes,
                min: 1,
                max: 30,
                step: 1,
                unit: '分钟',
                onChange: async (val: number) => {
                  this.restMinutes = val
                  await SettingsService.setDefaultRestDuration(val)
                }
              } as NumberSelectorParams)
            }
            .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_BORDER)

            // 休息提醒间隔
            Column({ space: Theme.SPACE_SMALL }) {
              Text('休息提醒间隔')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
                .width('100%')

              Text('专注达到此时长后将提醒你休息')
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
                .width('100%')

              Row({ space: Theme.SPACE_MEDIUM }) {
                // 小时选择
                this.NumberSelector({
                  value: this.restIntervalHours,
                  min: 0,
                  max: 4,
                  step: 1,
                  unit: '小时',
                  onChange: async (val: number) => {
                    this.restIntervalHours = val
                    await this.saveRestInterval()
                  }
                } as NumberSelectorParams)

                Text(':')
                  .fontSize(Theme.FONT_SIZE_LARGE)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                // 分钟选择
                this.NumberSelector({
                  value: this.restIntervalMinutes,
                  min: 0,
                  max: 55,
                  step: 5,
                  unit: '分钟',
                  onChange: async (val: number) => {
                    this.restIntervalMinutes = val
                    await this.saveRestInterval()
                  }
                } as NumberSelectorParams)
              }
              .width('100%')
              .justifyContent(FlexAlign.Start)
            }
          }
          .width('100%')
          .padding(Theme.SPACE_LARGE)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
          .shadow({
            radius: Theme.SHADOW_SMALL.radius,
            color: Theme.SHADOW_SMALL.color,
            offsetX: Theme.SHADOW_SMALL.offsetX,
            offsetY: Theme.SHADOW_SMALL.offsetY
          })

          // 卡片3：关于
          Column({ space: Theme.SPACE_MEDIUM }) {
            Text('关于')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .width('100%')

            Divider().strokeWidth(1).color(Theme.COLOR_BORDER)

            Row() {
              Text('版本')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
              Blank()
              Text('1.0.0')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .width('100%')

            Row() {
              Text('使用引导')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontColor(Theme.COLOR_PRIMARY)
            }
            .width('100%')
            .onClick(() => {
              router.pushUrl({ url: 'pages/GuidePage' })
            })
          }
          .width('100%')
          .padding(Theme.SPACE_LARGE)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
          .shadow({
            radius: Theme.SHADOW_SMALL.radius,
            color: Theme.SHADOW_SMALL.color,
            offsetX: Theme.SHADOW_SMALL.offsetX,
            offsetY: Theme.SHADOW_SMALL.offsetY
          })
        }
        .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM, bottom: Theme.SPACE_LARGE })
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
  private async saveRestInterval() {
    const totalMinutes = this.restIntervalHours * 60 + this.restIntervalMinutes
    if (totalMinutes > 0) {
      await SettingsService.setDefaultRestInterval(totalMinutes)
    }
  }
  @Builder
  NumberSelector(params: NumberSelectorParams) {
    Row({ space: Theme.SPACE_TINY }) {
      // 减少按钮
      Button({ type: ButtonType.Circle }) {
        Text('-')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontColor(params.value <= params.min ? Theme.COLOR_TEXT_TERTIARY : Theme.COLOR_PRIMARY)
      }
      .width(36)
      .height(36)
      .backgroundColor(Theme.COLOR_BACKGROUND)
      .enabled(params.value > params.min)
      .onClick(() => {
        if (params.value > params.min) {
          params.onChange(params.value - params.step)
        }
      })

      // 数值显示
      Text(`${params.value}`)
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .width(48)
        .textAlign(TextAlign.Center)

      // 增加按钮
      Button({ type: ButtonType.Circle }) {
        Text('+')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontColor(params.value >= params.max ? Theme.COLOR_TEXT_TERTIARY : Theme.COLOR_PRIMARY)
      }
      .width(36)
      .height(36)
      .backgroundColor(Theme.COLOR_BACKGROUND)
      .enabled(params.value < params.max)
      .onClick(() => {
        if (params.value < params.max) {
          params.onChange(params.value + params.step)
        }
      })
    }
  }
}
