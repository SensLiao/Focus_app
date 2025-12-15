/**
 * 任务状态管理
 * 提供任务的状态容器和操作
 */

import { Task, TaskCreateDTO, TaskUpdateDTO } from '../model/Task'
import { TaskRepo } from '../data/TaskRepo'
import { Result, isSuccess, success, fail } from '../model/Result'
import { Logger } from '../common/logger'

@Observed
export class TaskState {
  tasks: Task[] = []
  loading: boolean = false
  error: string | null = null
}

export class TaskStore {
  private static state: TaskState = new TaskState()
  private static context: Context | null = null

  /**
   * 初始化 Store
   */
  static init(context: Context): void {
    TaskStore.context = context
    Logger.info('TaskStore initialized')
  }

  /**
   * 获取状态
   */
  static getState(): TaskState {
    return TaskStore.state
  }

  /**
   * 加载所有活跃任务
   */
  static async loadTasks(): Promise<Result<void>> {
    if (!TaskStore.context) {
      Logger.error('TaskStore not initialized')
      return fail('NOT_INIT', 'Store未初始化')
    }

    TaskStore.state.loading = true
    TaskStore.state.error = null

    const result = await TaskRepo.findActive(TaskStore.context)

    if (isSuccess(result)) {
      TaskStore.state.tasks = result.data
      TaskStore.state.loading = false
      Logger.info(`Loaded ${result.data.length} tasks`)
      return success(undefined)
    } else {
      TaskStore.state.error = result.message
      TaskStore.state.loading = false
      Logger.error('Failed to load tasks', result.message)
      return result
    }
  }

  /**
   * 创建任务
   */
  static async createTask(dto: TaskCreateDTO): Promise<Result<number>> {
    if (!TaskStore.context) {
      return fail('NOT_INIT', 'Store未初始化')
    }

    const result = await TaskRepo.create(TaskStore.context, dto)

    if (isSuccess(result)) {
      await TaskStore.loadTasks()
      Logger.info('Task created and tasks reloaded')
    }

    return result
  }

  /**
   * 更新任务
   */
  static async updateTask(id: number, dto: TaskUpdateDTO): Promise<Result<void>> {
    if (!TaskStore.context) {
      return fail('NOT_INIT', 'Store未初始化')
    }

    const result = await TaskRepo.update(TaskStore.context, id, dto)

    if (isSuccess(result)) {
      await TaskStore.loadTasks()
      Logger.info('Task updated and tasks reloaded')
    }

    return result
  }

  /**
   * 删除任务
   */
  static async deleteTask(id: number): Promise<Result<void>> {
    if (!TaskStore.context) {
      return fail('NOT_INIT', 'Store未初始化')
    }

    const result = await TaskRepo.delete(TaskStore.context, id)

    if (isSuccess(result)) {
      await TaskStore.loadTasks()
      Logger.info('Task deleted and tasks reloaded')
    }

    return result
  }

  /**
   * 完成任务
   */
  static async completeTask(id: number, totalFocusTime: number): Promise<Result<void>> {
    return TaskStore.updateTask(id, {
      completedAt: Date.now(),
      totalFocusTime: totalFocusTime
    })
  }

  /**
   * 查找任务
   */
  static findTask(id: number): Task | undefined {
    return TaskStore.state.tasks.find(task => task.id === id)
  }
}
