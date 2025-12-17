/**
 * RDB 客户端
 * 负责数据库连接、初始化和表创建
 */

import relationalStore from '@ohos.data.relationalStore'
import { Constants } from '../common/constants'
import { Logger } from '../common/logger'

export class RdbClient {
  private static store: relationalStore.RdbStore | null = null
  private static readonly DB_VERSION = 3 // 升级版本以支持活动会话追踪

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
        securityLevel: relationalStore.SecurityLevel.S2  // S2级别：应用私有目录，适合大多数场景
        // 如需加密，添加: encrypt: true, encryptKey: new Uint8Array([...])
      }

      RdbClient.store = await relationalStore.getRdbStore(context, config)
      Logger.info('RDB Store initialized')

      // 关键：启用外键约束
      await RdbClient.store.executeSql('PRAGMA foreign_keys = ON;')
      Logger.info('Foreign keys enabled')

      // 初始化表结构和迁移
      await RdbClient.initTables(RdbClient.store)
      await RdbClient.migrate(RdbClient.store)
      
      // 验证表结构
      await RdbClient.verifyTables(RdbClient.store)
      
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
        last_completed_at INTEGER,
        is_anonymous INTEGER NOT NULL DEFAULT 0,
        total_focus_time INTEGER NOT NULL DEFAULT 0,
        active_session_id INTEGER,
        session_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (active_session_id) REFERENCES focus_sessions(id) ON DELETE SET NULL
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
      'CREATE INDEX IF NOT EXISTS idx_tasks_last_completed ON tasks(last_completed_at)',
      'CREATE INDEX IF NOT EXISTS idx_tasks_active_session ON tasks(active_session_id)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_task_id ON focus_sessions(task_id)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_start ON focus_sessions(start_at)',
      'CREATE INDEX IF NOT EXISTS idx_sessions_status ON focus_sessions(status)',
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
      // 检查 tasks 表的列
      const checkTaskSql = 'PRAGMA table_info(tasks)'
      const taskResultSet = await store.querySql(checkTaskSql)
      
      let hasLastCompletedAt = false
      let hasActiveSessionId = false
      let hasSessionCount = false
      
      while (taskResultSet.goToNextRow()) {
        const columnName = taskResultSet.getString(1)
        if (columnName === 'last_completed_at') hasLastCompletedAt = true
        if (columnName === 'active_session_id') hasActiveSessionId = true
        if (columnName === 'session_count') hasSessionCount = true
      }
      taskResultSet.close()

      // 添加 tasks 缺失的列
      if (!hasLastCompletedAt) {
        // 迁移旧的 completed_at 数据到 last_completed_at
        await store.executeSql('ALTER TABLE tasks ADD COLUMN last_completed_at INTEGER')
        await store.executeSql('UPDATE tasks SET last_completed_at = completed_at WHERE completed_at IS NOT NULL')
        Logger.info('Added last_completed_at column and migrated data')
      }
      
      if (!hasActiveSessionId) {
        await store.executeSql('ALTER TABLE tasks ADD COLUMN active_session_id INTEGER')
        Logger.info('Added active_session_id column')
      }
      
      if (!hasSessionCount) {
        await store.executeSql('ALTER TABLE tasks ADD COLUMN session_count INTEGER NOT NULL DEFAULT 0')
        Logger.info('Added session_count column')
      }
      
      // 检查 focus_sessions 表的列
      const checkSessionSql = 'PRAGMA table_info(focus_sessions)'
      const sessionResultSet = await store.querySql(checkSessionSql)
      
      let hasTimeLimitMs = false
      let hasSessionType = false
      let hasRestIntervalMs = false
      let hasRestDurationMs = false
      
      while (sessionResultSet.goToNextRow()) {
        const columnName = sessionResultSet.getString(1) // column name 在 index 1
        if (columnName === 'time_limit_ms') hasTimeLimitMs = true
        if (columnName === 'session_type') hasSessionType = true
        if (columnName === 'rest_interval_ms') hasRestIntervalMs = true
        if (columnName === 'rest_duration_ms') hasRestDurationMs = true
      }
      sessionResultSet.close()

      // 添加 focus_sessions 缺失的列
      if (!hasTimeLimitMs) {
        await store.executeSql('ALTER TABLE focus_sessions ADD COLUMN time_limit_ms INTEGER')
        Logger.info('Added time_limit_ms column')
      }
      
      if (!hasSessionType) {
        await store.executeSql("ALTER TABLE focus_sessions ADD COLUMN session_type TEXT DEFAULT 'NORMAL'")
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
      
      // 检查 break_events 表的列
      const checkBreakSql = 'PRAGMA table_info(break_events)'
      const breakResultSet = await store.querySql(checkBreakSql)
      
      let hasReason = false
      while (breakResultSet.goToNextRow()) {
        const columnName = breakResultSet.getString(1)
        if (columnName === 'reason') hasReason = true
      }
      breakResultSet.close()

      // 添加 break_events 缺失的列
      if (!hasReason) {
        await store.executeSql('ALTER TABLE break_events ADD COLUMN reason TEXT')
        Logger.info('Added reason column to break_events')
      }
      
      Logger.info('Database migration completed')
    } catch (error) {
      Logger.error('Database migration failed', JSON.stringify(error))
      // 不抛出错误，允许继续运行（可能列已存在）
    }
  }

  /**
   * 验证表结构
   */
  private static async verifyTables(store: relationalStore.RdbStore): Promise<void> {
    const requiredTables = ['tasks', 'focus_sessions', 'focus_segments', 'break_events']
    
    for (const tableName of requiredTables) {
      const verifySql = `SELECT name FROM sqlite_master WHERE type='table' AND name='${tableName}'`
      const resultSet = await store.querySql(verifySql)
      
      if (resultSet.rowCount === 0) {
        Logger.error(`Table ${tableName} does not exist`)
        resultSet.close()
        throw new Error(`Required table ${tableName} is missing`)
      }
      
      resultSet.close()
      Logger.info(`Table ${tableName} verified`)
    }
  }

  /**
   * 数据库完整性检查
   */
  static async checkIntegrity(context: Context): Promise<boolean> {
    try {
      const store = await RdbClient.getStore(context)
      const resultSet = await store.querySql('PRAGMA integrity_check')
      
      let isValid = false
      if (resultSet.goToFirstRow()) {
        const result = resultSet.getString(0)
        isValid = result === 'ok'
        Logger.info(`Database integrity check: ${result}`)
      }
      
      resultSet.close()
      return isValid
    } catch (error) {
      Logger.error('Integrity check failed', JSON.stringify(error))
      return false
    }
  }

  /**
   * 开始事务
   */
  static async beginTransaction(context: Context): Promise<void> {
    const store = await RdbClient.getStore(context)
    await store.executeSql('BEGIN TRANSACTION')
    Logger.info('Transaction started')
  }

  /**
   * 提交事务
   */
  static async commitTransaction(context: Context): Promise<void> {
    const store = await RdbClient.getStore(context)
    await store.executeSql('COMMIT')
    Logger.info('Transaction committed')
  }

  /**
   * 回滚事务
   */
  static async rollbackTransaction(context: Context): Promise<void> {
    const store = await RdbClient.getStore(context)
    await store.executeSql('ROLLBACK')
    Logger.info('Transaction rolled back')
  }
}
