/**
 * 日志工具
 */

import hilog from '@ohos.hilog'

const DOMAIN = 0x0001
const TAG = 'FocusApp'

export class Logger {
  static debug(message: string, ...args: Array<string | number | boolean>): void {
    hilog.debug(DOMAIN, TAG, `[DEBUG] ${message}`, ...args)
  }

  static info(message: string, ...args: Array<string | number | boolean>): void {
    hilog.info(DOMAIN, TAG, `[INFO] ${message}`, ...args)
  }

  static warn(message: string, ...args: Array<string | number | boolean>): void {
    hilog.warn(DOMAIN, TAG, `[WARN] ${message}`, ...args)
  }

  static error(message: string, ...args: Array<string | number | boolean>): void {
    hilog.error(DOMAIN, TAG, `[ERROR] ${message}`, ...args)
  }

  static fatal(message: string, ...args: Array<string | number | boolean>): void {
    hilog.fatal(DOMAIN, TAG, `[FATAL] ${message}`, ...args)
  }
}
