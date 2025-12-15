/**
 * 任务实体
 */

export interface Task {
  id: number
  title: string
  description?: string
  createdAt: number        // 创建时间戳（ms）
  completedAt?: number     // 完成时间戳（ms）
  isAnonymous: boolean     // 是否匿名任务（无任务直接计时）
  totalFocusTime: number   // 累计专注时长（ms）
}

export interface TaskCreateDTO {
  title: string
  description?: string
  isAnonymous?: boolean
}

export interface TaskUpdateDTO {
  title?: string
  description?: string
  completedAt?: number
  totalFocusTime?: number
}
