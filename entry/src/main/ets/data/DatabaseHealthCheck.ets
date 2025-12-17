/**
 * 数据库健康检查工具
 * 用于验证 RDB 数据库的有效性和完整性
 */

import { RdbClient } from './RdbClient'
import { Logger } from '../common/logger'

export interface HealthCheckResult {
  isHealthy: boolean
  checks: {
    connectionValid: boolean
    tablesExist: boolean
    integrityOk: boolean
    foreignKeysEnabled: boolean
  }
  errors: string[]
}

export class DatabaseHealthCheck {
  /**
   * 执行完整的数据库健康检查
   */
  static async performCheck(context: Context): Promise<HealthCheckResult> {
    const result: HealthCheckResult = {
      isHealthy: true,
      checks: {
        connectionValid: false,
        tablesExist: false,
        integrityOk: false,
        foreignKeysEnabled: false
      },
      errors: []
    }

    try {
      // 1. 检查数据库连接
      result.checks.connectionValid = await this.checkConnection(context, result.errors)
      
      // 2. 检查表结构
      result.checks.tablesExist = await this.checkTables(context, result.errors)
      
      // 3. 检查数据库完整性
      result.checks.integrityOk = await this.checkIntegrity(context, result.errors)
      
      // 4. 检查外键约束
      result.checks.foreignKeysEnabled = await this.checkForeignKeys(context, result.errors)
      
      // 综合判断
      result.isHealthy = Object.values(result.checks).every(check => check === true)
      
      if (result.isHealthy) {
        Logger.info('Database health check passed')
      } else {
        Logger.warn('Database health check failed', JSON.stringify(result))
      }
      
    } catch (error) {
      result.isHealthy = false
      result.errors.push(`Health check exception: ${JSON.stringify(error)}`)
      Logger.error('Health check exception', JSON.stringify(error))
    }

    return result
  }

  /**
   * 检查数据库连接
   */
  private static async checkConnection(context: Context, errors: string[]): Promise<boolean> {
    try {
      const store = await RdbClient.getStore(context)
      return store !== null
    } catch (error) {
      errors.push(`Connection failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查表结构
   */
  private static async checkTables(context: Context, errors: string[]): Promise<boolean> {
    try {
      const store = await RdbClient.getStore(context)
      const requiredTables = ['tasks', 'focus_sessions', 'focus_segments', 'break_events']
      
      for (const tableName of requiredTables) {
        const sql = `SELECT name FROM sqlite_master WHERE type='table' AND name='${tableName}'`
        const resultSet = await store.querySql(sql)
        const exists = resultSet.rowCount > 0
        resultSet.close()
        
        if (!exists) {
          errors.push(`Table ${tableName} does not exist`)
          return false
        }
      }
      
      return true
    } catch (error) {
      errors.push(`Table check failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查数据库完整性
   */
  private static async checkIntegrity(context: Context, errors: string[]): Promise<boolean> {
    try {
      return await RdbClient.checkIntegrity(context)
    } catch (error) {
      errors.push(`Integrity check failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 检查外键约束
   */
  private static async checkForeignKeys(context: Context, errors: string[]): Promise<boolean> {
    try {
      const store = await RdbClient.getStore(context)
      const resultSet = await store.querySql('PRAGMA foreign_keys')
      
      let enabled = false
      if (resultSet.goToFirstRow()) {
        enabled = resultSet.getLong(0) === 1
      }
      resultSet.close()
      
      if (!enabled) {
        errors.push('Foreign keys are not enabled')
      }
      
      return enabled
    } catch (error) {
      errors.push(`Foreign key check failed: ${JSON.stringify(error)}`)
      return false
    }
  }

  /**
   * 获取数据库统计信息
   */
  static async getDatabaseStats(context: Context): Promise<{
    taskCount: number
    sessionCount: number
    segmentCount: number
    breakCount: number
  }> {
    try {
      const store = await RdbClient.getStore(context)
      
      const stats = {
        taskCount: 0,
        sessionCount: 0,
        segmentCount: 0,
        breakCount: 0
      }
      
      // 统计各表记录数
      const tables = ['tasks', 'focus_sessions', 'focus_segments', 'break_events']
      const keys: (keyof typeof stats)[] = ['taskCount', 'sessionCount', 'segmentCount', 'breakCount']
      
      for (let i = 0; i < tables.length; i++) {
        const resultSet = await store.querySql(`SELECT COUNT(*) FROM ${tables[i]}`)
        if (resultSet.goToFirstRow()) {
          stats[keys[i]] = resultSet.getLong(0)
        }
        resultSet.close()
      }
      
      Logger.info('Database stats', JSON.stringify(stats))
      return stats
      
    } catch (error) {
      Logger.error('Failed to get database stats', JSON.stringify(error))
      return {
        taskCount: -1,
        sessionCount: -1,
        segmentCount: -1,
        breakCount: -1
      }
    }
  }

  /**
   * 打印诊断信息
   */
  static async printDiagnostics(context: Context): Promise<void> {
    Logger.info('=== Database Diagnostics ===')
    
    const healthResult = await this.performCheck(context)
    Logger.info('Health Check Result:', JSON.stringify(healthResult, null, 2))
    
    const stats = await this.getDatabaseStats(context)
    Logger.info('Database Stats:', JSON.stringify(stats, null, 2))
    
    Logger.info('=== End Diagnostics ===')
  }
}
