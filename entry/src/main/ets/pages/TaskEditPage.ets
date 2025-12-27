/**
 * 任务编辑页
 */

import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore } from '../store/taskStore'
import { Theme } from '../common/theme'

@Entry
@Component
struct TaskEditPage {
  @State title: string = ''
  @State description: string = ''

  build() {
    Column() {
      // 顶部导航
      Row() {
        Button('< 返回')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .onClick(() => {
            router.back()
          })

        Text('新建任务')
          .fontSize(Theme.FONT_SIZE_LARGE)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 占位
        Text('')
          .width(60)
      }
      .width('100%')
      .padding(Theme.SPACE_MEDIUM)

      // 表单
      Column({ space: Theme.SPACE_LARGE }) {
        Column({ space: Theme.SPACE_SMALL }) {
          Text('任务标题')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)

          TextInput({ placeholder: '输入任务标题' })
            .onChange((value: string) => {
              this.title = value
            })
            .height(48)
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: Theme.SPACE_SMALL }) {
          Text('任务描述（可选）')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)

          TextArea({ placeholder: '输入任务描述' })
            .onChange((value: string) => {
              this.description = value
            })
            .height(120)
        }
        .alignItems(HorizontalAlign.Start)

        Button('创建任务')
          .width('100%')
          .height(50)
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
          .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
          .border({ width: 1, color: Theme.COLOR_BORDER })
          .onClick(() => {
            this.createTask()
          })
      }
      .width('100%')
      .padding(Theme.SPACE_LARGE)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  private async createTask() {
    if (this.title.trim() === '') {
      promptAction.showToast({ message: '请输入任务标题' })
      return
    }

    const result = await TaskStore.createTask({
      title: this.title.trim(),
      description: this.description.trim() || undefined
    })

    if (result.ok) {
      promptAction.showToast({ message: '任务已创建' })
      router.back()
    } else {
      promptAction.showToast({ message: result.message ?? 'Unknown error' })
    }
  }
}
