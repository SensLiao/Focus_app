/**
 * 专注计时器组件
 */

import { Theme } from '../common/theme'

@Component
export struct FocusTimer {
  @Prop elapsedMs: number = 0
  @Prop segmentIndex: number = 1
  @Prop taskTitle: string = '匿名专注'

  build() {
    Column() {
      // 任务标题
      Text(this.taskTitle)
        .fontSize(Theme.FONT_SIZE_LARGE)
        .fontColor(Theme.COLOR_TEXT_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)

      // 段数提示
      Text(`第 ${this.segmentIndex} 段`)
        .fontSize(Theme.FONT_SIZE_SMALL)
        .fontColor(Theme.COLOR_TEXT_SECONDARY)
        .margin({ top: Theme.SPACE_SMALL })

      // 计时器显示
      Text(this.formatTime(this.elapsedMs))
        .fontSize(72)
        .fontColor(Theme.COLOR_PRIMARY)
        .fontWeight(FontWeight.Bold)
        .margin({ top: Theme.SPACE_LARGE })
        .fontFamily('monospace')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000)
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60

    if (hours > 0) {
      return `${this.pad(hours)}:${this.pad(minutes)}:${this.pad(seconds)}`
    } else {
      return `${this.pad(minutes)}:${this.pad(seconds)}`
    }
  }

  private pad(num: number): string {
    return num < 10 ? `0${num}` : `${num}`
  }
}
