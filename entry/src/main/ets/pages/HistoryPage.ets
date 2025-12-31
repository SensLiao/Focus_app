/**
 * History page - completed sessions with stats filter.
 */

import router from '@ohos.router'
import inputMethod from '@ohos.inputMethod'
import { TaskRepo } from '../data/TaskRepo'
import { SessionRepo } from '../data/SessionRepo'
import { SegmentRepo } from '../data/SegmentRepo'
import { BreakRepo } from '../data/BreakRepo'
import { Task } from '../model/Task'
import { FocusSession, SessionType } from '../model/FocusSession'
import { FocusSegment } from '../model/FocusSegment'
import { BreakEvent } from '../model/BreakEvent'
import { SessionStatus } from '../model/SessionStatus'
import { BottomNav } from '../components/BottomNav'
import { OnboardingOverlay } from '../components/OnboardingOverlay'
import { Theme } from '../common/theme'
import { getOnboardingStep, OnboardingRect, shouldShowOnboarding } from '../onboarding/OnboardingFlow'

class FocusSessionCopy implements FocusSession {
  id: number
  taskId?: number
  startAt: number
  endAt?: number
  status: SessionStatus
  actualFocusDuration: number
  totalDuration: number
  breakCount: number
  interruptionReason?: string
  timeLimitMs?: number
  sessionType: SessionType
  restIntervalMs?: number
  restDurationMs?: number

  constructor(session: FocusSession) {
    this.id = session.id
    this.taskId = session.taskId
    this.startAt = session.startAt
    this.endAt = session.endAt
    this.status = session.status
    this.actualFocusDuration = session.actualFocusDuration
    this.totalDuration = session.totalDuration
    this.breakCount = session.breakCount
    this.interruptionReason = session.interruptionReason
    this.timeLimitMs = session.timeLimitMs
    this.sessionType = session.sessionType
    this.restIntervalMs = session.restIntervalMs
    this.restDurationMs = session.restDurationMs
  }
}

class GroupedSessionBucket {
  session: FocusSession
  restTotal: number

  constructor(session: FocusSession, restTotal: number) {
    this.session = session
    this.restTotal = restTotal
  }
}

@Entry
@Component
struct HistoryPage {
  @State completedSessions: FocusSession[] = []
  @State taskById: Record<number, Task> = {}
  @State expandedSessionIds: number[] = []
  @State loading: boolean = false
  @State filterOpen: boolean = false
  @State selectedDate: Date = new Date()
  @State pickerYear: string = new Date().getFullYear().toString()
  @State pickerMonth: string = (new Date().getMonth() + 1).toString()
  @State pickerDay: string = new Date().getDate().toString()
  @State appliedDate: Date | null = null
  @State hourlyFocus: number[] = []
  @State hourlyRest: number[] = []
  @State headerOpacity: number = 0
  @State contentOpacity: number = 0
  @State screenWidth: number = 0
  private readonly chartHeight: number = 140
  private readonly axisBaselineOffset: number = 5
  private readonly chartMaxMinutes: number = 60
  private readonly chartItemWidth: number = 35
  private readonly chartBarWidth: number = 8
  private chartScroller: Scroller = new Scroller()
  // 滑动手势相关
  @State panOffsetX: number = 0
  private readonly swipeThreshold: number = 80
  @StorageLink('hasSeenOnboarding') hasSeenOnboarding: boolean = false
  @StorageLink('onboardingDisabled') onboardingDisabled: boolean = false
  @StorageLink('onboardingStepId') onboardingStepId: string = ''
  @StorageLink('onboardingAdvanceTick') onboardingAdvanceTick: number = 0
  @StorageLink('onboardingSkipTick') onboardingSkipTick: number = 0
  @StorageLink('onboardingDemoTaskId') onboardingDemoTaskId: number = -1
  @StorageLink('onboardingSkipped') onboardingSkipped: boolean = false
  @State historyListRect: OnboardingRect = { x: 0, y: 0, width: 0, height: 0 }
  @State lastAdvanceTick: number = 0
  @State lastSkipTick: number = 0
  private onboardingTickTimer: number = -1

  private hideKeyboard() {
    try {
      inputMethod.getController().hideTextInput()
    } catch (e) {
      // Ignore when keyboard is not available.
    }
  }

  async aboutToAppear() {
    this.resetHourlyData()
    await this.loadData()
    setTimeout(() => {
      this.headerOpacity = 1
    }, 100)
    setTimeout(() => {
      this.contentOpacity = 1
    }, 200)
    this.startOnboardingTickMonitor()
  }

  onPageShow() {
    this.loadData()
  }

  aboutToDisappear() {
    this.stopOnboardingTickMonitor()
  }

  private handleSwipeGesture(offsetX: number, velocity: number) {
    if (this.isOnboardingActive()) {
      return
    }
    const absOffset = Math.abs(offsetX)
    const absVelocity = Math.abs(velocity)
    
    // 快速滑动或滑动距离足够
    if (absVelocity > 500 || absOffset > this.swipeThreshold) {
      if (offsetX > 0) {
        // 向右滑动 - 切换到设置页面（历史是第1个，向右是第2个设置）
        router.replaceUrl({ url: 'pages/SettingsPage' })
      } else if (offsetX < 0) {
        // 向左滑动 - 切换到首页
        router.replaceUrl({ url: 'pages/Index' })
      }
    }
  }

  private parseLength(value: Length | undefined): number {
    if (value === undefined) {
      return 0
    }
    if (typeof value === 'number') {
      return value
    }
    if (typeof value === 'string') {
      const parsed = Number.parseFloat(value)
      return Number.isNaN(parsed) ? 0 : parsed
    }
    return 0
  }

  private areaToRect(newArea: Area): OnboardingRect {
    const pos = newArea.globalPosition ?? newArea.position
    return {
      x: this.parseLength(pos?.x),
      y: this.parseLength(pos?.y) - 45,
      width: this.parseLength(newArea.width),
      height: this.parseLength(newArea.height)
    }
  }

  private startOnboardingTickMonitor() {
    if (this.onboardingTickTimer !== -1) {
      return
    }
    this.lastAdvanceTick = this.onboardingAdvanceTick
    this.lastSkipTick = this.onboardingSkipTick
    this.onboardingTickTimer = setInterval(() => {
      if (!this.shouldShowOnboardingForRoute('HISTORY')) {
        this.lastAdvanceTick = this.onboardingAdvanceTick
        this.lastSkipTick = this.onboardingSkipTick
        return
      }
      if (this.onboardingAdvanceTick !== this.lastAdvanceTick) {
        this.lastAdvanceTick = this.onboardingAdvanceTick
        this.handleOnboardingAdvance()
      }
      if (this.onboardingSkipTick !== this.lastSkipTick) {
        this.lastSkipTick = this.onboardingSkipTick
        void this.handleOnboardingSkip()
      }
    }, 150)
  }

  private stopOnboardingTickMonitor() {
    if (this.onboardingTickTimer === -1) {
      return
    }
    clearInterval(this.onboardingTickTimer)
    this.onboardingTickTimer = -1
  }

  private async handleOnboardingSkip() {
    this.onboardingSkipped = true
    this.endOnboarding()
    await this.cleanupDemoTask()
    router.replaceUrl({ url: 'pages/Index' })
  }

  private async cleanupDemoTask() {
    const demoId = this.onboardingDemoTaskId
    if (demoId > 0) {
      await TaskRepo.delete(getContext(this), demoId)
    }
    if (demoId > 0) {
      this.onboardingDemoTaskId = demoId
    }
  }

  private getCurrentOnboardingStep() {
    return getOnboardingStep(this.onboardingStepId)
  }

  private shouldShowOnboardingForRoute(route: string): boolean {
    const step = this.getCurrentOnboardingStep()
    if (!step) {
      return false
    }
    if (step.isSetup) {
      return false
    }
    if (!shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)) {
      return false
    }
    return step.route === route
  }

  private getCurrentOnboardingTarget(): OnboardingRect | undefined {
    const step = this.getCurrentOnboardingStep()
    if (!step?.targetId) {
      return undefined
    }
    if (step.targetId === 'history_list_area') {
      if (this.historyListRect.width <= 0 || this.historyListRect.height <= 0) {
        return undefined
      }
      const baseWidth = this.screenWidth > 0 ? this.screenWidth : this.historyListRect.width
      const width = Math.max(0, baseWidth - 10)
      return {
        x: 5,
        y: this.historyListRect.y,
        width,
        height: this.historyListRect.height
      }
    }
    return undefined
  }

  private isOnboardingActive(): boolean {
    if (this.onboardingStepId === '') {
      return false
    }
    return shouldShowOnboarding(this.hasSeenOnboarding, this.onboardingDisabled)
  }

  private handleOnboardingAdvance() {
    const step = this.getCurrentOnboardingStep()
    if (!step) {
      return
    }
    if (step.id === 'end_history_page') {
      this.onboardingSkipped = false
      this.endOnboarding()
    }
  }

  private endOnboarding() {
    this.hasSeenOnboarding = true
    this.onboardingDisabled = true
    this.onboardingStepId = ''
  }

  build() {
    Stack() {
      Column() {
      // 顶部标题栏 - 精致现代风格
      Row() {
        Row({ space: 10 }) {
          Text('📊')
            .fontSize(Theme.FONT_SIZE_LARGE)
          Text('历史记录')
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
        }
        .alignItems(VerticalAlign.Center)
        
        Blank()
        
        Button({ type: ButtonType.Circle }) {
          Text('📅')
            .fontSize(20)
        }
        .width(48)
        .height(48)
        .backgroundColor(this.filterOpen ? Theme.COLOR_TEXT_PRIMARY : Theme.COLOR_CARD_BACKGROUND)
        .border({ width: 1, color: Theme.COLOR_BORDER })
        .shadow(Theme.SHADOW_SMALL)
        .onClick(() => {
          if (!this.filterOpen) {
            const base = this.appliedDate ?? this.selectedDate
            this.pickerYear = base.getFullYear().toString()
            this.pickerMonth = (base.getMonth() + 1).toString()
            this.pickerDay = base.getDate().toString()
          }
          this.filterOpen = !this.filterOpen
        })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 10, bottom: 16 })
      .alignItems(VerticalAlign.Center)
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

      Column() {
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
          this.CompletedSessionsContent()
        }
      }
      .layoutWeight(1)
      .width('100%')
      .opacity(this.contentOpacity)
      .animation({
        duration: Theme.ANIMATION_NORMAL,
        curve: Curve.EaseOut
      })

        BottomNav({ currentIndex: 1 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Theme.COLOR_BACKGROUND)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.hideKeyboard()
        }
      })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionUpdate((event: GestureEvent) => {
            this.panOffsetX = event.offsetX
          })
          .onActionEnd((event: GestureEvent) => {
            this.handleSwipeGesture(event.offsetX, event.velocityX)
            this.panOffsetX = 0
          })
      )

      if (this.shouldShowOnboardingForRoute('HISTORY')) {
        OnboardingOverlay({
          visible: true,
          body: this.getCurrentOnboardingStep()?.body ?? '',
          rule: this.getCurrentOnboardingStep()?.rule ?? 'TAP_ANYWHERE_EXCEPT_SKIP',
          target: this.getCurrentOnboardingTarget(),
          showSkip: true
        })
      }
    }
    .width('100%')
    .height('100%')
    .onAreaChange((_, newArea) => {
      this.screenWidth = this.parseLength(newArea.width)
    })
  }

  @Builder
  CompletedSessionsContent() {
    Stack() {
      Column({ space: Theme.SPACE_MEDIUM }) {
        if (this.appliedDate) {
          this.HourlyChart()
        }

        if (this.getVisibleSessions().length === 0) {
          Column({ space: 16 }) {
            Column() {
              Text('📭')
                .fontSize(56)
            }
            .width(100)
            .height(100)
            .borderRadius(50)
            .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
            .border({ width: 1, color: Theme.COLOR_BORDER })
            .justifyContent(FlexAlign.Center)
            
            Text('暂无完成的任务')
              .fontSize(Theme.FONT_SIZE_LARGE)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
            Text('完成专注后，记录会显示在这里')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
          }
          .justifyContent(FlexAlign.Center)
          .layoutWeight(1)
        } else {
          List({ space: Theme.SPACE_MEDIUM }) {
            ForEach(this.getVisibleSessions(), (session: FocusSession) => {
              ListItem() {
                this.SessionCard(session)
              }
            }, (session: FocusSession) => session.id.toString())
          }
          .onAreaChange((_, newArea) => {
            this.historyListRect = this.areaToRect(newArea)
          })
          .width('100%')
        }
      }
      .width('100%')

      if (this.filterOpen) {
        Column({ space: 16 }) {
          Row({ space: 8 }) {
            Text('📆')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
            Text('选择日期')
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
          }
          .width('100%')

          Row({ space: 10 }) {
            // Year 输入
            Column({ space: 6 }) {
              Text('年')
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
              TextInput({ placeholder: 'YYYY', text: this.pickerYear })
                .width('100%')
                .height(52)
                .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                .backgroundColor(Theme.COLOR_BACKGROUND)
                .border({ width: 1.5, color: Theme.COLOR_BORDER })
                .padding({ left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .onChange((value: string) => {
                  this.pickerYear = value.replace(/[^\d]/g, '')
                })
            }
            .layoutWeight(1)

            // Month 输入
            Column({ space: 6 }) {
              Text('月')
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
              TextInput({ placeholder: 'MM', text: this.pickerMonth })
                .width('100%')
                .height(52)
                .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                .backgroundColor(Theme.COLOR_BACKGROUND)
                .border({ width: 1.5, color: Theme.COLOR_BORDER })
                .padding({ left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .onChange((value: string) => {
                  this.pickerMonth = value.replace(/[^\d]/g, '')
                })
            }
            .layoutWeight(1)

            // Day 输入
            Column({ space: 6 }) {
              Text('日')
                .fontSize(Theme.FONT_SIZE_SMALL)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
              TextInput({ placeholder: 'DD', text: this.pickerDay })
                .width('100%')
                .height(52)
                .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
                .backgroundColor(Theme.COLOR_BACKGROUND)
                .border({ width: 1.5, color: Theme.COLOR_BORDER })
                .padding({ left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .onChange((value: string) => {
                  this.pickerDay = value.replace(/[^\d]/g, '')
                })
            }
            .layoutWeight(1)
          }

          Row({ space: 12 }) {
            Button('应用筛选')
              .layoutWeight(1)
              .height(50)
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .borderRadius(Theme.BORDER_RADIUS_LARGE)
              .shadow(Theme.SHADOW_GLOW)
              .onClick(() => {
                void this.applyFilter()
              })

            Button('清除')
              .layoutWeight(1)
              .height(50)
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .backgroundColor(Theme.COLOR_BACKGROUND)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .borderRadius(Theme.BORDER_RADIUS_LARGE)
              .border({ width: 1, color: Theme.COLOR_BORDER })
              .onClick(() => {
                this.clearFilter()
              })
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })
        .shadow(Theme.SHADOW_MEDIUM)
        .position({ x: 0, y: 0 })
        .zIndex(2)
      }
    }
    .layoutWeight(1)
    .width('100%')
    .padding({
      left: 20,
      right: 20,
      top: Theme.SPACE_MEDIUM,
      bottom: Theme.SPACE_MEDIUM
    })
  }

  @Builder
  HourlyChart() {
    Column({ space: 12 }) {
      // 图例
      Row() {
        Text(this.formatDateShort(this.appliedDate!.getTime()))
          .fontSize(Theme.FONT_SIZE_SMALL)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
        Row({ space: 16 }) {
          Row({ space: 8 }) {
            Column()
              .width(14)
              .height(14)
              .backgroundColor('#ED820E')
              .borderRadius(7)
            Text('休息')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
          Row({ space: 8 }) {
            Column()
              .width(14)
              .height(14)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .borderRadius(7)
            Text('专注')
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
          }
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Text('分钟')
        .fontSize(Theme.FONT_SIZE_TINY)
        .fontColor(Theme.COLOR_TEXT_TERTIARY)
        .margin({ left: 2 })

      Row({ space: Theme.SPACE_SMALL }) {
        Column() {
          Column() {
            Text('60')
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
            Text('45')
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
            Text('30')
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
            Text('15')
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
            Text('0')
              .fontSize(Theme.FONT_SIZE_TINY)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
          }
          .height(this.chartHeight + this.axisBaselineOffset)
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width(32)
        .height(this.chartHeight + this.axisBaselineOffset)

      Scroll(this.chartScroller) {
        Row({ space: 0 }) {
          ForEach(this.hourlyFocus, (value: number, index: number) => {
            Column() {
                Column({ space: 0 }) {
                  Column()
                    .width(this.chartBarWidth)
                    .height(this.getStackRestHeight(index))
                    .backgroundColor('#ED820E')
                    .borderRadius(6)
                  Column()
                    .width(this.chartBarWidth)
                    .height(this.getStackFocusHeight(index))
                    .backgroundColor(Theme.COLOR_PRIMARY)
                    .borderRadius(6)
                }
                .justifyContent(FlexAlign.End)
                .alignItems(HorizontalAlign.Center)
                .height(this.chartHeight)
                .width(28)
                Text(index.toString())
                  .fontSize(Theme.FONT_SIZE_TINY)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  .margin({ top: 8 })
              }
              .width(28)
              .height(this.chartHeight + 20)
            })
          }
          .height(this.chartHeight + 30)
          .padding({ right: Theme.SPACE_LARGE })
        }
        .height(this.chartHeight + 30)
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.On)
        .onAppear(() => {
          setTimeout(() => {
            if (this.appliedDate) {
              this.scrollChartToFirstActiveHour()
            }
          }, 0)
        })
      }
      .alignItems(VerticalAlign.Top)
      .width('100%')
      .clip(true)
    }
    .width('100%')
    .padding({ left: Theme.SPACE_LARGE, right: Theme.SPACE_LARGE, top: Theme.SPACE_MEDIUM, bottom: Theme.SPACE_MEDIUM })
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_LARGE)
    .shadow(Theme.SHADOW_MEDIUM)
  }

  @Builder
  SessionCard(session: FocusSession) {
    Column({ space: Theme.SPACE_SMALL }) {
      Row() {
        Column({ space: 6 }) {
          Row({ space: 10 }) {
            Text(this.getTaskTitle(session.taskId))
              .fontSize(Theme.FONT_SIZE_MEDIUM)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.COLOR_TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.appliedDate && this.isTaskIncomplete(session.taskId)) {
              Text('进行中')
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(Theme.BORDER_RADIUS_SMALL)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1, color: Theme.COLOR_BORDER })
            }
          }
          if (!(this.appliedDate && this.isTaskIncomplete(session.taskId))) {
            Text(`完成于: ${this.formatDate(this.getCompletionTime(session))}`)
              .fontSize(Theme.FONT_SIZE_SMALL)
              .fontColor(Theme.COLOR_TEXT_TERTIARY)
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text(this.formatDurationShort(session.actualFocusDuration))
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
          Text('专注时长')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }

        Stack({ alignContent: Alignment.Center }) {
          Text(this.isSessionExpanded(session.id) ? '▾' : '▸')
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .width(24)
        .height(24)
        .margin({ left: 10 })
      }
      .width('100%')

      if (this.isSessionExpanded(session.id)) {
        Column({ space: 12 }) {
          Divider()
            .color(Theme.COLOR_BORDER)
            .margin({ top: 4 })
          
          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Row({ space: 4 }) {
                Text('⏱️')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                Text('总时长')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              Text(this.formatDurationShort(session.totalDuration))
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            
            Column({ space: 4 }) {
              Row({ space: 4 }) {
                Text('🎯')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                Text('专注时长')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              Text(this.formatDurationShort(session.actualFocusDuration))
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }

          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Row({ space: 4 }) {
                Text('☕')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                Text('休息次数')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              Text(session.breakCount.toString() + ' 次')
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_PRIMARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            
            Column({ space: 4 }) {
              Row({ space: 4 }) {
                Text('😴')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                Text('休息时长')
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_TERTIARY)
              }
              Text(this.formatDurationShort(this.getRestDuration(session)))
                .fontSize(Theme.FONT_SIZE_MEDIUM)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
        }
        .padding({ top: 4 })
      }
    }
    .width('100%')
    .padding(Theme.SPACE_LARGE)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_LARGE)
    .shadow(Theme.SHADOW_MEDIUM)
    .onClick(() => {
      this.toggleExpanded(session.id)
    })
    .animation({
      duration: Theme.ANIMATION_NORMAL,
      curve: Curve.EaseOut
    })
  }

  private async loadData() {
    this.loading = true
    const sessionsResult = await SessionRepo.findCompleted(getContext(this), 200)
    if (sessionsResult.ok && sessionsResult.data) {
      const demoId = this.onboardingDemoTaskId
      const filtered = this.onboardingSkipped && demoId > 0
        ? sessionsResult.data.filter((session) => session.taskId !== demoId)
        : sessionsResult.data
      this.completedSessions = filtered
      await this.loadTaskMap(filtered)
    }
    if (this.appliedDate) {
      await this.loadHourlyDataForDate(this.appliedDate)
    }
    this.loading = false
  }

  private formatDurationShort(ms: number): string {
    const minutes = Math.floor(ms / (1000 * 60))
    const hours = Math.floor(minutes / 60)

    if (hours > 0) {
      return hours + 'h ' + (minutes % 60) + 'm'
    } else {
      return minutes + 'm'
    }
  }

  private formatDate(timestamp: number): string {
    const date = new Date(timestamp)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hour = date.getHours()
    const minute = date.getMinutes()

    return month + '/' + day + ' ' + this.pad(hour) + ':' + this.pad(minute)
  }

  private pad(num: number): string {
    return num < 10 ? '0' + num : num.toString()
  }

  private formatDateShort(timestamp: number): string {
    const date = new Date(timestamp)
    const month = date.getMonth() + 1
    const day = date.getDate()
    return month + '/' + day
  }

  private getDateFromPicker(year: number, month: number, day: number): Date {
    let monthIndex = month
    if (monthIndex >= 1 && monthIndex <= 12) {
      monthIndex -= 1
    }
    if (monthIndex < 0) {
      monthIndex = 0
    }
    if (monthIndex > 11) {
      monthIndex = 11
    }
    const maxDay = new Date(year, monthIndex + 1, 0).getDate()
    const safeDay = Math.min(Math.max(day, 1), maxDay)
    return new Date(year, monthIndex, safeDay)
  }

  private toggleExpanded(sessionId: number) {
    const index = this.expandedSessionIds.indexOf(sessionId)
    if (index >= 0) {
      this.expandedSessionIds.splice(index, 1)
    } else {
      this.expandedSessionIds.push(sessionId)
    }
    this.expandedSessionIds = [...this.expandedSessionIds]
  }

  private getTaskTitle(taskId?: number): string {
    if (taskId === undefined) {
      return 'Anonymous'
    }
    const task = this.taskById[taskId]
    return task?.title ?? 'Unknown Task'
  }

  private isTaskIncomplete(taskId?: number): boolean {
    if (taskId === undefined) {
      return false
    }
    const task = this.taskById[taskId]
    if (!task) {
      return true
    }
    return task.lastCompletedAt === undefined
  }

  private getVisibleSessions(): FocusSession[] {
    const filtered = this.filterSessionsByDate(this.completedSessions, this.appliedDate)
    return this.groupSessions(filtered, this.appliedDate !== null)
  }

  private filterSessionsByDate(sessions: FocusSession[], date: Date | null): FocusSession[] {
    if (!date) {
      return sessions
    }
    const start = new Date(date)
    start.setHours(0, 0, 0, 0)
    const end = new Date(start)
    end.setDate(end.getDate() + 1)
    const startMs = start.getTime()
    const endMs = end.getTime()
    return sessions.filter((session) => {
      const ts = session.endAt ?? session.startAt
      return ts >= startMs && ts < endMs
    })
  }

  private groupSessions(sessions: FocusSession[], groupByDay: boolean): FocusSession[] {
    const grouped: Record<string, GroupedSessionBucket> = {}
    const keys: string[] = []

    sessions.forEach((session) => {
      if (!groupByDay && this.isTaskIncomplete(session.taskId)) {
        return
      }
      let key = ''
      if (session.taskId !== undefined) {
        key = `task:${session.taskId}`
        if (groupByDay) {
          key += `:${this.getDayKey(this.getCompletionTime(session))}`
        }
      } else {
        key = `session:${session.id}`
      }

      if (!grouped[key]) {
        const copy = new FocusSessionCopy(session)
        copy.status = SessionStatus.FINISHED
        grouped[key] = new GroupedSessionBucket(copy, this.getRestDuration(session))
        keys.push(key)
        return
      }

      const target = grouped[key]
      const targetSession = target.session
      targetSession.actualFocusDuration += session.actualFocusDuration
      targetSession.totalDuration += session.totalDuration
      targetSession.breakCount += session.breakCount
      target.restTotal += this.getRestDuration(session)
      targetSession.startAt = Math.min(targetSession.startAt, session.startAt)

      const completion = this.getCompletionTime(session)
      const targetCompletion = this.getCompletionTime(targetSession)
      if (completion > targetCompletion) {
        targetSession.endAt = session.endAt ?? completion
      }
    })

    return keys.map((key) => {
      const item = grouped[key]
      item.session.restDurationMs = item.restTotal
      return item.session
    })
  }

  private getDayKey(timestamp: number): string {
    const date = new Date(timestamp)
    const month = this.pad(date.getMonth() + 1)
    const day = this.pad(date.getDate())
    return `${date.getFullYear()}-${month}-${day}`
  }

  private async applyFilter(): Promise<void> {
    const year = Number(this.pickerYear)
    const month = Number(this.pickerMonth)
    const day = Number(this.pickerDay)
    if (!Number.isFinite(year) || !Number.isFinite(month) || !Number.isFinite(day)) {
      return
    }
    this.selectedDate = this.getDateFromPicker(year, month, day)
    this.appliedDate = new Date(this.selectedDate)
    await this.loadHourlyDataForDate(this.appliedDate)
    this.filterOpen = false
  }

  private clearFilter() {
    this.appliedDate = null
    this.filterOpen = false
    this.resetHourlyData()
  }

  private resetHourlyData() {
    const focus: number[] = []
    const rest: number[] = []
    for (let i = 0; i < 24; i += 1) {
      focus.push(0)
      rest.push(0)
    }
    this.hourlyFocus = focus
    this.hourlyRest = rest
  }

  private async loadHourlyDataForDate(date: Date) {
    const start = new Date(date)
    start.setHours(0, 0, 0, 0)
    const end = new Date(start)
    end.setDate(end.getDate() + 1)
    const startMs = start.getTime()
    const endMs = end.getTime()

    const results = await Promise.all([
      SegmentRepo.findByTimeRange(getContext(this), startMs, endMs),
      BreakRepo.findByTimeRange(getContext(this), startMs, endMs)
    ])
    const segmentsResult = results[0]
    const breaksResult = results[1]

    const focus: number[] = []
    const rest: number[] = []
    for (let i = 0; i < 24; i += 1) {
      focus.push(0)
      rest.push(0)
    }

    if (segmentsResult.ok && segmentsResult.data) {
      segmentsResult.data.forEach((segment: FocusSegment) => {
        const segmentEnd = segment.endAt ?? (segment.startAt + segment.durationMs)
        this.addDurationToHourly(focus, segment.startAt, segmentEnd, startMs, endMs)
      })
    }

    if (breaksResult.ok && breaksResult.data) {
      breaksResult.data.forEach((breakEvent: BreakEvent) => {
        const breakEnd = breakEvent.endAt ?? (breakEvent.startAt + breakEvent.actualDuration)
        this.addDurationToHourly(rest, breakEvent.startAt, breakEnd, startMs, endMs)
      })
    }

    this.hourlyFocus = focus
    this.hourlyRest = rest
    setTimeout(() => {
      if (this.appliedDate) {
        this.scrollChartToFirstActiveHour()
      }
    }, 0)
  }

  private addDurationToHourly(
    target: number[],
    startMs: number,
    endMs: number,
    dayStart: number,
    dayEnd: number
  ) {
    const clampedStart = Math.max(startMs, dayStart)
    const clampedEnd = Math.min(endMs, dayEnd)
    if (clampedEnd <= clampedStart) {
      return
    }

    let cursor = clampedStart
    while (cursor < clampedEnd) {
      const hour = new Date(cursor).getHours()
      const nextHour = this.getNextHourBoundary(cursor)
      const segmentEnd = Math.min(clampedEnd, nextHour)
      const minutes = (segmentEnd - cursor) / 60000
      target[hour] += minutes
      cursor = segmentEnd
    }
  }

  private getNextHourBoundary(timeMs: number): number {
    const dt = new Date(timeMs)
    dt.setMinutes(60, 0, 0)
    return dt.getTime()
  }

  private isSessionExpanded(sessionId: number): boolean {
    return this.expandedSessionIds.includes(sessionId)
  }

  private getCompletionTime(session: FocusSession): number {
    return session.endAt ?? session.startAt
  }

  private getRestDuration(session: FocusSession): number {
    if (session.restDurationMs !== undefined) {
      return session.restDurationMs
    }
    return Math.max(session.totalDuration - session.actualFocusDuration, 0)
  }

  private getBarHeight(value: number): number {
    const height = (value / this.chartMaxMinutes) * this.chartHeight
    return Math.min(height, this.chartHeight)
  }

  private getStackScale(index: number): number {
    const focus = this.hourlyFocus[index] ?? 0
    const rest = this.hourlyRest[index] ?? 0
    const total = focus + rest
    if (total <= this.chartMaxMinutes) {
      return 1
    }
    return this.chartMaxMinutes / total
  }

  private getStackFocusHeight(index: number): number {
    const focus = this.hourlyFocus[index] ?? 0
    const scale = this.getStackScale(index)
    return this.getBarHeight(focus * scale)
  }

  private getStackRestHeight(index: number): number {
    const rest = this.hourlyRest[index] ?? 0
    const scale = this.getStackScale(index)
    return this.getBarHeight(rest * scale)
  }

  private async loadTaskMap(sessions: FocusSession[]) {
    const ids: number[] = []
    sessions.forEach((session) => {
      if (session.taskId !== undefined && !ids.includes(session.taskId)) {
        ids.push(session.taskId)
      }
    })
    const taskMap: Record<number, Task> = {}
    await Promise.all(ids.map(async (id) => {
      const result = await TaskRepo.findById(getContext(this), id)
      if (result.ok && result.data) {
        taskMap[id] = result.data
      }
    }))
    this.taskById = taskMap
  }

  private scrollChartToHour(hour: number) {
    const offset = Math.max(0, hour * this.chartItemWidth)
    this.chartScroller.scrollTo({
      xOffset: offset,
      yOffset: 0,
      animation: false
    })
  }

  private scrollChartToFirstActiveHour() {
    let firstActive = -1
    for (let i = 0; i < 24; i += 1) {
      if ((this.hourlyFocus[i] ?? 0) > 0 || (this.hourlyRest[i] ?? 0) > 0) {
        firstActive = i
        break
      }
    }
    if (firstActive === -1) {
      this.scrollChartToHour(0)
      return
    }
    const startHour = Math.max(0, firstActive - 4)
    this.scrollChartToHour(startHour)
  }
}
