/**
 * Clear all database content.
 */
import { RdbClient } from '../data/RdbClient'
import { Logger } from '../common/logger'

export class DatabaseResetService {
  static async clearAllData(context: Context): Promise<void> {
    try {
      const store = await RdbClient.getStore(context)
      await store.executeSql('DELETE FROM break_events', [])
      await store.executeSql('DELETE FROM focus_segments', [])
      await store.executeSql('DELETE FROM focus_sessions', [])
      await store.executeSql('DELETE FROM tasks', [])
      Logger.info('Database cleared.')
    } catch (error) {
      Logger.error('Failed to clear database', JSON.stringify(error))
    }
  }
}
