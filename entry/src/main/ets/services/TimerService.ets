/**
 * 计时器服务
 * 提供前台计时能力
 */

import { Logger } from '../common/logger'
import { Constants } from '../common/constants'

type TimerCallback = (elapsedMs: number) => void

export class TimerService {
  private static intervalId: number = -1
  private static startTime: number = 0
  private static pausedTime: number = 0
  private static isRunning: boolean = false
  private static callback: TimerCallback | null = null

  /**
   * 启动计时器
   */
  static start(callback: TimerCallback): void {
    if (TimerService.isRunning) {
      Logger.warn('Timer already running')
      return
    }

    TimerService.callback = callback
    TimerService.startTime = Date.now() - TimerService.pausedTime
    TimerService.isRunning = true

    TimerService.intervalId = setInterval(() => {
      const elapsedMs = Date.now() - TimerService.startTime
      if (TimerService.callback) {
        TimerService.callback(elapsedMs)
      }
    }, Constants.TIMER_TICK_INTERVAL)

    Logger.info('Timer started')
  }

  /**
   * 暂停计时器
   */
  static pause(): number {
    if (!TimerService.isRunning) {
      Logger.warn('Timer not running')
      return TimerService.pausedTime
    }

    TimerService.isRunning = false
    clearInterval(TimerService.intervalId)
    TimerService.pausedTime = Date.now() - TimerService.startTime

    Logger.info(`Timer paused at ${TimerService.pausedTime}ms`)
    return TimerService.pausedTime
  }

  /**
   * 恢复计时器
   */
  static resume(callback: TimerCallback): void {
    if (TimerService.isRunning) {
      Logger.warn('Timer already running')
      return
    }

    TimerService.start(callback)
    Logger.info('Timer resumed')
  }

  /**
   * 停止并重置计时器
   */
  static stop(): number {
    const elapsedMs = TimerService.isRunning
      ? Date.now() - TimerService.startTime
      : TimerService.pausedTime

    if (TimerService.isRunning) {
      clearInterval(TimerService.intervalId)
    }

    TimerService.isRunning = false
    TimerService.startTime = 0
    TimerService.pausedTime = 0
    TimerService.callback = null

    Logger.info(`Timer stopped at ${elapsedMs}ms`)
    return elapsedMs
  }

  /**
   * 获取当前已流逝时间
   */
  static getElapsed(): number {
    return TimerService.isRunning
      ? Date.now() - TimerService.startTime
      : TimerService.pausedTime
  }

  /**
   * 检查是否正在运行
   */
  static isActive(): boolean {
    return TimerService.isRunning
  }
}
