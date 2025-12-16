/**
 * 设置页面 - 基于 Figma Design
 */

import router from '@ohos.router'
import { BottomNav } from '../components/BottomNav'
import { Theme } from '../common/theme'

@Entry
@Component
struct SettingsPage {
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
      .padding(Theme.SPACE_MEDIUM)

      // 设置列表
      List() {
        // 通用设置部分
        ListItemGroup({ header: this.groupHeader('General') }) {
          ListItem() {
            this.settingItem('Notifications', 'Manage notification settings')
          }
          
          ListItem() {
            this.settingItem('Theme', 'Light mode')
          }

          ListItem() {
            this.settingItem('Language', 'English')
          }
        }

        // 专注设置部分
        ListItemGroup({ header: this.groupHeader('Focus') }) {
          ListItem() {
            this.settingItem('Default Focus Duration', '25 minutes')
          }

          ListItem() {
            this.settingItem('Default Break Duration', '5 minutes')
          }

          ListItem() {
            this.settingItem('Auto-start Break', 'Off')
          }
        }

        // 数据部分
        ListItemGroup({ header: this.groupHeader('Data') }) {
          ListItem() {
            this.settingItem('Export Data', 'Export your focus history')
          }

          ListItem() {
            this.settingItem('Clear History', 'Delete all focus records')
          }
        }

        // 关于部分
        ListItemGroup({ header: this.groupHeader('About') }) {
          ListItem() {
            this.settingItem('Version', '1.0.0')
          }

          ListItem() {
            this.settingItem('Privacy Policy', 'View privacy policy')
          }

          ListItem() {
            this.settingItem('Terms of Service', 'View terms of service')
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor(Theme.COLOR_BACKGROUND)

      // 底部导航栏
      BottomNav({ currentIndex: 2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  @Builder
  groupHeader(title: string) {
    Text(title)
      .fontSize(Theme.FONT_SIZE_SMALL)
      .fontColor(Theme.COLOR_TEXT_SECONDARY)
      .fontWeight(FontWeight.Medium)
      .padding({ 
        left: Theme.SPACE_MEDIUM, 
        right: Theme.SPACE_MEDIUM,
        top: Theme.SPACE_MEDIUM,
        bottom: Theme.SPACE_SMALL
      })
  }

  @Builder
  settingItem(title: string, subtitle: string) {
    Row() {
      Column() {
        Text(title)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)

        Text(subtitle)
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Image($r('app.media.layered_image'))
        .width(20)
        .height(20)
        .fillColor(Theme.COLOR_TEXT_TERTIARY)
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .onClick(() => {
      // TODO: 实现设置项点击处理
    })
  }
}
