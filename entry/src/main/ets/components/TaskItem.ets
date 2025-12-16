/**
 * 任务列表项组件 - 基于 Figma Design
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
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.task.description) {
          Text(this.task.description)
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: Theme.SPACE_TINY })
        }

        // 专注时长标签
        if (this.task.totalFocusTime > 0) {
          Row() {
            Text(this.formatDuration(this.task.totalFocusTime))
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_PRIMARY)
          }
          .padding({ 
            left: Theme.SPACE_SMALL, 
            right: Theme.SPACE_SMALL,
            top: Theme.SPACE_TINY,
            bottom: Theme.SPACE_TINY
          })
          .backgroundColor('#EFF6FF')
          .borderRadius(Theme.BORDER_RADIUS_SMALL)
          .margin({ top: Theme.SPACE_SMALL })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 开始按钮
      Button('Start')
        .fontSize(Theme.FONT_SIZE_SMALL)
        .height(36)
        .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM })
        .backgroundColor(Theme.COLOR_PRIMARY)
        .borderRadius(Theme.BORDER_RADIUS_SMALL)
        .onClick(() => {
          if (this.onStart) {
            this.onStart(this.task)
          }
        })
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
    .border({
      width: 1,
      color: Theme.COLOR_BORDER
    })
    .onClick(() => {
      if (this.onTap) {
        this.onTap(this.task)
      }
    })
    // 添加长按删除功能
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          AlertDialog.show({
            title: '删除任务',
            message: `确定要删除任务"${this.task.title}"吗？`,
            primaryButton: {
              value: '取消',
              action: () => {}
            },
            secondaryButton: {
              value: '删除',
              fontColor: Theme.COLOR_ERROR,
              action: () => {
                if (this.onDelete) {
                  this.onDelete(this.task)
                }
              }
            }
          })
        })
    )
  }

  private formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)

    if (hours > 0) {
      return `${hours}h ${minutes % 60}m`
    } else if (minutes > 0) {
      return `${minutes}m`
    } else {
      return `${seconds}s`
    }
  }
}
