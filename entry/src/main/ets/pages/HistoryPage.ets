/**
 * 历史页 - 已完成任务和专注记录
 */

import router from '@ohos.router'
import { TaskRepo } from '../data/TaskRepo'
import { Task } from '../model/Task'
import { Theme } from '../common/theme'

@Entry
@Component
struct HistoryPage {
  @State completedTasks: Task[] = []
  @State loading: boolean = false

  async aboutToAppear() {
    await this.loadCompletedTasks()
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button('< 返回')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .onClick(() => {
            router.back()
          })

        Text('历史记录')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Text('')
          .width(60)
      }
      .width('100%')
      .padding(Theme.SPACE_MEDIUM)

      // 统计卡片
      Row({ space: Theme.SPACE_MEDIUM }) {
        Column() {
          Text(this.completedTasks.length.toString())
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_PRIMARY)

          Text('已完成任务')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

        Column() {
          Text(this.formatTotalTime())
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_SUCCESS)

          Text('总专注时长')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
      }
      .width('100%')
      .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM })

      // 任务列表
      if (this.loading) {
        Text('加载中...')
          .margin({ top: Theme.SPACE_LARGE })
      } else if (this.completedTasks.length === 0) {
        Text('暂无历史记录')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .margin({ top: Theme.SPACE_LARGE })
      } else {
        List({ space: Theme.SPACE_MEDIUM }) {
          ForEach(this.completedTasks, (task: Task) => {
            ListItem() {
              Row() {
                Column() {
                  Text(task.title)
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.formatDuration(task.totalFocusTime))
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_PRIMARY)
                    .margin({ top: 4 })

                  if (task.completedAt) {
                    Text(this.formatDate(task.completedAt))
                      .fontSize(Theme.FONT_SIZE_SMALL)
                      .fontColor(Theme.COLOR_TEXT_SECONDARY)
                      .margin({ top: 4 })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(Theme.SPACE_MEDIUM)
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
            }
          }, (task: Task) => task.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM, top: Theme.SPACE_MEDIUM })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  private async loadCompletedTasks() {
    this.loading = true
    const result = await TaskRepo.findCompleted(getContext(this))
    if (result.ok && result.data) {
      this.completedTasks = result.data
    }
    this.loading = false
  }

  private formatTotalTime(): string {
    const totalMs = this.completedTasks.reduce((sum, task) => sum + task.totalFocusTime, 0)
    const hours = Math.floor(totalMs / (1000 * 60 * 60))
    return `${hours}h`
  }

  private formatDuration(ms: number): string {
    const minutes = Math.floor(ms / (1000 * 60))
    const hours = Math.floor(minutes / 60)

    if (hours > 0) {
      return `${hours}h ${minutes % 60}m`
    } else {
      return `${minutes}m`
    }
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hour = date.getHours()
    const minute = date.getMinutes()

    return `${month}月${day}日 ${this.pad(hour)}:${this.pad(minute)}`
  }

  private pad(num: number): string {
    return num < 10 ? `0${num}` : `${num}`
  }
}
