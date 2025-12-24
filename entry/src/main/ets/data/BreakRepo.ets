/**
 * 休息事件 Repository
 * 提供休息事件的 CRUD 操作
 */

import relationalStore from '@ohos.data.relationalStore'
import { Result, success, fail } from '../model/Result'
import { BreakEvent, BreakEventCreateDTO, BreakEventUpdateDTO } from '../model/BreakEvent'
import { RdbClient } from './RdbClient'
import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

export class BreakRepo {
  /**
   * 创建休息事件
   */
  static async create(context: Context, dto: BreakEventCreateDTO): Promise<Result<number>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {
        session_id: dto.sessionId,
        start_at: dto.startAt,
        planned_duration: dto.plannedDuration,
        actual_duration: 0,
        is_skipped: 0
      }
      
      // 添加 reason 字段支持
      if (dto.reason !== undefined) {
        valueBucket.reason = dto.reason
      }

      const rowId = await store.insert('break_events', valueBucket)
      Logger.info(`Break event created with id: ${rowId}`)
      return success(rowId)
    } catch (error) {
      Logger.error('Failed to create break event', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '创建休息事件失败')
    }
  }

  /**
   * 更新休息事件
   */
  static async update(context: Context, id: number, dto: BreakEventUpdateDTO): Promise<Result<void>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {}

      if (dto.endAt !== undefined) {
        valueBucket.end_at = dto.endAt
      }
      if (dto.actualDuration !== undefined) {
        valueBucket.actual_duration = dto.actualDuration
      }
      if (dto.isSkipped !== undefined) {
        valueBucket.is_skipped = dto.isSkipped ? 1 : 0
      }
      if (dto.reason !== undefined) {
        valueBucket.reason = dto.reason
      }

      const predicates = new relationalStore.RdbPredicates('break_events')
      predicates.equalTo('id', id)

      const changedRows = await store.update(valueBucket, predicates)
      if (changedRows === 0) {
        return fail(Constants.ERROR_CODE_NOT_FOUND, '休息事件不存在')
      }

      Logger.info(`Break event updated: ${id}`)
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to update break event', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '更新休息事件失败')
    }
  }

  /**
   * 查询会话的所有休息事件
   */
  static async findBySessionId(context: Context, sessionId: number): Promise<Result<BreakEvent[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('break_events')
      predicates.equalTo('session_id', sessionId)
      predicates.orderByAsc('start_at')

      const resultSet = await store.query(predicates)
      const breaks: BreakEvent[] = []

      while (resultSet.goToNextRow()) {
        breaks.push(BreakRepo.rowToBreakEvent(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${breaks.length} break events for session ${sessionId}`)
      return success(breaks)
    } catch (error) {
      Logger.error('Failed to find break events by session id', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询休息事件失败')
    }
  }

  /**
   * 按时间范围查询休息事件（包含跨天事件）
   */
  static async findByTimeRange(
    context: Context,
    startAt: number,
    endAt: number
  ): Promise<Result<BreakEvent[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('break_events')
      predicates.lessThan('start_at', endAt)
      predicates.and()
      predicates.beginWrap()
      predicates.isNull('end_at')
      predicates.or()
      predicates.greaterThanOrEqualTo('end_at', startAt)
      predicates.endWrap()
      predicates.orderByAsc('start_at')

      const resultSet = await store.query(predicates)
      const breaks: BreakEvent[] = []

      while (resultSet.goToNextRow()) {
        breaks.push(BreakRepo.rowToBreakEvent(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${breaks.length} break events in range`)
      return success(breaks)
    } catch (error) {
      Logger.error('Failed to find break events by time range', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询休息事件失败')
    }
  }

  /**
   * 将 ResultSet 行转换为 BreakEvent 对象
   */
  private static rowToBreakEvent(resultSet: relationalStore.ResultSet): BreakEvent {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      sessionId: resultSet.getLong(resultSet.getColumnIndex('session_id')),
      startAt: resultSet.getLong(resultSet.getColumnIndex('start_at')),
      endAt: resultSet.isColumnNull(resultSet.getColumnIndex('end_at'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('end_at')),
      plannedDuration: resultSet.getLong(resultSet.getColumnIndex('planned_duration')),
      actualDuration: resultSet.getLong(resultSet.getColumnIndex('actual_duration')),
      isSkipped: resultSet.getLong(resultSet.getColumnIndex('is_skipped')) === 1,
      reason: resultSet.isColumnNull(resultSet.getColumnIndex('reason'))
        ? undefined
        : resultSet.getString(resultSet.getColumnIndex('reason'))
    }
  }
}
