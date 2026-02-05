/**
 * System settings navigation helpers.
 *
 * Goal: avoid "暂无打开方式" by trying multiple Wants across HarmonyOS/OpenHarmony
 * variants, and providing reliable fallback behavior.
 */

import common from '@ohos.app.ability.common'
import Want from '@ohos.app.ability.Want'
import bundle from '@ohos.bundle'
import type { BusinessError } from '@ohos.base'
import { Logger } from '../common/logger'
import { AppLifecycleService } from './AppLifecycleService'

export interface OpenOptions {
  verifyBackground?: boolean
  timeoutMs?: number
}

interface PreflightHandled {
  kind: 'handled'
  count: number
  wantJson: string
  abilitiesJson: string
}

interface PreflightUnhandled {
  kind: 'unhandled'
  wantJson: string
}

interface PreflightUnknown {
  kind: 'unknown'
  wantJson: string
  errorJson: string
}

type PreflightResult = PreflightHandled | PreflightUnhandled | PreflightUnknown

export class SettingsNavigator {
  static async openAppSettings(context: common.UIAbilityContext, options?: OpenOptions): Promise<boolean> {
    const bundleName = context.abilityInfo.bundleName
    const wants = SettingsNavigator.buildAppSettingsWants(bundleName)

    for (let i = 0; i < wants.length; i++) {
      const want = wants[i]
      const ok = await SettingsNavigator.tryStartAbility(context, want, options)
      if (ok) {
        return true
      }
    }
    return false
  }

  static async openSystemSettingsHome(context: common.UIAbilityContext): Promise<boolean> {
    const wants = SettingsNavigator.buildSystemSettingsHomeWants()
    for (let i = 0; i < wants.length; i++) {
      const ok = await SettingsNavigator.tryStartAbility(context, wants[i])
      if (ok) {
        return true
      }
    }
    return false
  }

  static async openAppSettingsWithFallback(context: common.UIAbilityContext, options?: OpenOptions): Promise<boolean> {
    const silentOptions: OpenOptions = {
      verifyBackground: options?.verifyBackground,
      timeoutMs: options?.timeoutMs
    }
    const ok = await SettingsNavigator.openAppSettings(context, silentOptions)
    if (ok) {
      return true
    }
    return await SettingsNavigator.openSystemSettingsHome(context)
  }

  private static buildAppSettingsWants(bundleName: string): Want[] {
    // Common HarmonyOS/OpenHarmony pattern: app info page.
    const appInfoWant: Want = {
      action: 'action.settings.app.info',
      uri: 'application_info_entry',
      parameters: { pushParams: bundleName }
    }

    // Some system variants may omit/ignore uri/parameters; keep a simpler form.
    const appInfoNoUri: Want = {
      action: 'action.settings.app.info',
      parameters: { pushParams: bundleName }
    }

    // Alternate parameter key used in some variants.
    const appInfoAltParam: Want = {
      action: 'action.settings.app.info',
      parameters: { bundleName: bundleName }
    }

    // Android-style app details settings (may work on some distributions).
    const androidDetails: Want = {
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      uri: `package:${bundleName}`
    }
    const ohosDetails: Want = {
      action: 'ohos.settings.APPLICATION_DETAILS_SETTINGS',
      uri: `package:${bundleName}`
    }

    return [appInfoWant, appInfoNoUri, appInfoAltParam, ohosDetails, androidDetails]
  }

  private static buildSystemSettingsHomeWants(): Want[] {
    const huawei: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility'
    }
    const openHarmony: Want = {
      bundleName: 'com.ohos.settings',
      abilityName: 'com.ohos.settings.MainAbility'
    }
    const androidSettings: Want = {
      bundleName: 'com.android.settings',
      abilityName: 'com.android.settings.Settings'
    }
    return [huawei, openHarmony, androidSettings]
  }

  private static async tryStartAbility(
    context: common.UIAbilityContext,
    want: Want,
    options?: OpenOptions
  ): Promise<boolean> {
    const preflight: PreflightResult = await SettingsNavigator.preflightQueryAbilityByWant(want)
    if (preflight.kind === 'handled') {
      Logger.info(`[SettingsNavigator] preflight: handled count=${preflight.count} want=${preflight.wantJson} abilities=${preflight.abilitiesJson}`)
    } else if (preflight.kind === 'unhandled') {
      // Don't hard-block startAbility based on preflight, because:
      // - queryAbilityByWant can be permission-limited or incomplete on some devices
      // - some implicit routing may still succeed even if query returns empty
      Logger.warn(`[SettingsNavigator] preflight: unhandled (will still try startAbility) want=${preflight.wantJson}`)
    } else if (preflight.kind === 'unknown') {
      Logger.warn(`[SettingsNavigator] preflight: unknown want=${preflight.wantJson} err=${preflight.errorJson}`)
    }

    if (options?.verifyBackground) {
      const didBackground = await SettingsNavigator.tryStartWithLifecycle(context, want, options?.timeoutMs ?? 1200)
      if (!didBackground) {
        Logger.warn('Settings jump did not background app', JSON.stringify(want))
      }
      return didBackground
    }

    return context
      .startAbility(want)
      .then((): boolean => true)
      .catch((error: BusinessError): boolean => {
        Logger.warn(
          `[SettingsNavigator] startAbility failed code=${error.code} message=${error.message} want=${JSON.stringify(want)} error=${JSON.stringify(error)}`
        )
        return false
      })
  }

  private static async preflightQueryAbilityByWant(want: Want): Promise<PreflightResult> {
    const wantJson = JSON.stringify(want)
    return bundle
      .queryAbilityByWant(want, 0)
      .then((abilities): PreflightResult => {
        const count = abilities.length
        if (count <= 0) {
          const res: PreflightUnhandled = { kind: 'unhandled', wantJson }
          return res
        }
        const summarized = abilities.slice(0, 6).map((a): string => {
          return `${a.bundleName}/${a.name}`
        })
        const res: PreflightHandled = {
          kind: 'handled',
          count,
          wantJson,
          abilitiesJson: JSON.stringify(summarized)
        }
        return res
      })
      .catch((error: BusinessError): PreflightResult => {
        const res: PreflightUnknown = { kind: 'unknown', wantJson, errorJson: JSON.stringify(error) }
        return res
      })
  }

  private static async tryStartWithLifecycle(
    context: common.UIAbilityContext,
    want: Want,
    timeoutMs: number
  ): Promise<boolean> {
    return new Promise<boolean>((resolve) => {
      let done = false
      let listener: (event: 'foreground' | 'background' | 'destroy') => void

      const finish = (ok: boolean) => {
        if (done) return
        done = true
        AppLifecycleService.unregister(listener)
        resolve(ok)
      }
      listener = (event: 'foreground' | 'background' | 'destroy'): void => {
        if (event === 'background') {
          finish(true)
        }
      }

      AppLifecycleService.register(listener)
      context.startAbility(want).then(() => {
        setTimeout((): void => {
          finish(false)
        }, timeoutMs)
      }).catch((): void => {
        finish(false)
      })
    })
  }
}
