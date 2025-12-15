/**
 * 会话 Repository
 * 提供专注会话的 CRUD 操作
 */

import relationalStore from '@ohos.data.relationalStore'
import { Result, success, fail } from '../model/Result'
import { FocusSession, FocusSessionCreateDTO, FocusSessionUpdateDTO } from '../model/FocusSession'
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
        break_count: 0
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
        : resultSet.getString(resultSet.getColumnIndex('interruption_reason'))
    }
  }
}
