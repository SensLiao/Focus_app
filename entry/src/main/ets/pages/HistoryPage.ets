/**
 * 历史页 - 已完成任务和专注记录（UI 现代化版本）
 */

import router from '@ohos.router'
import { TaskRepo } from '../data/TaskRepo'
import { SessionRepo, SessionStats } from '../data/SessionRepo'
import { Task } from '../model/Task'
import { FocusSession } from '../model/FocusSession'
import { BottomNav } from '../components/BottomNav'
import { StatCard } from '../components/StatCard'
import { Theme } from '../common/theme'

@Entry
@Component
struct HistoryPage {
  @State completedTasks: Task[] = []
  @State recentSessions: FocusSession[] = []
  @State stats: SessionStats = {
    totalFocusTime: 0,
    sessionCount: 0,
    totalBreaks: 0,
    todayFocusTime: 0
  }
  @State loading: boolean = false
  @State activeTab: number = 0 // 0: 任务, 1: 会话

  async aboutToAppear() {
    await this.loadData()
  }

  // 页面每次显示时刷新数据
  onPageShow() {
    this.loadData()
  }

  build() {
    Column() {
      // 顶部标题区（渐变背景）
      Column() {
        Row() {
          Text('历史记录')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .padding({ left: Theme.SPACE_LARGE, top: Theme.SPACE_XLARGE, bottom: Theme.SPACE_MEDIUM })

        // 统计卡片（今日专注）
        Column() {
          Text('今日专注')
            .fontSize(Theme.FONT_SIZE_SMALL)
            .fontColor('#ffffffcc')
          
          Text(this.formatDurationLong(this.stats.todayFocusTime))
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ top: Theme.SPACE_SMALL })
        }
        .width('100%')
        .padding({ left: Theme.SPACE_LARGE, bottom: Theme.SPACE_LARGE })
      }
      .width('100%')
      .linearGradient({
        angle: 135,
        colors: [
          [Theme.COLOR_PRIMARY_LIGHT, 0],
          [Theme.COLOR_PRIMARY, 1]
        ]
      })

      // 统计卡片行
      Row({ space: Theme.SPACE_SMALL }) {
        Column() {
          Text(this.formatDurationShort(this.stats.totalFocusTime))
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_PRIMARY)
          Text('总专注')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

        Column() {
          Text(this.stats.sessionCount.toString())
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_SUCCESS)
          Text('会话数')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

        Column() {
          Text(this.stats.totalBreaks.toString())
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_WARNING)
          Text('休息次数')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)

        Column() {
          Text(this.completedTasks.length.toString())
            .fontSize(Theme.FONT_SIZE_LARGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.COLOR_ERROR)
          Text('已完成')
            .fontSize(Theme.FONT_SIZE_TINY)
            .fontColor(Theme.COLOR_TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .padding(Theme.SPACE_MEDIUM)
        .backgroundColor(Theme.COLOR_CARD_BACKGROUND)
        .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
      }
      .width('100%')
      .padding({ left: Theme.SPACE_MEDIUM, right: Theme.SPACE_MEDIUM, top: Theme.SPACE_MEDIUM })

      // Tab 切换
      Row() {
        Button('已完成任务')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(36)
          .backgroundColor(this.activeTab === 0 ? Theme.COLOR_PRIMARY : Theme.COLOR_BACKGROUND)
          .fontColor(this.activeTab === 0 ? Color.White : Theme.COLOR_TEXT_SECONDARY)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
          .layoutWeight(1)
          .onClick(() => {
            this.activeTab = 0
          })

        Button('专注记录')
          .fontSize(Theme.FONT_SIZE_SMALL)
          .height(36)
          .backgroundColor(this.activeTab === 1 ? Theme.COLOR_PRIMARY : Theme.COLOR_BACKGROUND)
          .fontColor(this.activeTab === 1 ? Color.White : Theme.COLOR_TEXT_SECONDARY)
          .borderRadius(Theme.BORDER_RADIUS_MEDIUM)
          .layoutWeight(1)
          .onClick(() => {
            this.activeTab = 1
          })
      }
      .width('100%')
      .padding({ left: Theme.SPACE_LARGE, right: Theme.SPACE_LARGE, top: Theme.SPACE_MEDIUM })

      // 内容区
      if (this.loading) {
        Column() {
          Text('加载中...')
            .fontSize(Theme.FONT_SIZE_MEDIUM)
            .fontColor(Theme.COLOR_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.activeTab === 0) {
        // 已完成任务列表
        this.TaskListContent()
      } else {
        // 专注记录列表
        this.SessionListContent()
      }

      // 底部导航栏
      BottomNav({ currentIndex: 1 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.COLOR_BACKGROUND)
  }

  @Builder
  TaskListContent() {
    if (this.completedTasks.length === 0) {
      Column({ space: Theme.SPACE_MEDIUM }) {
        Text('📝')
          .fontSize(48)
        Text('还没有已完成的任务')
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontColor(Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: Theme.SPACE_MEDIUM }) {
        ForEach(this.completedTasks, (task: Task) => {
          ListItem() {
            Column() {
              Row() {
                Column({ space: Theme.SPACE_TINY }) {
                  Text(task.title)
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.COLOR_TEXT_PRIMARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  if (task.completedAt) {
                    Text('完成于 ' + this.formatDate(task.completedAt))
                      .fontSize(Theme.FONT_SIZE_TINY)
                      .fontColor(Theme.COLOR_TEXT_TERTIARY)
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Column() {
                  Text(this.formatDurationShort(task.totalFocusTime))
                    .fontSize(Theme.FONT_SIZE_MEDIUM)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.COLOR_PRIMARY)
                }
              }
              .width('100%')
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
          }
        }, (task: Task) => task.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: Theme.SPACE_LARGE,
        right: Theme.SPACE_LARGE,
        top: Theme.SPACE_MEDIUM
      })
    }
  }

  @Builder
  SessionListContent() {
    if (this.recentSessions.length === 0) {
      Column({ space: Theme.SPACE_MEDIUM }) {
        Text('⏱')
          .fontSize(48)
        Text('还没有专注记录')
          .fontSize(Theme.FONT_SIZE_MEDIUM)
          .fontColor(Theme.COLOR_TEXT_TERTIARY)
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: Theme.SPACE_MEDIUM }) {
        ForEach(this.recentSessions, (session: FocusSession) => {
          ListItem() {
            Column({ space: Theme.SPACE_SMALL }) {
              Row() {
                Text(this.formatDate(session.startAt))
                  .fontSize(Theme.FONT_SIZE_SMALL)
                  .fontColor(Theme.COLOR_TEXT_SECONDARY)

                Blank()

                Text(this.formatDurationShort(session.actualFocusDuration))
                  .fontSize(Theme.FONT_SIZE_MEDIUM)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.COLOR_PRIMARY)
              }
              .width('100%')

              Row({ space: Theme.SPACE_SMALL }) {
                // 会话类型标签
                Text(this.getSessionTypeLabel(session.sessionType))
                  .fontSize(Theme.FONT_SIZE_TINY)
                  .fontColor(Color.White)
                  .padding({ left: Theme.SPACE_SMALL, right: Theme.SPACE_SMALL, top: 2, bottom: 2 })
                  .backgroundColor(Theme.COLOR_PRIMARY)
                  .borderRadius(Theme.BORDER_RADIUS_SMALL)

                // 休息次数
                if (session.breakCount > 0) {
                  Text('休息 ' + session.breakCount + ' 次')
                    .fontSize(Theme.FONT_SIZE_TINY)
                    .fontColor(Theme.COLOR_TEXT_TERTIARY)
                }
              }

              // 中断原因
              if (session.interruptionReason && session.interruptionReason !== '') {
                Text('中断原因: ' + session.interruptionReason)
                  .fontSize(Theme.FONT_SIZE_TINY)
                  .fontColor(Theme.COLOR_WARNING)
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
          }
        }, (session: FocusSession) => session.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: Theme.SPACE_LARGE,
        right: Theme.SPACE_LARGE,
        top: Theme.SPACE_MEDIUM
      })
    }
  }

  private async loadData() {
    this.loading = true
    // 并行加载数据
    const results = await Promise.all([
      TaskRepo.findCompleted(getContext(this)),
      SessionRepo.findCompleted(getContext(this), 50),
      SessionRepo.getStats(getContext(this))
    ])
    const tasksResult = results[0]
    const sessionsResult = results[1]
    const statsResult = results[2]

    if (tasksResult.ok && tasksResult.data) {
      this.completedTasks = tasksResult.data
    }

    if (sessionsResult.ok && sessionsResult.data) {
      this.recentSessions = sessionsResult.data
    }

    if (statsResult.ok && statsResult.data) {
      this.stats = statsResult.data
    }

    this.loading = false
  }

  private formatDurationLong(ms: number): string {
    const seconds = Math.floor(ms / 1000)
    const minutes = Math.floor(seconds / 60)
    const hours = Math.floor(minutes / 60)
    
    if (hours > 0) {
      return hours + '小时' + (minutes % 60) + '分钟'
    } else if (minutes > 0) {
      return minutes + '分钟'
    } else {
      return seconds + '秒'
    }
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

    return month + '月' + day + '日 ' + this.pad(hour) + ':' + this.pad(minute)
  }

  private pad(num: number): string {
    return num < 10 ? '0' + num : num.toString()
  }

  private getSessionTypeLabel(type: string): string {
    switch (type) {
      case 'COUNTDOWN':
        return '倒计时'
      case 'POMODORO':
        return '番茄钟'
      default:
        return '正计时'
    }
  }
}
