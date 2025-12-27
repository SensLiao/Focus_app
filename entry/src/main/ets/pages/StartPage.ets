/**
 * Task creation / edit page - 精致现代风格
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { TaskStore } from '../store/taskStore'
import { FocusStore } from '../store/focusStore'
import { SessionType } from '../model/FocusSession'
import { Theme } from '../common/theme'
import { SuccessAnimation } from '../components/SuccessAnimation'

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
  // 动画相关状态
  @State showSuccessAnimation: boolean = false
  @State headerOpacity: number = 0
  @State contentOpacity: number = 0

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

    // 入场动画
    setTimeout(() => {
      this.headerOpacity = 1
    }, 100)
    setTimeout(() => {
      this.contentOpacity = 1
    }, 200)
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row({ space: 16 }) {
          Button({ type: ButtonType.Circle }) {
            Text('←')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          .width(44)
          .height(44)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .onClick(() => {
            router.back()
          })

          Text(this.taskId !== null ? '编辑任务' : '新建任务')
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .width('100%')
        .padding({ left: 16, right: 20, top: 12, bottom: 12 })
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })
        .opacity(this.headerOpacity)
        .animation({
          duration: Theme.ANIMATION_NORMAL,
          curve: Curve.EaseOut
        })

        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(48)
              .color(Theme.COLOR_TEXT_PRIMARY)
            Text('加载中...')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .margin({ top: 16 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Column({ space: 24 }) {
            // 任务名称输入框
            Column({ space: 10 }) {
              Row({ space: 6 }) {
                Text('📝')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                Text('任务名称')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('*')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
              }

              TextInput({ placeholder: '给你的任务起个名字...', text: this.taskTitle })
                .width('100%')
                .height(56)
                .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1.5, color: Theme.COLOR_BORDER })
                .padding({ left: 18, right: 18 })
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .onChange((value: string) => {
                  this.taskTitle = value
                })
            }
            .alignItems(HorizontalAlign.Start)

            // 任务描述输入框
            Column({ space: 10 }) {
              Row({ space: 6 }) {
                Text('📋')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                Text('任务描述')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('(可选)')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }

              TextArea({ placeholder: '添加一些描述，帮助你更好地专注...', text: this.taskDescription })
                .width('100%')
                .height(140)
                .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1.5, color: Theme.COLOR_BORDER })
                .padding({ left: 18, right: 18, top: 16, bottom: 16 })
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .onChange((value: string) => {
                  this.taskDescription = value
                })
            }
            .alignItems(HorizontalAlign.Start)

            // 提示卡片
            Row({ space: 14 }) {
              Column() {
                Text('💡')
                  .fontSize(24)
              }
              .width(48)
              .height(48)
              .borderRadius(24)
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .justifyContent(FlexAlign.Center)

              Column({ space: 4 }) {
                Text('专注小贴士')
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.COLOR_TEXT_PRIMARY)
                Text('建议每次专注 25 分钟，然后休息 5 分钟')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding(16)
.backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .border({ width: 1, color: Theme.COLOR_BORDER })
            .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

            Blank()

            // 按钮区域
            Column({ space: 14 }) {
              Button(this.taskId !== null ? '保存更改' : '创建并开始专注')
                .width('100%')
                .height(58)
                .fontSize(Theme.FONT_SIZE_LARGE)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.taskTitle.trim().length > 0 ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_TEXT_TERTIARY)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1, color: this.taskTitle.trim().length > 0 ? Theme.COLOR_BORDER : Theme.COLOR_TEXT_LIGHT })
                .borderRadius(Theme.BORDER_RADIUS_XLARGE)
                .enabled(!this.saving && this.taskTitle.trim().length > 0)
                .shadow(Theme.SHADOW_SMALL)
                .onClick(() => {
                  if (this.taskId !== null) {
                    this.saveTask()
                  } else {
                    this.createTask()
                  }
                })

              if (this.taskId === null) {
                Button('无任务专注')
                  .width('100%')
                  .height(52)
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  .backgroundColor(Theme.COLOR_BACKGROUND)
                  .borderRadius(Theme.BORDER_RADIUS_LARGE)
                  .border({ width: 1, color: Theme.COLOR_BORDER })
                  .enabled(!this.saving)
                  .onClick(() => {
                    this.startWithoutTask()
                  })
              }
            }
            .padding({ bottom: 20 })
          }
          .padding({ left: 22, right: 22, top: 28, bottom: 28 })
          .layoutWeight(1)
          .backgroundColor(Theme.COLOR_BACKGROUND)
          .opacity(this.contentOpacity)
          .animation({
            duration: Theme.ANIMATION_NORMAL,
            curve: Curve.EaseOut
          })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.COLOR_BACKGROUND)

      // 成功动画
      SuccessAnimation({
        visible: $showSuccessAnimation,
        type: 'create',
        message: `任务 "${this.taskTitle}" 已创建`
      })
    }
    .width('100%')
    .height('100%')
  }

  private async saveTask() {
    if (this.taskId === null) {
      return
    }
    if (this.taskTitle.trim() === '') {
      promptAction.showToast({ message: '请输入任务名称' })
      return
    }
    this.saving = true
    const result = await TaskStore.updateTask(this.taskId, {
      title: this.taskTitle.trim(),
      description: this.taskDescription.trim() || undefined
    })
    this.saving = false
    if (result.ok) {
      promptAction.showToast({ message: '任务已更新' })
      router.back()
    } else {
      promptAction.showToast({ message: result.message ?? '更新失败' })
    }
  }

  private async createTask() {
    if (this.taskTitle.trim() === '') {
      promptAction.showToast({ message: '请输入任务名称' })
      return
    }
    this.saving = true
    const createResult = await TaskStore.createTask({
      title: this.taskTitle.trim(),
      description: this.taskDescription.trim() || undefined
    })
    if (!createResult.ok || createResult.data === undefined) {
      this.saving = false
      promptAction.showToast({ message: createResult.message ?? '创建失败' })
      return
    }

    // 显示成功动画
    this.showSuccessAnimation = true
    
    // 延迟跳转，让用户看到动画
    setTimeout(() => {
      this.saving = false
      const taskId = createResult.data
      router.replaceUrl({ url: 'pages/FocusPage', params: { pendingTaskId: taskId } })
    }, 1800)
  }

  private async startWithoutTask() {
    const focusResult = await FocusStore.startFocus(undefined, undefined, SessionType.NORMAL)
    if (focusResult.ok) {
      router.replaceUrl({ url: 'pages/FocusPage', params: { startAnonymous: true } })
    } else {
      promptAction.showToast({ message: focusResult.message ?? '无法开始专注' })
    }
  }
}
