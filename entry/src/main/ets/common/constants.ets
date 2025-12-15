/**
 * 全局常量
 */

export class Constants {
  // 数据库
  static readonly DB_NAME = 'FocusApp.db'
  static readonly DB_VERSION = 1

  // 计时器
  static readonly TIMER_TICK_INTERVAL = 1000  // 1秒

  // 休息设置（默认值）
  static readonly DEFAULT_BREAK_INTERVAL = 25 * 60 * 1000  // 25分钟
  static readonly DEFAULT_BREAK_DURATION = 5 * 60 * 1000   // 5分钟

  // 提醒
  static readonly RETURN_REMINDER_DELAY = 5 * 60 * 1000    // 离开5分钟后提醒

  // 错误代码
  static readonly ERROR_CODE_DB = 'DB_ERROR'
  static readonly ERROR_CODE_NOT_FOUND = 'NOT_FOUND'
  static readonly ERROR_CODE_INVALID_STATE = 'INVALID_STATE'
  static readonly ERROR_CODE_REMINDER = 'REMINDER_ERROR'

  // 打断原因
  static readonly INTERRUPTION_APP_KILLED = 'APP_KILLED'
  static readonly INTERRUPTION_USER_PAUSED = 'USER_PAUSED'
  static readonly INTERRUPTION_USER_FINISHED = 'USER_FINISHED'
}
