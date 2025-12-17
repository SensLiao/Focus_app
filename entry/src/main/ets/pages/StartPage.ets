/**
 * 启动配置页 - 极简现代风格（Minimalist Design）
 * 用户在此配置专注参数，然后启动会话
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { FocusStore } from '../store/focusStore'
import { TaskStore } from '../store/taskStore'
import { SessionType } from '../model/FocusSession'
import { SessionRepo } from '../data/SessionRepo'

interface RouterParams {
  taskId?: number
  taskTitle?: string
}

@Entry
@Component
struct StartPage {
  @State taskId: number | null = null
  @State taskTitle: string = 'Anonymous'
  @State isCountdownMode: boolean = false
  @State countdownMinutes: number = 25
  @State restCount: number = 0
  @State restTimeMinutes: number = 0
  @State sessionCount: number = 0
  async aboutToAppear() {
    // 从路由参数获取taskId和taskTitle
    const params = router.getParams() as RouterParams
    if (params?.taskId) {
      this.taskId = params.taskId
      this.taskTitle = params.taskTitle ?? 'Anonymous'
      // 也可以从TaskStore查找确认
      const task = TaskStore.findTask(this.taskId)
      if (task) {
        this.taskTitle = task.title
      }
    }

    // 加载统计数据
    await this.loadStats()
  }

  // 加载统计数据
  private async loadStats() {
    const ctx = getContext(this)
    const stats = await SessionRepo.getStats(ctx)
    
    if (stats.ok && stats.data) {
      this.sessionCount = stats.data.sessionCount
    }
  }
  // 开始专注会话
  private async startFocusSession() {
    const sessionType = this.isCountdownMode ? SessionType.COUNTDOWN : SessionType.NORMAL
    const timeLimitMs = this.isCountdownMode ? this.countdownMinutes * 60 * 1000 : undefined
    const taskId = this.taskId !== null ? this.taskId : undefined
    
    const result = await FocusStore.startFocus(taskId, timeLimitMs, sessionType)
    if (result.ok) {
      // 使用replaceUrl替换当前页面，防止返回到配置页
      router.replaceUrl({ url: 'pages/FocusPage' })
    } else {
      promptAction.showToast({ message: result.message ?? '启动失败' })
    }
  }

  // 创建任务
  private createTask() {
    router.push({ url: 'pages/TaskEditPage' })
  }

  // 返回首页
  private goBack() {
    router.back()
  }

  // 查看详情
  private viewDetail() {
    router.push({ url: 'pages/HistoryPage' })
  }

  build() {
    Column() {
      // ====== A. Header ======
      Row() {
        // 返回按钮
        Text('←')
          .fontSize(24)
          .fontColor('#1A1A2E')
          .onClick(() => {
            this.goBack()
          })

        Blank()

        // 页面标题
        Text(this.taskTitle)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1A1A2E')

        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20 })
      .alignItems(VerticalAlign.Center)

      // ====== B. Main Timer Section ======
      Column() {
        // 大圆形进度指示器（静态占位）
        Stack() {
          // 外圈背景（淡紫色）
          Circle()
            .width(280)
            .height(280)
            .fill('#E0E0F5')
            .shadow({
              radius: 24,
              color: '#3B66F520',
              offsetX: 0,
              offsetY: 8
            })

          // 圆内内容
          Column({ space: 12 }) {
            Text('Focus time')
              .fontSize(14)
              .fontColor('#8F9098')

            Text('0:00')
              .fontSize(64)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A1A2E')

            Text('Total focus: 0:00')
              .fontSize(12)
              .fontColor('#8F9098')
          }
        }
        .margin({ top: 40, bottom: 40 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)

      // ====== C. Mode Toggle ======
      Row({ space: 12 }) {
        Toggle({ type: ToggleType.Switch, isOn: this.isCountdownMode })
          .selectedColor('#2F54EB')
          .onChange((isOn: boolean) => {
            this.isCountdownMode = isOn
          })

        Text('Countdown Mode')
          .fontSize(16)
          .fontColor('#1A1A2E')
      }
      .width('100%')
      .padding({ left: 24, right: 24 })
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 16 })

      // 倒计时时长设置（仅倒计时模式显示）
      if (this.isCountdownMode) {
        Row({ space: 12 }) {
          Text('Duration:')
            .fontSize(14)
            .fontColor('#8F9098')

          Button(`${this.countdownMinutes} min`)
            .fontSize(14)
            .height(36)
            .backgroundColor('#F5F5F7')
            .fontColor('#1A1A2E')
            .borderRadius(8)
            .onClick(() => {
              // 简单的时长选择（可扩展为picker）
              if (this.countdownMinutes === 25) {
                this.countdownMinutes = 45
              } else if (this.countdownMinutes === 45) {
                this.countdownMinutes = 60
              } else {
                this.countdownMinutes = 25
              }
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 16 })
      }

      // ====== D. Primary Action Buttons ======
      Column({ space: 12 }) {
        // 主按钮：开始专注
        Button('Start Focus Session')
          .width('100%')
          .height(56)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#2F54EB')
          .borderRadius(28)
          .shadow({
            radius: 12,
            color: '#2F54EB40',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => {
            this.startFocusSession()
          })

        // 次要按钮：创建任务（仅无任务时显示）
        if (this.taskId === null) {
          Button('Create Task First')
            .width('100%')
            .height(48)
            .fontSize(14)
            .fontWeight(FontWeight.Regular)
            .fontColor('#2F54EB')
            .backgroundColor('#F5F5F7')
            .borderRadius(24)
            .onClick(() => {
              this.createTask()
            })
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 20 })

      // ====== E. Statistics Cards ======
      Column({ space: 12 }) {
        // Card 1: 休息统计
        Row() {
          Column() {
            Text('Rest Count')
              .fontSize(12)
              .fontColor('#8F9098')
            Text(this.restCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A2E')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column() {
            Text('Rest Time')
              .fontSize(12)
              .fontColor('#8F9098')
            Text(`${this.restTimeMinutes} min`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A2E')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: '#1A1A2E10',
          offsetX: 0,
          offsetY: 2
        })

        // Card 2: 会话统计
        Row() {
          Column() {
            Text('Focus session')
              .fontSize(12)
              .fontColor('#8F9098')
            Text(this.sessionCount.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1A1A2E')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Text('View Detail')
            .fontSize(14)
            .fontColor('#2F54EB')
            .onClick(() => {
              this.viewDetail()
            })
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: '#1A1A2E10',
          offsetX: 0,
          offsetY: 2
        })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F9FAFB')
  }
}
