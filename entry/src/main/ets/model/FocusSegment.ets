/**
 * 专注段实体
 */

export interface FocusSegment {
  id: number
  sessionId: number       // 所属会话
  segmentIndex: number    // 第几段（1/2/3...）
  startAt: number         // 开始时间戳（ms）
  endAt?: number          // 结束时间戳（ms）
  durationMs: number      // 时长（ms）
}

export interface FocusSegmentCreateDTO {
  sessionId: number
  segmentIndex: number
  startAt: number
}

export interface FocusSegmentUpdateDTO {
  endAt?: number
  durationMs?: number
}
