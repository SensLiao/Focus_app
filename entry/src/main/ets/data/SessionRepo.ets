/**
 * 会话 Repository
 * 提供专注会话的 CRUD 操作
 */

import relationalStore from '@ohos.data.relationalStore'
import { Result, success, fail } from '../model/Result'
import { FocusSession, FocusSessionCreateDTO, FocusSessionUpdateDTO, SessionType } from '../model/FocusSession'
import { SessionStatus } from '../model/SessionStatus'
import { RdbClient } from './RdbClient'
import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

export class SessionRepo {
  /**
   * 创建会话
   */
  static async create(context: Context, dto: FocusSessionCreateDTO): Promise<Result<number>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {
        task_id: dto.taskId ?? null,
        start_at: dto.startAt,
        status: SessionStatus.RUNNING,
        actual_focus_duration: 0,
        total_duration: 0,
        break_count: 0,
        session_type: dto.sessionType ?? SessionType.NORMAL,
        time_limit_ms: dto.timeLimitMs ?? null,
        rest_interval_ms: dto.restIntervalMs ?? null,
        rest_duration_ms: dto.restDurationMs ?? null
      }

      const rowId = await store.insert('focus_sessions', valueBucket)
      Logger.info(`Session created with id: ${rowId}`)
      return success(rowId)
    } catch (error) {
      Logger.error('Failed to create session', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '创建会话失败')
    }
  }

  /**
   * 更新会话
   */
  static async update(context: Context, id: number, dto: FocusSessionUpdateDTO): Promise<Result<void>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {}

      if (dto.endAt !== undefined) {
        valueBucket.end_at = dto.endAt
      }
      if (dto.status !== undefined) {
        valueBucket.status = dto.status
      }
      if (dto.actualFocusDuration !== undefined) {
        valueBucket.actual_focus_duration = dto.actualFocusDuration
      }
      if (dto.totalDuration !== undefined) {
        valueBucket.total_duration = dto.totalDuration
      }
      if (dto.breakCount !== undefined) {
        valueBucket.break_count = dto.breakCount
      }
      if (dto.interruptionReason !== undefined) {
        valueBucket.interruption_reason = dto.interruptionReason
      }
      if (dto.timeLimitMs !== undefined) {
        valueBucket.time_limit_ms = dto.timeLimitMs
      }

      const predicates = new relationalStore.RdbPredicates('focus_sessions')
      predicates.equalTo('id', id)

      const changedRows = await store.update(valueBucket, predicates)
      if (changedRows === 0) {
        return fail(Constants.ERROR_CODE_NOT_FOUND, '会话不存在')
      }

      Logger.info(`Session updated: ${id}`)
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to update session', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '更新会话失败')
    }
  }

  /**
   * 查询单个会话
   */
  static async findById(context: Context, id: number): Promise<Result<FocusSession>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('focus_sessions')
      predicates.equalTo('id', id)

      const resultSet = await store.query(predicates)
      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return fail(Constants.ERROR_CODE_NOT_FOUND, '会话不存在')
      }

      const session = SessionRepo.rowToSession(resultSet)
      resultSet.close()

      return success(session)
    } catch (error) {
      Logger.error('Failed to find session by id', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询会话失败')
    }
  }

  /**
   * 查询进行中的会话（用于恢复）
   */
  static async findRunning(context: Context): Promise<Result<FocusSession | null>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('focus_sessions')
      predicates.equalTo('status', SessionStatus.RUNNING)

      const resultSet = await store.query(predicates)
      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        Logger.info('No running session found')
        return success(null)
      }

      const session = SessionRepo.rowToSession(resultSet)
      resultSet.close()

      Logger.info(`Found running session: ${session.id}`)
      return success(session)
    } catch (error) {
      Logger.error('Failed to find running session', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询会话失败')
    }
  }

  /**
   * 查询任务的所有会话
   */
  static async findByTaskId(context: Context, taskId: number): Promise<Result<FocusSession[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('focus_sessions')
      predicates.equalTo('task_id', taskId)
      predicates.orderByDesc('start_at')

      const resultSet = await store.query(predicates)
      const sessions: FocusSession[] = []

      while (resultSet.goToNextRow()) {
        sessions.push(SessionRepo.rowToSession(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${sessions.length} sessions for task ${taskId}`)
      return success(sessions)
    } catch (error) {
      Logger.error('Failed to find sessions by task id', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询会话失败')
    }
  }

  /**
   * 将 ResultSet 行转换为 FocusSession 对象
   */
  private static rowToSession(resultSet: relationalStore.ResultSet): FocusSession {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      taskId: resultSet.isColumnNull(resultSet.getColumnIndex('task_id'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('task_id')),
      startAt: resultSet.getLong(resultSet.getColumnIndex('start_at')),
      endAt: resultSet.isColumnNull(resultSet.getColumnIndex('end_at'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('end_at')),
      status: resultSet.getString(resultSet.getColumnIndex('status')) as SessionStatus,
      actualFocusDuration: resultSet.getLong(resultSet.getColumnIndex('actual_focus_duration')),
      totalDuration: resultSet.getLong(resultSet.getColumnIndex('total_duration')),
      breakCount: resultSet.getLong(resultSet.getColumnIndex('break_count')),
      interruptionReason: resultSet.isColumnNull(resultSet.getColumnIndex('interruption_reason'))
        ? undefined
        : resultSet.getString(resultSet.getColumnIndex('interruption_reason')),
      sessionType: (resultSet.getString(resultSet.getColumnIndex('session_type')) ?? SessionType.NORMAL) as SessionType,
      timeLimitMs: resultSet.isColumnNull(resultSet.getColumnIndex('time_limit_ms'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('time_limit_ms')),
      restIntervalMs: resultSet.isColumnNull(resultSet.getColumnIndex('rest_interval_ms'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('rest_interval_ms')),
      restDurationMs: resultSet.isColumnNull(resultSet.getColumnIndex('rest_duration_ms'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('rest_duration_ms'))
    }
  }

  /**
   * 更新会话的时长（actualFocusDuration 和 totalDuration）
   */
  static async updateDurations(
    context: Context,
    sessionId: number,
    actualFocusDuration: number,
    totalDuration: number
  ): Promise<Result<void>> {
    return await SessionRepo.update(context, sessionId, {
      actualFocusDuration,
      totalDuration
    })
  }

  /**
   * 设置中断原因
   */
  static async setInterruptionReason(
    context: Context,
    sessionId: number,
    reason: string
  ): Promise<Result<void>> {
    return await SessionRepo.update(context, sessionId, {
      interruptionReason: reason
    })
  }

  /**
   * 更新时限（延长倒计时）
   */
  static async updateTimeLimit(
    context: Context,
    sessionId: number,
    newTimeLimitMs: number
  ): Promise<Result<void>> {
    return await SessionRepo.update(context, sessionId, {
      timeLimitMs: newTimeLimitMs
    })
  }

  /**
   * 查询所有已完成的会话
   */
  static async findCompleted(context: Context, limit?: number): Promise<Result<FocusSession[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('focus_sessions')
      predicates.equalTo('status', SessionStatus.FINISHED)
      predicates.orderByDesc('end_at')
      if (limit) {
        predicates.limitAs(limit)
      }

      const resultSet = await store.query(predicates)
      const sessions: FocusSession[] = []

      while (resultSet.goToNextRow()) {
        sessions.push(SessionRepo.rowToSession(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${sessions.length} completed sessions`)
      return success(sessions)
    } catch (error) {
      Logger.error('Failed to find completed sessions', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询已完成会话失败')
    }
  }

  /**
   * 获取统计数据
   */
  static async getStats(context: Context): Promise<Result<SessionStats>> {
    try {
      const store = await RdbClient.getStore(context)

      // 获取总专注时间
      const totalTimeResult = await store.querySql(
        'SELECT SUM(actual_focus_duration) as total FROM focus_sessions WHERE status = ?',
        [SessionStatus.FINISHED]
      )
      let totalFocusTime = 0
      if (totalTimeResult.goToFirstRow()) {
        totalFocusTime = totalTimeResult.getLong(0) || 0
      }
      totalTimeResult.close()
      // 获取总会话数
      const sessionCountResult = await store.querySql(
        'SELECT COUNT(*) as count FROM focus_sessions WHERE status = ?',
        [SessionStatus.FINISHED]
      )
      let sessionCount = 0
      if (sessionCountResult.goToFirstRow()) {
        sessionCount = sessionCountResult.getLong(0) || 0
      }
      sessionCountResult.close()
      // 获取总休息次数
      const breakCountResult = await store.querySql(
        'SELECT SUM(break_count) as total FROM focus_sessions WHERE status = ?',
        [SessionStatus.FINISHED]
      )
      let totalBreaks = 0
      if (breakCountResult.goToFirstRow()) {
        totalBreaks = breakCountResult.getLong(0) || 0
      }
      breakCountResult.close()

      // 今日专注时间
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      const todayStart = today.getTime()
      const todayResult = await store.querySql(
        'SELECT SUM(actual_focus_duration) as total FROM focus_sessions WHERE status = ? AND start_at >= ?',
        [SessionStatus.FINISHED, todayStart]
      )
      let todayFocusTime = 0
      if (todayResult.goToFirstRow()) {
        todayFocusTime = todayResult.getLong(0) || 0
      }
      todayResult.close()
      Logger.info('Stats retrieved successfully')
      return success({
        totalFocusTime,
        sessionCount,
        totalBreaks,
        todayFocusTime
      } as SessionStats)
    } catch (error) {
      Logger.error('Failed to get stats', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '获取统计数据失败')
    }
  }
}

/**
 * 会话统计数据
 */
export interface SessionStats {
  totalFocusTime: number
  sessionCount: number
  totalBreaks: number
  todayFocusTime: number
}
