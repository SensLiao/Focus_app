/**
 * History page - completed sessions with stats filter.
 */

import { TaskRepo } from '../data/TaskRepo'
import { SessionRepo } from '../data/SessionRepo'
import { SegmentRepo } from '../data/SegmentRepo'
import { BreakRepo } from '../data/BreakRepo'
import { Task } from '../model/Task'
import { FocusSession } from '../model/FocusSession'
import { FocusSegment } from '../model/FocusSegment'
import { BreakEvent } from '../model/BreakEvent'
import { BottomNav } from '../components/BottomNav'
import { Theme } from '../common/theme'

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
  private readonly chartHeight: number = 180
  private readonly chartMaxMinutes: number = 60
  private readonly chartItemWidth: number = 30
  private readonly chartBarWidth: number = 8
  private readonly bottomNavHeight: number = 60
  private chartScroller: Scroller = new Scroller()

  async aboutToAppear() {
    this.resetHourlyData()
    await this.loadData()
  }

  onPageShow() {
    this.loadData()
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Text('历史记录')
          .fontSize(24)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.COLOR_TEXT_PRIMARY)
        Blank()
        Button({ type: ButtonType.Normal }) {
          Text('📋').fontSize(20)
        }
        .width(40)
        .height(40)
        .backgroundColor(this.filterOpen ? Theme.COLOR_PRIMARY_BG : Color.Transparent)
        .borderRadius(10)
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
      .height(60)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
      .border({
        width: { bottom: 1 },
        color: Theme.COLOR_BORDER
      })

      // 过滤状态显示
      if (this.appliedDate) {
        Row() {
          Text(`已筛选: ${this.formatDateShort(this.appliedDate.getTime())}`)
            .fontSize(13)
            .fontColor(Theme.COLOR_PRIMARY)
          Blank()
          Text('✕')
            .fontSize(14)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
            .onClick(() => {
              this.clearFilter()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .backgroundColor(Theme.COLOR_PRIMARY_BG)
      }

      if (this.filterOpen) {
        Column({ space: 12 }) {
          Text('选择日期')
            .fontSize(13)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
            .width('100%')

          Row({ space: 8 }) {
            // Year 输入
            Column({ space: 4 }) {
              Text('年')
                .fontSize(11)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              TextInput({ placeholder: 'YYYY', text: this.pickerYear })
                .width('100%')
                .height(44)
                .borderRadius(10)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1, color: Theme.COLOR_BORDER })
                .padding({ left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .onChange((value: string) => {
                  this.pickerYear = value.replace(/[^\d]/g, '')
                })
            }
            .layoutWeight(1)

            // Month 输入
            Column({ space: 4 }) {
              Text('月')
                .fontSize(11)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              TextInput({ placeholder: 'MM', text: this.pickerMonth })
                .width('100%')
                .height(44)
                .borderRadius(10)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1, color: Theme.COLOR_BORDER })
                .padding({ left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .onChange((value: string) => {
                  this.pickerMonth = value.replace(/[^\d]/g, '')
                })
            }
            .layoutWeight(1)

            // Day 输入
            Column({ space: 4 }) {
              Text('日')
                .fontSize(11)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              TextInput({ placeholder: 'DD', text: this.pickerDay })
                .width('100%')
                .height(44)
                .borderRadius(10)
                .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
                .border({ width: 1, color: Theme.COLOR_BORDER })
                .padding({ left: 12, right: 12 })
                .textAlign(TextAlign.Center)
                .fontSize(14)
                .onChange((value: string) => {
                  this.pickerDay = value.replace(/[^\d]/g, '')
                })
            }
            .layoutWeight(1)
          }

          Row({ space: 8 }) {
            Button('应用')
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(Theme.COLOR_PRIMARY)
              .fontColor(Color.White)
              .borderRadius(12)
              .onClick(() => {
                void this.applyFilter()
              })

            Button('清除')
              .layoutWeight(1)
              .height(44)
              .fontSize(14)
              .backgroundColor(Theme.COLOR_BACKGROUND)
              .fontColor(Theme.COLOR_TEXT_SECONDARY)
              .borderRadius(12)
              .onClick(() => {
                this.clearFilter()
              })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .border({
          width: { bottom: 1 },
          color: Theme.COLOR_BORDER
        })
      }

      if (this.loading) {
        Column() {
          Text('加载中...')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        this.CompletedSessionsContent()
      }

      BottomNav({ currentIndex: 1 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  @Builder
  CompletedSessionsContent() {
    Column({ space: Theme.SPACE_MEDIUM }) {
      if (this.appliedDate) {
        this.HourlyChart()
      }

      if (this.getVisibleSessions().length === 0) {
        Column({ space: Theme.SPACE_MEDIUM }) {
          Text('暂无完成的任务')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
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
        .width('100%')
      }
    }
    .layoutWeight(1)
    .width('100%')
    .padding({
      left: Theme.SPACE_LARGE,
      right: Theme.SPACE_LARGE,
      top: Theme.SPACE_SMALL,
      bottom: Theme.SPACE_MEDIUM + this.bottomNavHeight
    })
  }

  @Builder
  HourlyChart() {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        Row({ space: 6 }) {
          Column()
            .width(10)
            .height(10)
            .backgroundColor('#F59E0B')
            .borderRadius(5)
          Text('休息')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        Row({ space: 6 }) {
          Column()
            .width(10)
            .height(10)
            .backgroundColor(Theme.COLOR_PRIMARY)
            .borderRadius(5)
          Text('专注')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
      }

      Row({ space: Theme.SPACE_SMALL }) {
        Column() {
          Text('分钟')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
            .margin({ bottom: 4 })
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
          .height(this.chartHeight)
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width(28)
        .height(this.chartHeight + 20)

        Scroll(this.chartScroller) {
          Row({ space: 12 }) {
            ForEach(this.hourlyFocus, (value: number, index: number) => {
              Column() {
                Column({ space: 0 }) {
                  Column()
                    .width(this.chartBarWidth)
                    .height(this.getStackRestHeight(index))
                    .backgroundColor('#F59E0B')
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
                .width(24)
                Text(index.toString())
                  .fontSize(Theme.FONT_SIZE_TINY)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)
                  .margin({ top: 6 })
              }
              .width(24)
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
      }
      .width('100%')
      .clip(true)
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
  }

  @Builder
  SessionCard(session: FocusSession) {
    Column({ space: Theme.SPACE_SMALL }) {
      Row() {
        Column({ space: 6 }) {
          Text(this.getTaskTitle(session.taskId))
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.COLOR_TEXT_PRIMARY)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`完成于: ${this.formatDate(this.getCompletionTime(session))}`)
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text(this.formatDurationShort(session.actualFocusDuration))
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.COLOR_PRIMARY)

        Text(this.isSessionExpanded(session.id) ? 'v' : '>')
          .fontSize(16)
          .fontColor(Theme.COLOR_TEXT_TERTIARY)
          .margin({ left: 6 })
      }
      .width('100%')

      if (this.isSessionExpanded(session.id)) {
        Column({ space: 8 }) {
          Row({ space: 12 }) {
            Column() {
              Text('总时长')
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              Text(this.formatDurationShort(session.totalDuration))
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .layoutWeight(1)
            Column() {
              Text('专注时长')
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              Text(this.formatDurationShort(session.actualFocusDuration))
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .layoutWeight(1)
          }

          Row({ space: 12 }) {
            Column() {
              Text('休息次数')
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              Text(session.breakCount.toString())
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .layoutWeight(1)
            Column() {
              Text('休息时长')
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_TERTIARY)
              Text(this.formatDurationShort(this.getRestDuration(session)))
                .fontSize(Theme.FONT_SIZE_TINY)
                .fontColor(Theme.COLOR_TEXT_SECONDARY)
            }
            .layoutWeight(1)
          }
        }
      }
    }
    .width('100%')
    .padding(Theme.SPACE_MEDIUM)
    .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
    .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
    .shadow({
      radius: Theme.SHADOW_SMALL.radius,
      color: Theme.SHADOW_SMALL.color,
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.toggleExpanded(session.id)
    })
  }

  private async loadData() {
    this.loading = true
    const sessionsResult = await SessionRepo.findCompleted(getContext(this), 200)
    if (sessionsResult.ok && sessionsResult.data) {
      this.completedSessions = sessionsResult.data
      await this.loadTaskMap(sessionsResult.data)
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

  private getVisibleSessions(): FocusSession[] {
    if (!this.appliedDate) {
      return this.completedSessions
    }
    const start = new Date(this.appliedDate)
    start.setHours(0, 0, 0, 0)
    const end = new Date(start)
    end.setDate(end.getDate() + 1)
    const startMs = start.getTime()
    const endMs = end.getTime()
    return this.completedSessions.filter((session) => {
      const ts = session.endAt ?? session.startAt
      return ts >= startMs && ts < endMs
    })
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
    this.scrollChartToFirstActiveHour()
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
    const startHour = Math.max(0, firstActive - 2)
    this.scrollChartToHour(startHour)
  }
}
