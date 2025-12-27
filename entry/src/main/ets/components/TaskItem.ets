/**
 * Task list item
 */
import { Task } from '../model/Task'
import { Theme } from '../common/theme'

@Component
export struct TaskItem {
  @Prop task: Task
  @Prop isResting: boolean = false
  onTap?: (task: Task) => void
  onStart?: (task: Task) => void
  onResume?: (task: Task) => void
  onDelete?: (task: Task) => void

  private isActiveTask(): boolean {
    return this.task.activeSessionId !== undefined && this.task.activeSessionId !== null
  }

  build() {
    Row() {
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

        Row({ space: Theme.SPACE_SMALL }) {
          if (this.task.totalFocusTime > 0) {
            Text(this.formatDuration(this.task.totalFocusTime))
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .padding({
                left: Theme.SPACE_SMALL,
                right: Theme.SPACE_SMALL,
                top: Theme.SPACE_TINY,
                bottom: Theme.SPACE_TINY
              })
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .border({ width: 1, color: Theme.COLOR_BORDER })
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
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .borderRadius(Theme.BORDER_RADIUS_SMALL)
          }
        }
        .margin({ top: Theme.SPACE_SMALL })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.isActiveTask()) {
        Button({ type: ButtonType.Circle }) {
          Text(this.isResting ? '☕' : '▶')
            .fontSize(24)
        }
        .width(50)
        .height(50)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({ width: 1, color: Theme.COLOR_BORDER })
        .borderRadius(25)
        .shadow(Theme.SHADOW_SMALL)
        .onClick(() => {
          if (this.onResume) {
            this.onResume(this.task)
          }
        })
        .animation({
          duration: 1500,
          curve: Curve.EaseInOut,
          iterations: -1,
          playMode: PlayMode.Alternate
        })
      } else {
        Button('Start')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(40)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
          .padding({ left: Theme.SPACE_LARGE, right: Theme.SPACE_LARGE })
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .border({ width: 1, color: Theme.COLOR_BORDER })
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
    .gesture(
      LongPressGesture({ repeat: false })
        .onAction(() => {
          AlertDialog.show({
            title: 'Delete task',
            message: `Delete task "${this.task.title}"?`,
            primaryButton: {
              value: 'Cancel',
              action: () => {}
            },
            secondaryButton: {
              value: 'Delete',
              fontColor: Theme.COLOR_TEXT_PRIMARY,
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

