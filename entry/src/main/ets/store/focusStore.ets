/**
 * 专注会话状态管理
 * 提供专注会话的状态容器和操作
 */

import { FocusSession, SessionType } from '../model/FocusSession'
import { FocusSegment } from '../model/FocusSegment'
import { SessionStatus } from '../model/SessionStatus'
import { SessionRepo } from '../data/SessionRepo'
import { SegmentRepo } from '../data/SegmentRepo'
import { BreakRepo } from '../data/BreakRepo'
import { TaskRepo } from '../data/TaskRepo'
import { TimerService } from '../services/TimerService'
import { ReminderService } from '../services/ReminderService'
import { Result, success, fail } from '../model/Result'
import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

@Observed
export class FocusState {
  currentSession: FocusSession | null = null
  currentSegment: FocusSegment | null = null
  currentTaskId: number | null = null
  isBreaking: boolean = false
  breakStartAt: number | null = null
  breakDuration: number = 0
  elapsedTime: number = 0
  breakElapsedTime: number = 0
  returnReminderId: number = -1
  breakReminderId: number = -1
  remainingTime: number = 0 // 倒计时剩余时间（ms）
}

export class FocusStore {
  private static state: FocusState = new FocusState()
  private static context: Context | null = null

  /**
   * 初始化 Store
   */
  static init(context: Context): void {
    FocusStore.context = context
    Logger.info('FocusStore initialized')
  }

  /**
   * 获取状态
   */
  static getState(): FocusState {
    return FocusStore.state
  }
  /**
   * 开始专注（新会话）
   */
  static async startFocus(
    taskId?: number,
    timeLimitMs?: number,
    sessionType?: SessionType,
    restIntervalMs?: number,
    restDurationMs?: number
  ): Promise<Result<void>> {
    if (!FocusStore.context) {
      return fail('NOT_INIT', 'Store未初始化')
    }

    if (FocusStore.state.currentSession !== null) {
      return fail('ALREADY_RUNNING', '已有进行中的会话')
    }

    const now = Date.now()

    // 创建会话
    const sessionResult = await SessionRepo.create(FocusStore.context, {
      taskId: taskId,
      startAt: now,
      timeLimitMs: timeLimitMs,
      sessionType: sessionType ?? SessionType.NORMAL,
      restIntervalMs: restIntervalMs,
      restDurationMs: restDurationMs
    })

    if (!sessionResult.ok) {
      return fail(sessionResult.code, sessionResult.message)
    }
    const sessionId = sessionResult.data

    // 创建第一个专注段
    const segmentResult = await SegmentRepo.create(FocusStore.context, {
      sessionId: sessionId,
      segmentIndex: 1,
      startAt: now
    })

    if (!segmentResult.ok) {
      return fail(segmentResult.code, segmentResult.message)
    }

    // 更新状态
    FocusStore.state.currentSession = {
      id: sessionId,
      taskId: taskId,
      startAt: now,
      status: SessionStatus.RUNNING,
      actualFocusDuration: 0,
      totalDuration: 0,
      breakCount: 0,
      sessionType: sessionType ?? SessionType.NORMAL,
      timeLimitMs: timeLimitMs,
      restIntervalMs: restIntervalMs,
      restDurationMs: restDurationMs
    }

    FocusStore.state.currentSegment = {
      id: segmentResult.data,
      sessionId: sessionId,
      segmentIndex: 1,
      startAt: now,
      durationMs: 0
    }

    FocusStore.state.currentTaskId = taskId ?? null
    FocusStore.state.elapsedTime = 0
    FocusStore.state.remainingTime = timeLimitMs ?? 0

    // 启动计时器（倒计时模式或普通模式）
    TimerService.start((elapsedMs) => {
      FocusStore.state.elapsedTime = elapsedMs
      
      // 倒计时模式更新剩余时间
      if (timeLimitMs && timeLimitMs > 0) {
        FocusStore.state.remainingTime = Math.max(0, timeLimitMs - elapsedMs)
        
        // 倒计时结束自动完成
        if (FocusStore.state.remainingTime <= 0) {
          FocusStore.finishFocus()
        }
      }
    })

    Logger.info(`Focus started for task ${taskId ?? 'anonymous'}, type: ${sessionType ?? SessionType.NORMAL}`)
    return success(undefined)
  }

  /**
   * 暂停专注
   */
  static async pauseFocus(): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.currentSession || !FocusStore.state.currentSegment) {
      return fail('NO_SESSION', '无进行中的会话')
    }

    // 暂停计时器
    const elapsedMs = TimerService.pause()
    const now = Date.now()

    // 更新当前段
    await SegmentRepo.update(FocusStore.context, FocusStore.state.currentSegment.id, {
      endAt: now,
      durationMs: elapsedMs
    })

    // 更新会话状态
    const session = FocusStore.state.currentSession
    const newActualDuration = session.actualFocusDuration + elapsedMs
    const newTotalDuration = now - session.startAt

    await SessionRepo.update(FocusStore.context, session.id, {
      status: SessionStatus.PAUSED,
      actualFocusDuration: newActualDuration,
      totalDuration: newTotalDuration,
      interruptionReason: Constants.INTERRUPTION_USER_PAUSED
    })

    FocusStore.state.currentSession.status = SessionStatus.PAUSED
    FocusStore.state.currentSession.actualFocusDuration = newActualDuration
    FocusStore.state.currentSession.totalDuration = newTotalDuration

    Logger.info(`Focus paused at ${elapsedMs}ms`)
    return success(undefined)
  }

  /**
   * 继续专注（新段）
   */
  static async resumeFocus(): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.currentSession) {
      return fail('NO_SESSION', '无暂停的会话')
    }

    if (FocusStore.state.currentSession.status !== SessionStatus.PAUSED) {
      return fail('NOT_PAUSED', '会话未暂停')
    }

    const now = Date.now()
    const sessionId = FocusStore.state.currentSession.id
    // 获取当前会话的最后一个段索引
    const segmentsResult = await SegmentRepo.findBySessionId(FocusStore.context, sessionId)
    if (!segmentsResult.ok) {
      return fail(segmentsResult.code, segmentsResult.message)
    }

    const nextIndex = segmentsResult.data.length + 1
    // 创建新的专注段
    const segmentResult = await SegmentRepo.create(FocusStore.context, {
      sessionId: sessionId,
      segmentIndex: nextIndex,
      startAt: now
    })

    if (!segmentResult.ok) {
      return fail(segmentResult.code, segmentResult.message)
    }

    // 更新会话状态
    await SessionRepo.update(FocusStore.context, sessionId, {
      status: SessionStatus.RUNNING
    })

    FocusStore.state.currentSession.status = SessionStatus.RUNNING
    FocusStore.state.currentSegment = {
      id: segmentResult.data,
      sessionId: sessionId,
      segmentIndex: nextIndex,
      startAt: now,
      durationMs: 0
    }
    FocusStore.state.elapsedTime = 0

    // 启动计时器
    TimerService.start((elapsedMs) => {
      FocusStore.state.elapsedTime = elapsedMs
    })

    Logger.info(`Focus resumed with segment ${nextIndex}`)
    return success(undefined)
  }

  /**
   * 结束专注
   */
  static async finishFocus(): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.currentSession) {
      return fail('NO_SESSION', '无进行中的会话')
    }

    const session = FocusStore.state.currentSession
    const now = Date.now()
    let actualDuration = session.actualFocusDuration

    // 如果当前正在运行，先暂停当前段
    if (session.status === SessionStatus.RUNNING && FocusStore.state.currentSegment) {
      const elapsedMs = TimerService.stop()
      await SegmentRepo.update(FocusStore.context, FocusStore.state.currentSegment.id, {
        endAt: now,
        durationMs: elapsedMs
      })
      actualDuration += elapsedMs
    } else {
      TimerService.stop()
    }

    // 更新会话为完成状态
    const totalDuration = now - session.startAt
    await SessionRepo.update(FocusStore.context, session.id, {
      endAt: now,
      status: SessionStatus.FINISHED,
      actualFocusDuration: actualDuration,
      totalDuration: totalDuration,
      interruptionReason: Constants.INTERRUPTION_USER_FINISHED
    })
    // 如果关联了任务，更新任务的总专注时间并完成
    if (session.taskId !== undefined) {
      const taskResult = await TaskRepo.findById(FocusStore.context, session.taskId)
      if (taskResult.ok) {
        const task = taskResult.data
        await TaskRepo.update(FocusStore.context, session.taskId, {
          completedAt: now,
          totalFocusTime: task.totalFocusTime + actualDuration
        })
      }
    }

    // 清空状态
    FocusStore.clearState()

    Logger.info(`Focus finished with ${actualDuration}ms`)
    return success(undefined)
  }

  /**
   * 开始休息
   */
  static async startBreak(durationMs: number): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.currentSession) {
      return fail('NO_SESSION', '无进行中的会话')
    }

    // 暂停当前专注
    await FocusStore.pauseFocus()

    const now = Date.now()
    const sessionId = FocusStore.state.currentSession.id
    // 创建休息事件
    const breakResult = await BreakRepo.create(FocusStore.context, {
      sessionId: sessionId,
      startAt: now,
      plannedDuration: durationMs
    })

    if (!breakResult.ok) {
      return fail(breakResult.code, breakResult.message)
    }

    // 更新会话休息次数
    const newBreakCount = FocusStore.state.currentSession.breakCount + 1
    await SessionRepo.update(FocusStore.context, sessionId, {
      breakCount: newBreakCount
    })

    FocusStore.state.currentSession.breakCount = newBreakCount
    FocusStore.state.isBreaking = true
    FocusStore.state.breakStartAt = now
    FocusStore.state.breakDuration = durationMs
    FocusStore.state.breakElapsedTime = 0

    // 创建休息结束提醒
    const reminderResult = await ReminderService.createBreakEndReminder(durationMs)
    if (reminderResult.ok) {
      FocusStore.state.breakReminderId = reminderResult.data
    }

    // 启动休息计时器
    TimerService.start((elapsedMs) => {
      FocusStore.state.breakElapsedTime = elapsedMs
      // 自动结束休息
      if (elapsedMs >= durationMs) {
        FocusStore.finishBreak()
      }
    })

    Logger.info(`Break started for ${durationMs}ms`)
    return success(undefined)
  }

  /**
   * 结束休息
   */
  static async finishBreak(): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.isBreaking) {
      return fail('NOT_BREAKING', '未在休息中')
    }

    const elapsedMs = TimerService.stop()
    const now = Date.now()

    // 更新休息事件（简化版：假设只有一个最新的）
    // 生产环境需要保存 breakId

    FocusStore.state.isBreaking = false
    FocusStore.state.breakStartAt = null
    FocusStore.state.breakElapsedTime = 0

    // 取消提醒
    if (FocusStore.state.breakReminderId !== -1) {
      await ReminderService.cancelReminder(FocusStore.state.breakReminderId)
      FocusStore.state.breakReminderId = -1
    }

    Logger.info(`Break finished after ${elapsedMs}ms`)
    return success(undefined)
  }

  /**
   * 处理后台事件
   */
  static async handleBackground(): Promise<void> {
    if (FocusStore.state.currentSession?.status === SessionStatus.RUNNING) {
      // 暂停当前会话
      await FocusStore.pauseFocus()

      // 创建返回提醒
      const result = await ReminderService.createReturnReminder()
      if (result.ok) {
        FocusStore.state.returnReminderId = result.data
      }

      Logger.info('Handled background event')
    }
  }

  /**
   * 处理前台事件
   */
  static async handleForeground(): Promise<void> {
    // 取消返回提醒
    if (FocusStore.state.returnReminderId !== -1) {
      await ReminderService.cancelReminder(FocusStore.state.returnReminderId)
      FocusStore.state.returnReminderId = -1
    }

    Logger.info('Handled foreground event')
  }

  /**
   * 检查并恢复未完成的会话
   */
  static async checkAndRecoverSession(): Promise<Result<FocusSession | null>> {
    if (!FocusStore.context) {
      return fail('NOT_INIT', 'Store未初始化')
    }

    const result = await SessionRepo.findRunning(FocusStore.context)
    if (!result.ok || result.data === null) {
      return result
    }

    const session = result.data

    // 标记为被打断
    await SessionRepo.update(FocusStore.context, session.id, {
      status: SessionStatus.PAUSED,
      interruptionReason: Constants.INTERRUPTION_APP_KILLED
    })

    Logger.info('Recovered interrupted session')
    return success(session)
  }

  /**
   * 清空状态
   */
  private static clearState(): void {
    FocusStore.state.currentSession = null
    FocusStore.state.currentSegment = null
    FocusStore.state.currentTaskId = null
    FocusStore.state.isBreaking = false
    FocusStore.state.breakStartAt = null
    FocusStore.state.elapsedTime = 0
    FocusStore.state.breakElapsedTime = 0
    FocusStore.state.returnReminderId = -1
    FocusStore.state.breakReminderId = -1
    FocusStore.state.remainingTime = 0
  }

  /**
   * 延长时限（倒计时模式）
   */
  static async extendTimeLimit(additionalMs: number): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.currentSession) {
      return fail('NO_SESSION', '无进行中的会话')
    }

    const session = FocusStore.state.currentSession
    if (!session.timeLimitMs || session.timeLimitMs <= 0) {
      return fail('NOT_COUNTDOWN', '非倒计时模式')
    }

    const newTimeLimit = session.timeLimitMs + additionalMs
    
    // 更新数据库
    await SessionRepo.updateTimeLimit(FocusStore.context, session.id, newTimeLimit)
    
    // 更新状态
    FocusStore.state.currentSession.timeLimitMs = newTimeLimit
    FocusStore.state.remainingTime = newTimeLimit - FocusStore.state.elapsedTime

    Logger.info(`Time limit extended by ${additionalMs}ms, new limit: ${newTimeLimit}ms`)
    return success(undefined)
  }

  /**
   * 设置中断原因
   */
  static async setInterruptionReason(reason: string): Promise<Result<void>> {
    if (!FocusStore.context || !FocusStore.state.currentSession) {
      return fail('NO_SESSION', '无进行中的会话')
    }

    await SessionRepo.setInterruptionReason(FocusStore.context, FocusStore.state.currentSession.id, reason)
    FocusStore.state.currentSession.interruptionReason = reason

    Logger.info(`Interruption reason set: ${reason}`)
    return success(undefined)
  }

  /**
   * 跳过休息
   */
  static async skipBreak(): Promise<Result<void>> {
    if (!FocusStore.state.isBreaking) {
      return fail('NOT_BREAKING', '未在休息中')
    }

    TimerService.stop()
    
    // 取消提醒
    if (FocusStore.state.breakReminderId !== -1) {
      await ReminderService.cancelReminder(FocusStore.state.breakReminderId)
      FocusStore.state.breakReminderId = -1
    }

    FocusStore.state.isBreaking = false
    FocusStore.state.breakStartAt = null
    FocusStore.state.breakElapsedTime = 0

    Logger.info('Break skipped')
    return success(undefined)
  }

  /**
   * 延长休息
   */
  static async extendBreak(additionalMs: number): Promise<Result<void>> {
    if (!FocusStore.state.isBreaking) {
      return fail('NOT_BREAKING', '未在休息中')
    }

    FocusStore.state.breakDuration += additionalMs
    
    // 取消旧提醒并创建新提醒
    if (FocusStore.state.breakReminderId !== -1) {
      await ReminderService.cancelReminder(FocusStore.state.breakReminderId)
    }

    const newRemainingTime = FocusStore.state.breakDuration - FocusStore.state.breakElapsedTime
    const reminderResult = await ReminderService.createBreakEndReminder(newRemainingTime)
    if (reminderResult.ok) {
      FocusStore.state.breakReminderId = reminderResult.data
    }

    Logger.info(`Break extended by ${additionalMs}ms, new duration: ${FocusStore.state.breakDuration}ms`)
    return success(undefined)
  }
}
