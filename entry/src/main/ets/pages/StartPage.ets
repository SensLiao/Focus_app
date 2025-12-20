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
      Row({ space: 12 }) {
        Text('<')
          .fontSize(24)
          .fontColor('#1A1A2E')
          .onClick(() => {
            router.back()
          })

        Text(this.taskId !== null ? 'Edit Task' : 'New Task')
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A2E')
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)
      .border({
        width: { bottom: 1 },
        color: Theme.COLOR_BORDER
      })

      if (this.loading) {
        Column() {
          Text('Loading...')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Column({ space: 16 }) {
          Column({ space: 8 }) {
            Text('Task Name')
              .fontSize(16)
              .fontColor('#1A1A2E')
            TextInput({ placeholder: 'Enter task name', text: this.taskTitle })
              .width('100%')
              .height(52)
              .borderRadius(12)
              .backgroundColor(Color.White)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .padding({ left: 12, right: 12 })
              .onChange((value: string) => {
                this.taskTitle = value
              })
          }

          Column({ space: 8 }) {
            Text('Task Description')
              .fontSize(16)
              .fontColor('#1A1A2E')
            TextArea({ placeholder: 'Enter task description (optional)', text: this.taskDescription })
              .width('100%')
              .height(140)
              .borderRadius(12)
              .backgroundColor(Color.White)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .padding({ left: 12, right: 12, top: 12, bottom: 12 })
              .onChange((value: string) => {
                this.taskDescription = value
              })
          }

          Column({ space: 12 }) {
            Button(this.taskId !== null ? 'Update' : 'Create')
              .width('100%')
              .height(56)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .borderRadius(16)
              .enabled(!this.saving && this.taskTitle.trim().length > 0)
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
                .height(52)
                .fontSize(15)
                .fontColor('#4B5563')
                .backgroundColor('#F3F4F6')
                .borderRadius(14)
                .enabled(!this.saving)
                .onClick(() => {
                  this.startWithoutTask()
                })
            }
          }
          .padding({ top: 12 })
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 32 })
        .layoutWeight(1)
        .backgroundColor('#F7F8FA')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
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
