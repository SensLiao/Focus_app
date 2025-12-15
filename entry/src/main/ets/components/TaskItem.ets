/**
 * 任务列表项组件
 */

import { Task } from '../model/Task'
import { Theme } from '../common/theme'

@Component
export struct TaskItem {
  @Prop task: Task
  onTap?: (task: Task) => void
  onStart?: (task: Task) => void
  onDelete?: (task: Task) => void

  build() {
    Row() {
      // 任务信息
      Column() {
        Text(this.task.title)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.task.description) {
          Text(this.task.description)
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }

        // 专注时长
        if (this.task.totalFocusTime > 0) {
          Text(this.formatDuration(this.task.totalFocusTime))
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_PRIMARY)
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 操作按钮
      Row() {
        Button('开始')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(32)
          .backgroundColor(Theme.COLOR_PRIMARY)
          .onClick(() => {
            if (this.onStart) {
              this.onStart(this.task)
            }
          })

        Button('删除')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(32)
          .backgroundColor(Theme.COLOR_ERROR)
          .margin({ left: Theme.SPACE_SMALL })
          .onClick(() => {
            if (this.onDelete) {
              this.onDelete(this.task)
            }
          })
      }
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.task)
      }
    })
  }

  private formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)

    if (hours > 0) {
      return `${hours}小时${minutes % 60}分钟`
    } else if (minutes > 0) {
      return `${minutes}分钟`
    } else {
      return `${seconds}秒`
    }
  }
}
