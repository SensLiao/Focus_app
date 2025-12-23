import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppLifecycleService } from '../services/AppLifecycleService';
import { FocusStore } from '../store/focusStore';
import { SessionStatus } from '../model/SessionStatus';
import { Logger } from '../common/logger';
import { NotificationService } from '../services/NotificationService';
import { SettingsService } from '../services/SettingsService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    Logger.info('Ability onCreate');
    void SettingsService.init(this.context);
    void NotificationService.init(this.context);

    // 注册生命周期监听
    AppLifecycleService.register((event) => {
      if (event === 'background') {
        FocusStore.handleBackground();
      } else if (event === 'foreground') {
        FocusStore.handleForeground();
      }
    });
  }

  onDestroy(): void {
    Logger.info('Ability onDestroy');
    void FocusStore.handleAppExit();
    AppLifecycleService.emit('destroy');
    AppLifecycleService.clear();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    Logger.info('Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      Logger.info('Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    Logger.info('Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    Logger.info('Ability onForeground');
    AppLifecycleService.emit('foreground');
    NotificationService.cancelBackgroundExit();
  }

  onBackground(): void {
    // Ability has back to background
    Logger.info('Ability onBackground');
    AppLifecycleService.emit('background');
    const focusState = FocusStore.getState();
    if (
      SettingsService.isNotificationsEnabled()
      && !focusState.isBreaking
      && focusState.currentSession?.status === SessionStatus.RUNNING
    ) {
      NotificationService.publishBackgroundExit();
    }
  }
}
