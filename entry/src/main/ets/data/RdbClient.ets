/**
 * RDB 客户端
 * 负责数据库连接、初始化和表创建
 */

import relationalStore from '@ohos.data.relationalStore'
import { Constants } from '../common/constants'
import { Logger } from '../common/logger'

export class RdbClient {
  private static store: relationalStore.RdbStore | null = null
  private static readonly DB_VERSION = 2 // 升级版本以支持新字段

  /**
   * 获取 RDB Store 实例（单例）
   * 每次连接后启用外键约束
   */
  static async getStore(context: Context): Promise<relationalStore.RdbStore> {
    if (RdbClient.store !== null) {
      return RdbClient.store
    }

    try {
      const config: relationalStore.StoreConfig = {
        name: Constants.DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S1
      }

      RdbClient.store = await relationalStore.getRdbStore(context, config)
      Logger.info('RDB Store initialized')

      // 关键：启用外键约束
      await RdbClient.store.executeSql('PRAGMA foreign_keys = ON;')
      Logger.info('Foreign keys enabled')

      // 初始化表结构和迁移
      await RdbClient.initTables(RdbClient.store)
      await RdbClient.migrate(RdbClient.store)
      Logger.info('Tables initialized and migrated')

      return RdbClient.store
    } catch (error) {
      Logger.error('Failed to get RDB Store', JSON.stringify(error))
      throw new Error('Failed to initialize RDB Store')
    }
  }

  /**
   * 初始化数据库表
   */
  private static async initTables(store: relationalStore.RdbStore): Promise<void> {
    const tables = [
      // 任务表
      `CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        is_anonymous INTEGER NOT NULL DEFAULT 0,
        total_focus_time INTEGER NOT NULL DEFAULT 0
      )`,

      // 会话表
      `CREATE TABLE IF NOT EXISTS focus_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        start_at INTEGER NOT NULL,
        end_at INTEGER,
        status TEXT NOT NULL CHECK(status IN ('RUNNING','PAUSED','FINISHED')),
        actual_focus_duration INTEGER NOT NULL DEFAULT 0,
        total_duration INTEGER NOT NULL DEFAULT 0,
        break_count INTEGER NOT NULL DEFAULT 0,
        interruption_reason TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      )`,

      // 专注段表
      `CREATE TABLE IF NOT EXISTS focus_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        segment_index INTEGER NOT NULL,
        start_at INTEGER NOT NULL,
        end_at INTEGER,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES focus_sessions(id) ON DELETE CASCADE
      )`,

      // 休息事件表
      `CREATE TABLE IF NOT EXISTS break_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        start_at INTEGER NOT NULL,
        end_at INTEGER,
        planned_duration INTEGER NOT NULL,
        actual_duration INTEGER NOT NULL DEFAULT 0,
        is_skipped INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES focus_sessions(id) ON DELETE CASCADE
      )`,

      // 索引
      'CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed_at)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_task_id ON focus_sessions(task_id)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_start ON focus_sessions(start_at)',
      'CREATE INDEX IF NOT EXISTS idx_segments_session_id ON focus_segments(session_id)',
      'CREATE INDEX IF NOT EXISTS idx_breaks_session_id ON break_events(session_id)'
    ]

    for (const sql of tables) {
      await store.executeSql(sql)
    }
  }

  /**
   * 关闭数据库连接
   */
  static async close(): Promise<void> {
    if (RdbClient.store !== null) {
      // RDB Store 没有显式 close 方法，设置为 null 即可
      RdbClient.store = null
      Logger.info('RDB Store closed')
    }
  }

  /**
   * 数据库迁移
   */
  private static async migrate(store: relationalStore.RdbStore): Promise<void> {
    try {
      // 检查是否需要迁移（简单方式：检查列是否存在）
      const checkSql = 'PRAGMA table_info(focus_sessions)'
      const resultSet = await store.querySql(checkSql)
      
      let hasTimeLimitMs = false
      let hasSessionType = false
      let hasRestIntervalMs = false
      let hasRestDurationMs = false
      
      while (resultSet.goToNextRow()) {
        const columnName = resultSet.getString(1) // column name 在 index 1
        if (columnName === 'time_limit_ms') hasTimeLimitMs = true
        if (columnName === 'session_type') hasSessionType = true
        if (columnName === 'rest_interval_ms') hasRestIntervalMs = true
        if (columnName === 'rest_duration_ms') hasRestDurationMs = true
      }
      resultSet.close()

      // 添加缺失的列
      if (!hasTimeLimitMs) {
        await store.executeSql('ALTER TABLE focus_sessions ADD COLUMN time_limit_ms INTEGER')
        Logger.info('Added time_limit_ms column')
      }
      
      if (!hasSessionType) {
        await store.executeSql("ALTER TABLE focus_sessions ADD COLUMN session_type TEXT DEFAULT 'NORMAL' CHECK(session_type IN ('NORMAL','COUNTDOWN','POMODORO'))")
        Logger.info('Added session_type column')
      }
      
      if (!hasRestIntervalMs) {
        await store.executeSql('ALTER TABLE focus_sessions ADD COLUMN rest_interval_ms INTEGER')
        Logger.info('Added rest_interval_ms column')
      }
      
      if (!hasRestDurationMs) {
        await store.executeSql('ALTER TABLE focus_sessions ADD COLUMN rest_duration_ms INTEGER')
        Logger.info('Added rest_duration_ms column')
      }
      
      // interruption_reason 已在原表中定义
      Logger.info('Database migration completed')
    } catch (error) {
      Logger.error('Database migration failed', JSON.stringify(error))
      // 不抛出错误，允许继续运行（可能列已存在）
    }
  }
}
