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
  onResume?: (task: Task) => void  // 新增：恢复活动会话
  onDelete?: (task: Task) => void

  // 判断是否为活动任务
  private isActiveTask(): boolean {
    return this.task.activeSessionId !== undefined && this.task.activeSessionId !== null
  }

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

        // 专注时长和会话计数标签
        Row({ space: Theme.SPACE_SMALL }) {
          if (this.task.totalFocusTime > 0) {
            Text(this.formatDuration(this.task.totalFocusTime))
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_PRIMARY)
              .padding({ 
                left: Theme.SPACE_SMALL, 
                right: Theme.SPACE_SMALL,
                top: Theme.SPACE_TINY,
                bottom: Theme.SPACE_TINY
              })
              .backgroundColor('#EFF6FF')
              .borderRadius(Theme.BORDER_RADIUS_SMALL)
          }
          
          if (this.task.sessionCount > 0) {
            Text(`${this.task.sessionCount} sessions`)
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .padding({ 
                left: Theme.SPACE_SMALL, 
                right: Theme.SPACE_SMALL,
                top: Theme.SPACE_TINY,
                bottom: Theme.SPACE_TINY
              })
              .backgroundColor('#F5F5F5')
              .borderRadius(Theme.BORDER_RADIUS_SMALL)
          }
        }
        .margin({ top: Theme.SPACE_SMALL })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 根据是否活动任务显示不同按钮
      if (this.isActiveTask()) {
        // 活动任务：显示紫色咖啡图标
        Button({ type: ButtonType.Circle }) {
          Text('☕')
            .fontSize(24)
        }
        .width(50)
        .height(50)
        .backgroundColor('#B37FEB')  // 渐变紫
        .borderRadius(25)
        .shadow({
          radius: 12,
          color: '#B37FEB33',
          offsetX: 0,
          offsetY: 4
        })
        .onClick(() => {
          if (this.onResume) {
            this.onResume(this.task)
          }
        })
        // 添加脉动动画提示
        .animation({
          duration: 1500,
          curve: Curve.EaseInOut,
          iterations: -1,  // 无限循环
          playMode: PlayMode.Alternate
        })
      } else {
        // 普通任务：显示绿色开始按钮
        Button('Start')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(40)
          .padding({ left: Theme.SPACE_LARGE, right: Theme.SPACE_LARGE })
          .backgroundColor(Theme.COLOR_PRIMARY)
          .borderRadius(Theme.BORDER_RADIUS_LARGE)
          .fontWeight(FontWeight.Medium)
          .shadow({
            radius: Theme.SHADOW_SMALL.radius,
            color: Theme.SHADOW_SMALL.color,
            offsetX: Theme.SHADOW_SMALL.offsetX,
            offsetY: Theme.SHADOW_SMALL.offsetY
          })
          .onClick(() => {
            if (this.onStart) {
              this.onStart(this.task)
            }
          })
      }
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
