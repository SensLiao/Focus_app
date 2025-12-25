/**
 * 设置服务
 * 使用 Preferences 持久化用户设置
 */

import dataPreferences from '@ohos.data.preferences'
import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

export interface AppSettings {
  notificationsEnabled: boolean
  restEnabled: boolean
  defaultRestDuration: number      // 默认休息时长（分钟）
  defaultRestInterval: number      // 默认休息间隔（分钟）
  defaultFocusDuration: number     // 默认专注时长（分钟，倒计时用）
  autoExtendBreak: boolean         // 是否自动延长休息
}

const DEFAULT_SETTINGS: AppSettings = {
  notificationsEnabled: true,
  restEnabled: true,
  defaultRestDuration: 5,
  defaultRestInterval: 25,
  defaultFocusDuration: 25,
  autoExtendBreak: false
}

const PREFERENCES_NAME = 'focus_app_settings'
const KEY_NOTIFICATIONS = 'notifications_enabled'
const KEY_REST_ENABLED = 'rest_enabled'
const KEY_REST_DURATION = 'default_rest_duration'
const KEY_REST_INTERVAL = 'default_rest_interval'
const KEY_FOCUS_DURATION = 'default_focus_duration'
const KEY_AUTO_EXTEND_BREAK = 'auto_extend_break'

export class SettingsService {
  private static preferences: dataPreferences.Preferences | null = null
  private static settings: AppSettings = {
    notificationsEnabled: DEFAULT_SETTINGS.notificationsEnabled,
    restEnabled: DEFAULT_SETTINGS.restEnabled,
    defaultRestDuration: DEFAULT_SETTINGS.defaultRestDuration,
    defaultRestInterval: DEFAULT_SETTINGS.defaultRestInterval,
    defaultFocusDuration: DEFAULT_SETTINGS.defaultFocusDuration,
    autoExtendBreak: DEFAULT_SETTINGS.autoExtendBreak
  }

  /**
   * 初始化设置服务
   */
  static async init(context: Context): Promise<void> {
    try {
      SettingsService.preferences = await dataPreferences.getPreferences(context, PREFERENCES_NAME)
      await SettingsService.loadSettings()
      Logger.info('SettingsService initialized')
    } catch (error) {
      Logger.error('Failed to initialize SettingsService', error.toString())
    }
  }

  /**
   * 加载设置
   */
  private static async loadSettings(): Promise<void> {
    if (!SettingsService.preferences) return

    try {
      SettingsService.settings.notificationsEnabled = 
        await SettingsService.preferences.get(KEY_NOTIFICATIONS, DEFAULT_SETTINGS.notificationsEnabled) as boolean
      SettingsService.settings.restEnabled =
        await SettingsService.preferences.get(KEY_REST_ENABLED, DEFAULT_SETTINGS.restEnabled) as boolean
      SettingsService.settings.defaultRestDuration = 
        await SettingsService.preferences.get(KEY_REST_DURATION, DEFAULT_SETTINGS.defaultRestDuration) as number
      SettingsService.settings.defaultRestInterval = 
        await SettingsService.preferences.get(KEY_REST_INTERVAL, DEFAULT_SETTINGS.defaultRestInterval) as number
      SettingsService.settings.defaultFocusDuration = 
        await SettingsService.preferences.get(KEY_FOCUS_DURATION, DEFAULT_SETTINGS.defaultFocusDuration) as number
      SettingsService.settings.autoExtendBreak = 
        await SettingsService.preferences.get(KEY_AUTO_EXTEND_BREAK, DEFAULT_SETTINGS.autoExtendBreak) as boolean
      
      Logger.info('Settings loaded')
    } catch (error) {
      Logger.error('Failed to load settings', error.toString())
    }
  }

  /**
   * 获取所有设置
   */
  static getSettings(): AppSettings {
    return {
      notificationsEnabled: SettingsService.settings.notificationsEnabled,
      restEnabled: SettingsService.settings.restEnabled,
      defaultRestDuration: SettingsService.settings.defaultRestDuration,
      defaultRestInterval: SettingsService.settings.defaultRestInterval,
      defaultFocusDuration: SettingsService.settings.defaultFocusDuration,
      autoExtendBreak: SettingsService.settings.autoExtendBreak
    }
  }

  /**
   * 获取通知开关状态
   */
  static isNotificationsEnabled(): boolean {
    return SettingsService.settings.notificationsEnabled
  }

  /**
   * 设置通知开关
   */
  static async setNotificationsEnabled(enabled: boolean): Promise<void> {
    if (!SettingsService.preferences) return
    
    try {
      await SettingsService.preferences.put(KEY_NOTIFICATIONS, enabled)
      await SettingsService.preferences.flush()
      SettingsService.settings.notificationsEnabled = enabled
      Logger.info(`Notifications ${enabled ? 'enabled' : 'disabled'}`)
    } catch (error) {
      Logger.error('Failed to save notifications setting', error.toString())
    }
  }

  static isRestEnabled(): boolean {
    return SettingsService.settings.restEnabled
  }

  static async setRestEnabled(enabled: boolean): Promise<void> {
    if (!SettingsService.preferences) return
    
    try {
      await SettingsService.preferences.put(KEY_REST_ENABLED, enabled)
      await SettingsService.preferences.flush()
      SettingsService.settings.restEnabled = enabled
      Logger.info(`Rest ${enabled ? 'enabled' : 'disabled'}`)
    } catch (error) {
      Logger.error('Failed to save rest enabled setting', error.toString())
    }
  }

  /**
   * 获取默认休息时长（分钟）
   */
  static getDefaultRestDuration(): number {
    return SettingsService.settings.defaultRestDuration
  }

  /**
   * 设置默认休息时长（分钟）
   */
  static async setDefaultRestDuration(minutes: number): Promise<void> {
    if (!SettingsService.preferences) return
    
    try {
      await SettingsService.preferences.put(KEY_REST_DURATION, minutes)
      await SettingsService.preferences.flush()
      SettingsService.settings.defaultRestDuration = minutes
      Logger.info(`Default rest duration set to ${minutes} minutes`)
    } catch (error) {
      Logger.error('Failed to save rest duration setting', error.toString())
    }
  }

  /**
   * 获取默认休息间隔（分钟）
   */
  static getDefaultRestInterval(): number {
    return SettingsService.settings.defaultRestInterval
  }

  /**
   * 设置默认休息间隔（分钟）
   */
  static async setDefaultRestInterval(minutes: number): Promise<void> {
    if (!SettingsService.preferences) return
    
    try {
      await SettingsService.preferences.put(KEY_REST_INTERVAL, minutes)
      await SettingsService.preferences.flush()
      SettingsService.settings.defaultRestInterval = minutes
      Logger.info(`Default rest interval set to ${minutes} minutes`)
    } catch (error) {
      Logger.error('Failed to save rest interval setting', error.toString())
    }
  }

  /**
   * 获取默认专注时长（分钟）
   */
  static getDefaultFocusDuration(): number {
    return SettingsService.settings.defaultFocusDuration
  }

  /**
   * 设置默认专注时长（分钟）
   */
  static async setDefaultFocusDuration(minutes: number): Promise<void> {
    if (!SettingsService.preferences) return
    
    try {
      await SettingsService.preferences.put(KEY_FOCUS_DURATION, minutes)
      await SettingsService.preferences.flush()
      SettingsService.settings.defaultFocusDuration = minutes
      Logger.info(`Default focus duration set to ${minutes} minutes`)
    } catch (error) {
      Logger.error('Failed to save focus duration setting', error.toString())
    }
  }

  /**
   * 获取是否自动延长休息
   */
  static isAutoExtendBreakEnabled(): boolean {
    return SettingsService.settings.autoExtendBreak
  }

  /**
   * 设置是否自动延长休息
   */
  static async setAutoExtendBreak(enabled: boolean): Promise<void> {
    if (!SettingsService.preferences) return
    
    try {
      await SettingsService.preferences.put(KEY_AUTO_EXTEND_BREAK, enabled)
      await SettingsService.preferences.flush()
      SettingsService.settings.autoExtendBreak = enabled
      Logger.info(`Auto extend break ${enabled ? 'enabled' : 'disabled'}`)
    } catch (error) {
      Logger.error('Failed to save auto extend break setting', error.toString())
    }
  }

  /**
   * 获取默认休息时长（毫秒）
   */
  static getDefaultRestDurationMs(): number {
    return SettingsService.settings.defaultRestDuration * 60 * 1000
  }

  /**
   * 获取默认休息间隔（毫秒）
   */
  static getDefaultRestIntervalMs(): number {
    return SettingsService.settings.defaultRestInterval * 60 * 1000
  }

  /**
   * 获取默认专注时长（毫秒）
   */
  static getDefaultFocusDurationMs(): number {
    return SettingsService.settings.defaultFocusDuration * 60 * 1000
  }
}
