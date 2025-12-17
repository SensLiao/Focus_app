/**
 * 任务实体
 */

export interface Task {
  id: number
  title: string
  description?: string
  createdAt: number          // 创建时间戳（ms）
  lastCompletedAt?: number   // 最后完成时间戳（ms，支持多次完成）
  isAnonymous: boolean       // 是否匿名任务（无任务直接计时）
  totalFocusTime: number     // 累计专注时长（ms）
  activeSessionId?: number   // 当前活动会话ID（用于恢复和UI指示）
  sessionCount: number       // 完成的会话总数
}

export interface TaskCreateDTO {
  title: string
  description?: string
  isAnonymous?: boolean
}

export interface TaskUpdateDTO {
  title?: string
  description?: string
  lastCompletedAt?: number
  totalFocusTime?: number
  activeSessionId?: number
  sessionCount?: number
}
