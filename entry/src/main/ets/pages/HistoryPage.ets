/**
 * 历史页 - 已完成任务和专注记录（基于 Figma Design）
 */

import router from '@ohos.router'
import { TaskRepo } from '../data/TaskRepo'
import { Task } from '../model/Task'
import { BottomNav } from '../components/BottomNav'
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
      // 顶部标题
      Row() {
        Text('History')
          .fontSize(Theme.FONT_SIZE_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
          .layoutWeight(1)
      }
      .width('100%')
      .padding(Theme.SPACE_MEDIUM)

      // 统计卡片
      Row({ space: Theme.SPACE_MEDIUM }) {
        Column() {
          Text(this.completedTasks.length.toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_PRIMARY)

          Text('Completed Tasks')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .margin({ top: Theme.SPACE_TINY })
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
        .border({
          width: 1,
          color: Theme.COLOR_BORDER
        })

        Column() {
          Text(this.formatTotalTime())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_SUCCESS)

          Text('Total Focus Time')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .margin({ top: Theme.SPACE_TINY })
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
        .border({
          width: 1,
          color: Theme.COLOR_BORDER
        })
      }
      .width('100%')
      .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM })

      // 任务列表
      if (this.loading) {
        Column() {
          Text('Loading...')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.completedTasks.length === 0) {
        Column() {
          Text('No history yet')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: Theme.SPACE_MEDIUM }) {
          ForEach(this.completedTasks, (task: Task) => {
            ListItem() {
              Row() {
                Column() {
                  Text(task.title)
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    .fontWeight(FontWeight.Medium)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(this.formatDuration(task.totalFocusTime))
                    .fontSize(Theme.FONT_SIZE_SMALL)
                    .fontColor(Theme.COLOR_PRIMARY)
                    .margin({ top: Theme.SPACE_TINY })

                  if (task.completedAt) {
                    Text(this.formatDate(task.completedAt))
                      .fontSize(Theme.FONT_SIZE_SMALL)
                      .fontColor(Theme.COLOR_TEXT_SECONDARY)
                      .margin({ top: Theme.SPACE_TINY })
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')
              .padding(Theme.SPACE_MEDIUM)
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
              .border({
                width: 1,
                color: Theme.COLOR_BORDER
              })
            }
          }, (task: Task) => task.id.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ 
          left: Theme.SPACE_MEDIUM, 
          right: Theme.SPACE_MEDIUM, 
          top: Theme.SPACE_MEDIUM,
          bottom: Theme.SPACE_MEDIUM 
        })
      }

      // 底部导航栏
      BottomNav({ currentIndex: 1 })
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
