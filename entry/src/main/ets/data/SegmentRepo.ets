/**
 * 专注段 Repository
 * 提供专注段的 CRUD 操作
 */

import relationalStore from '@ohos.data.relationalStore'
import { Result, success, fail } from '../model/Result'
import { FocusSegment, FocusSegmentCreateDTO, FocusSegmentUpdateDTO } from '../model/FocusSegment'
import { RdbClient } from './RdbClient'
import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

export class SegmentRepo {
  /**
   * 创建专注段
   */
  static async create(context: Context, dto: FocusSegmentCreateDTO): Promise<Result<number>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {
        session_id: dto.sessionId,
        segment_index: dto.segmentIndex,
        start_at: dto.startAt,
        duration_ms: 0
      }

      const rowId = await store.insert('focus_segments', valueBucket)
      Logger.info(`Segment created with id: ${rowId}`)
      return success(rowId)
    } catch (error) {
      Logger.error('Failed to create segment', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '创建专注段失败')
    }
  }

  /**
   * 更新专注段
   */
  static async update(context: Context, id: number, dto: FocusSegmentUpdateDTO): Promise<Result<void>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {}

      if (dto.endAt !== undefined) {
        valueBucket.end_at = dto.endAt
      }
      if (dto.durationMs !== undefined) {
        valueBucket.duration_ms = dto.durationMs
      }

      const predicates = new relationalStore.RdbPredicates('focus_segments')
      predicates.equalTo('id', id)

      const changedRows = await store.update(valueBucket, predicates)
      if (changedRows === 0) {
        return fail(Constants.ERROR_CODE_NOT_FOUND, '专注段不存在')
      }

      Logger.info(`Segment updated: ${id}`)
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to update segment', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '更新专注段失败')
    }
  }

  /**
   * 查询会话的所有专注段
   */
  static async findBySessionId(context: Context, sessionId: number): Promise<Result<FocusSegment[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('focus_segments')
      predicates.equalTo('session_id', sessionId)
      predicates.orderByAsc('segment_index')

      const resultSet = await store.query(predicates)
      const segments: FocusSegment[] = []

      while (resultSet.goToNextRow()) {
        segments.push(SegmentRepo.rowToSegment(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${segments.length} segments for session ${sessionId}`)
      return success(segments)
    } catch (error) {
      Logger.error('Failed to find segments by session id', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询专注段失败')
    }
  }

  /**
   * 查询会话的最后一个专注段
   */
  static async findLastBySessionId(context: Context, sessionId: number): Promise<Result<FocusSegment | null>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('focus_segments')
      predicates.equalTo('session_id', sessionId)
      predicates.orderByDesc('segment_index')
      predicates.limitAs(1)

      const resultSet = await store.query(predicates)
      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return success(null)
      }

      const segment = SegmentRepo.rowToSegment(resultSet)
      resultSet.close()

      return success(segment)
    } catch (error) {
      Logger.error('Failed to find last segment', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询专注段失败')
    }
  }

  /**
   * 将 ResultSet 行转换为 FocusSegment 对象
   */
  private static rowToSegment(resultSet: relationalStore.ResultSet): FocusSegment {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      sessionId: resultSet.getLong(resultSet.getColumnIndex('session_id')),
      segmentIndex: resultSet.getLong(resultSet.getColumnIndex('segment_index')),
      startAt: resultSet.getLong(resultSet.getColumnIndex('start_at')),
      endAt: resultSet.isColumnNull(resultSet.getColumnIndex('end_at'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('end_at')),
      durationMs: resultSet.getLong(resultSet.getColumnIndex('duration_ms'))
    }
  }
}
