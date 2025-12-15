/**
 * 专注会话实体
 */

import { SessionStatus } from './SessionStatus'

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
}

export interface FocusSessionCreateDTO {
  taskId?: number
  startAt: number
}

export interface FocusSessionUpdateDTO {
  endAt?: number
  status?: SessionStatus
  actualFocusDuration?: number
  totalDuration?: number
  breakCount?: number
  interruptionReason?: string
}
