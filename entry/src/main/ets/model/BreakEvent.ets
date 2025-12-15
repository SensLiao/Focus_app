/**
 * 休息事件实体
 */

export interface BreakEvent {
  id: number
  sessionId: number         // 所属会话
  startAt: number           // 开始时间戳（ms）
  endAt?: number            // 结束时间戳（ms）
  plannedDuration: number   // 计划休息时长（ms）
  actualDuration: number    // 实际休息时长（ms）
  isSkipped: boolean        // 是否跳过
}

export interface BreakEventCreateDTO {
  sessionId: number
  startAt: number
  plannedDuration: number
}

export interface BreakEventUpdateDTO {
  endAt?: number
  actualDuration?: number
  isSkipped?: boolean
}
