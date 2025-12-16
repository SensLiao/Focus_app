/**
 * 专注会话实体
 */

import { SessionStatus } from './SessionStatus'

// 会话类型
export enum SessionType {
  NORMAL = 'NORMAL',         // 普通模式（正计时）
  COUNTDOWN = 'COUNTDOWN',   // 倒计时模式
  POMODORO = 'POMODORO'      // 番茄钟模式
}

export interface FocusSession {
  id: number
  taskId?: number               // 可空，匿名任务则为空
  startAt: number               // 开始时间戳（ms）
  endAt?: number                // 结束时间戳（ms）
  status: SessionStatus         // 会话状态
  actualFocusDuration: number   // 纯专注时长（不含休息，ms）
  totalDuration: number         // 总时长（含休息/暂停，ms）
  breakCount: number            // 休息次数
  interruptionReason?: string   // 打断原因
  timeLimitMs?: number          // 倒计时时长（ms）
  sessionType: SessionType      // 会话类型
  restIntervalMs?: number       // 休息间隔（番茄钟模式，ms）
  restDurationMs?: number       // 休息时长（番茄钟模式，ms）
}

export interface FocusSessionCreateDTO {
  taskId?: number
  startAt: number
  timeLimitMs?: number          // 倒计时时长
  sessionType?: SessionType     // 默认 NORMAL
  restIntervalMs?: number       // 番茄钟休息间隔
  restDurationMs?: number       // 番茄钟休息时长
}

export interface FocusSessionUpdateDTO {
  endAt?: number
  status?: SessionStatus
  actualFocusDuration?: number
  totalDuration?: number
  breakCount?: number
  interruptionReason?: string
  timeLimitMs?: number          // 允许延长时限
}
