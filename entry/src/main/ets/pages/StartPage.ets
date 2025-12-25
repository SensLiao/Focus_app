/**
 * Task creation / edit page - adapted to sample_frontend StartPage
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { SessionType } from '../model/FocusSession'
import { Theme } from '../common/theme'

interface RouterParams {
  taskId?: number
}

@Entry
@Component
struct StartPage {
  @State taskId: number | null = null
  @State taskTitle: string = ''
  @State taskDescription: string = ''
  @State loading: boolean = true
  @State saving: boolean = false

  async aboutToAppear() {
    TaskStore.init(getContext(this))
    FocusStore.init(getContext(this))

    const params = router.getParams() as RouterParams
    if (params && params.taskId !== undefined) {
      this.taskId = params.taskId
      const task = TaskStore.findTask(params.taskId)
      if (task) {
        this.taskTitle = task.title
        this.taskDescription = task.description ?? ''
      }
    }
    this.loading = false
  }

  build() {
    Column() {
      // 顶部导航栏
      Row({ space: 12 }) {
        Text('←')
          .fontSize(24)
          .fontColor(Theme.COLOR_TEXT_SECONDARY)
          .onClick(() => {
            router.back()
          })

        Text(this.taskId !== null ? 'Edit Task' : 'New Task')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
      }
      .width('100%')
      .height(60)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .border({
        width: { bottom: 1 },
        color: Theme.COLOR_BORDER
      })

      if (this.loading) {
        Column() {
          Text('加载中...')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 20 }) {
          // Task Name 输入框
          Column({ space: 8 }) {
            Text('任务名称')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
            TextInput({ placeholder: '输入任务名称', text: this.taskTitle })
              .width('100%')
              .height(52)
              .borderRadius(14)
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .padding({ left: 16, right: 16 })
              .fontSize(15)
              .onChange((value: string) => {
                this.taskTitle = value
              })
          }
          .alignItems(HorizontalAlign.Start)

          // Task Description 输入框
          Column({ space: 8 }) {
            Text('任务描述')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
            TextArea({ placeholder: '输入任务描述（可选）', text: this.taskDescription })
              .width('100%')
              .height(140)
              .borderRadius(14)
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .fontSize(15)
              .onChange((value: string) => {
                this.taskDescription = value
              })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          // 按钮区域
          Column({ space: 12 }) {
            Button(this.taskId !== null ? '更新' : '创建')
              .width('100%')
              .height(52)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(this.taskTitle.trim().length > 0 ? Theme.COLOR_PRIMARY : Theme.COLOR_TEXT_LIGHT)
              .borderRadius(26)
              .enabled(!this.saving && this.taskTitle.trim().length > 0)
              .shadow({
                radius: this.taskTitle.trim().length > 0 ? 12 : 0,
                color: this.taskTitle.trim().length > 0 ? '#2563EB30' : '#00000000',
                offsetX: 0,
                offsetY: 4
              })
              .onClick(() => {
                if (this.taskId !== null) {
                  this.saveTask()
                } else {
                  this.createTask()
                }
              })

            if (this.taskId === null) {
              Button('Start without a task')
                .width('100%')
                .height(48)
                .fontSize(15)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
                .backgroundColor(Theme.COLOR_BACKGROUND)
                .borderRadius(24)
                .enabled(!this.saving)
                .onClick(() => {
                  this.startWithoutTask()
                })
            }
          }
          .padding({ bottom: 16 })
        }
        .padding({ left: 20, right: 20, top: 24, bottom: 24 })
        .layoutWeight(1)
        .backgroundColor(Theme.COLOR_BACKGROUND)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  private async saveTask() {
    if (this.taskId === null) {
      return
    }
    if (this.taskTitle.trim() === '') {
      promptAction.showToast({ message: 'Please enter task name' })
      return
    }
    this.saving = true
    const result = await TaskStore.updateTask(this.taskId, {
      title: this.taskTitle.trim(),
      description: this.taskDescription.trim() || undefined
    })
    this.saving = false
    if (result.ok) {
      promptAction.showToast({ message: 'Task updated' })
      router.back()
    } else {
      promptAction.showToast({ message: result.message ?? 'Update failed' })
    }
  }

  private async createTask() {
    if (this.taskTitle.trim() === '') {
      promptAction.showToast({ message: 'Please enter task name' })
      return
    }
    this.saving = true
    const createResult = await TaskStore.createTask({
      title: this.taskTitle.trim(),
      description: this.taskDescription.trim() || undefined
    })
    if (!createResult.ok || createResult.data === undefined) {
      this.saving = false
      promptAction.showToast({ message: createResult.message ?? 'Create failed' })
      return
    }

    this.saving = false

    const taskId = createResult.data
    router.replaceUrl({ url: 'pages/FocusPage', params: { pendingTaskId: taskId } })
  }

  private async startWithoutTask() {
    const focusResult = await FocusStore.startFocus(undefined, undefined, SessionType.NORMAL)
    if (focusResult.ok) {
      router.replaceUrl({ url: 'pages/FocusPage', params: { startAnonymous: true } })
    } else {
      promptAction.showToast({ message: focusResult.message ?? 'Unable to start focus' })
    }
  }
}
