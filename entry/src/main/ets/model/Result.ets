/**
 * Result 模式：统一错误处理
 * 用于 Data/Service 层异步操作的返回类型
 */

// Keep a discriminated shape but add optional fields to both sides so code/message/data
// can be accessed safely even when callers skip explicit narrowing.
export interface ResultSuccess<T> {
  ok: true
  data: T
  code?: string
  message?: string
}

export interface ResultFailure<T = never> {
  ok: false
  data?: T
  code: string
  message: string
}

export type Result<T> = ResultSuccess<T> | ResultFailure<T>

export function success<T>(data: T): ResultSuccess<T> {
  return { ok: true, data: data }
}

export function fail<T = never>(code: string, message: string): ResultFailure<T> {
  return { ok: false, code: code, message: message }
}

export function isSuccess<T>(result: Result<T>): boolean {
  return result.ok === true
}

export function isFailure<T>(result: Result<T>): boolean {
  return result.ok === false
}
