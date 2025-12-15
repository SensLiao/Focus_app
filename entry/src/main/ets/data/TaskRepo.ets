/**
 * 任务 Repository
 * 提供任务的 CRUD 操作
 */

import relationalStore from '@ohos.data.relationalStore'
import { Result, success, fail } from '../model/Result'
import { Task, TaskCreateDTO, TaskUpdateDTO } from '../model/Task'
import { RdbClient } from './RdbClient'
import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

export class TaskRepo {
  /**
   * 创建任务
   */
  static async create(context: Context, dto: TaskCreateDTO): Promise<Result<number>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {
        title: dto.title,
        description: dto.description ?? '',
        created_at: Date.now(),
        is_anonymous: dto.isAnonymous ? 1 : 0,
        total_focus_time: 0
      }

      const rowId = await store.insert('tasks', valueBucket)
      Logger.info(`Task created with id: ${rowId}`)
      return success(rowId)
    } catch (error) {
      Logger.error('Failed to create task', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '创建任务失败')
    }
  }

  /**
   * 更新任务
   */
  static async update(context: Context, id: number, dto: TaskUpdateDTO): Promise<Result<void>> {
    try {
      const store = await RdbClient.getStore(context)
      const valueBucket: relationalStore.ValuesBucket = {}

      if (dto.title !== undefined) {
        valueBucket.title = dto.title
      }
      if (dto.description !== undefined) {
        valueBucket.description = dto.description
      }
      if (dto.completedAt !== undefined) {
        valueBucket.completed_at = dto.completedAt
      }
      if (dto.totalFocusTime !== undefined) {
        valueBucket.total_focus_time = dto.totalFocusTime
      }

      const predicates = new relationalStore.RdbPredicates('tasks')
      predicates.equalTo('id', id)

      const changedRows = await store.update(valueBucket, predicates)
      if (changedRows === 0) {
        return fail(Constants.ERROR_CODE_NOT_FOUND, '任务不存在')
      }

      Logger.info(`Task updated: ${id}`)
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to update task', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '更新任务失败')
    }
  }

  /**
   * 删除任务
   */
  static async delete(context: Context, id: number): Promise<Result<void>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('tasks')
      predicates.equalTo('id', id)

      const deletedRows = await store.delete(predicates)
      if (deletedRows === 0) {
        return fail(Constants.ERROR_CODE_NOT_FOUND, '任务不存在')
      }

      Logger.info(`Task deleted: ${id}`)
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to delete task', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '删除任务失败')
    }
  }

  /**
   * 查询单个任务
   */
  static async findById(context: Context, id: number): Promise<Result<Task>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('tasks')
      predicates.equalTo('id', id)

      const resultSet = await store.query(predicates)
      if (!resultSet.goToFirstRow()) {
        resultSet.close()
        return fail(Constants.ERROR_CODE_NOT_FOUND, '任务不存在')
      }

      const task = TaskRepo.rowToTask(resultSet)
      resultSet.close()

      return success(task)
    } catch (error) {
      Logger.error('Failed to find task by id', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询任务失败')
    }
  }

  /**
   * 查询所有未完成任务
   */
  static async findActive(context: Context): Promise<Result<Task[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('tasks')
      predicates.isNull('completed_at')
      predicates.orderByDesc('created_at')

      const resultSet = await store.query(predicates)
      const tasks: Task[] = []

      while (resultSet.goToNextRow()) {
        tasks.push(TaskRepo.rowToTask(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${tasks.length} active tasks`)
      return success(tasks)
    } catch (error) {
      Logger.error('Failed to find active tasks', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询任务失败')
    }
  }

  /**
   * 查询已完成任务
   */
  static async findCompleted(context: Context): Promise<Result<Task[]>> {
    try {
      const store = await RdbClient.getStore(context)
      const predicates = new relationalStore.RdbPredicates('tasks')
      predicates.isNotNull('completed_at')
      predicates.orderByDesc('completed_at')

      const resultSet = await store.query(predicates)
      const tasks: Task[] = []

      while (resultSet.goToNextRow()) {
        tasks.push(TaskRepo.rowToTask(resultSet))
      }
      resultSet.close()

      Logger.info(`Found ${tasks.length} completed tasks`)
      return success(tasks)
    } catch (error) {
      Logger.error('Failed to find completed tasks', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_DB, '查询任务失败')
    }
  }

  /**
   * 将 ResultSet 行转换为 Task 对象
   */
  private static rowToTask(resultSet: relationalStore.ResultSet): Task {
    return {
      id: resultSet.getLong(resultSet.getColumnIndex('id')),
      title: resultSet.getString(resultSet.getColumnIndex('title')),
      description: resultSet.getString(resultSet.getColumnIndex('description')) || undefined,
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      completedAt: resultSet.isColumnNull(resultSet.getColumnIndex('completed_at'))
        ? undefined
        : resultSet.getLong(resultSet.getColumnIndex('completed_at')),
      isAnonymous: resultSet.getLong(resultSet.getColumnIndex('is_anonymous')) === 1,
      totalFocusTime: resultSet.getLong(resultSet.getColumnIndex('total_focus_time'))
    }
  }
}
