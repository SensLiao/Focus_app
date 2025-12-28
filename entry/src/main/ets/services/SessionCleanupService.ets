/**
 * Cleanup inconsistent running sessions on app launch.
 */
import { RdbClient } from '../data/RdbClient'
import { Logger } from '../common/logger'
import { SessionStatus } from '../model/SessionStatus'

export class SessionCleanupService {
  static async finalizeRunningSessionsForCompletedTasks(context: Context): Promise<void> {
    try {
      const store = await RdbClient.getStore(context)
      const now = Date.now()
      const updateSessionsSql =
        'UPDATE focus_sessions SET status = ?, end_at = ?, total_duration = (? - start_at) ' +
        'WHERE status = ? AND task_id IN (SELECT id FROM tasks WHERE last_completed_at IS NOT NULL)'
      await store.executeSql(updateSessionsSql, [SessionStatus.FINISHED, now, now, SessionStatus.RUNNING])

      const clearTasksSql =
        'UPDATE tasks SET active_session_id = NULL WHERE last_completed_at IS NOT NULL AND active_session_id IS NOT NULL'
      await store.executeSql(clearTasksSql, [])

      Logger.info('Session cleanup completed for finished tasks with running sessions.')
    } catch (error) {
      Logger.error('Failed to cleanup running sessions', JSON.stringify(error))
    }
  }
}
