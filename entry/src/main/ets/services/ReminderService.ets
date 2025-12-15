/**
 * 提醒服务
 * 封装 ReminderAgent 能力
 */

import reminderAgentManager from '@ohos.reminderAgentManager'
import { Logger } from '../common/logger'
import { Result, success, fail } from '../model/Result'
import { Constants } from '../common/constants'

export class ReminderService {
  /**
   * 创建计时器提醒
   */
  static async createTimerReminder(
    title: string,
    content: string,
    durationSeconds: number
  ): Promise<Result<number>> {
    try {
      const reminderRequest: reminderAgentManager.ReminderRequestTimer = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_TIMER,
        triggerTimeInSeconds: durationSeconds,
        title: title,
        content: content,
        wantAgent: {
          pkgName: 'com.example.focusapp',
          abilityName: 'EntryAbility'
        }
      }

      const reminderId = await reminderAgentManager.publishReminder(reminderRequest)
      Logger.info(`Reminder created with id: ${reminderId}`)
      return success(reminderId)
    } catch (error) {
      Logger.error('Failed to create reminder', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_REMINDER, '创建提醒失败')
    }
  }

  /**
   * 取消提醒
   */
  static async cancelReminder(reminderId: number): Promise<Result<void>> {
    try {
      await reminderAgentManager.cancelReminder(reminderId)
      Logger.info(`Reminder cancelled: ${reminderId}`)
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to cancel reminder', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_REMINDER, '取消提醒失败')
    }
  }

  /**
   * 取消所有提醒
   */
  static async cancelAllReminders(): Promise<Result<void>> {
    try {
      await reminderAgentManager.cancelAllReminders()
      Logger.info('All reminders cancelled')
      return success(undefined)
    } catch (error) {
      Logger.error('Failed to cancel all reminders', JSON.stringify(error))
      return fail(Constants.ERROR_CODE_REMINDER, '取消所有提醒失败')
    }
  }

  /**
   * 创建离开后返回提醒（5分钟）
   */
  static async createReturnReminder(): Promise<Result<number>> {
    const delaySeconds = Math.floor(Constants.RETURN_REMINDER_DELAY / 1000)
    return ReminderService.createTimerReminder(
      '专注会话已暂停',
      '点击继续您的专注',
      delaySeconds
    )
  }

  /**
   * 创建休息结束提醒
   */
  static async createBreakEndReminder(durationMs: number): Promise<Result<number>> {
    const delaySeconds = Math.floor(durationMs / 1000)
    return ReminderService.createTimerReminder(
      '休息时间结束',
      '准备继续专注吧',
      delaySeconds
    )
  }
}
