/**
 * 应用生命周期服务
 * 统一分发前后台切换事件
 */

import { Logger } from '../common/logger'

type LifecycleEvent = 'foreground' | 'background' | 'destroy'
type LifecycleListener = (event: LifecycleEvent) => void

export class AppLifecycleService {
  private static listeners: LifecycleListener[] = []

  /**
   * 注册生命周期监听器
   */
  static register(listener: LifecycleListener): void {
    AppLifecycleService.listeners.push(listener)
    Logger.info('Lifecycle listener registered')
  }

  /**
   * 注销生命周期监听器
   */
  static unregister(listener: LifecycleListener): void {
    const index = AppLifecycleService.listeners.indexOf(listener)
    if (index > -1) {
      AppLifecycleService.listeners.splice(index, 1)
      Logger.info('Lifecycle listener unregistered')
    }
  }

  /**
   * 发送生命周期事件
   */
  static emit(event: LifecycleEvent): void {
    Logger.info(`Lifecycle event: ${event}`)
    AppLifecycleService.listeners.forEach(listener => {
      try {
        listener(event)
      } catch (error) {
        Logger.error('Error in lifecycle listener', JSON.stringify(error))
      }
    })
  }

  /**
   * 清空所有监听器
   */
  static clear(): void {
    AppLifecycleService.listeners = []
    Logger.info('All lifecycle listeners cleared')
  }
}
