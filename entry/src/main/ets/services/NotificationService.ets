/**
 * Notification service for background warnings.
 */

import notificationManager from '@ohos.notificationManager';
import abilityWantAgent from '@ohos.app.ability.wantAgent';
import type Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/logger';

const BACKGROUND_NOTIFICATION_ID: number = 1001;
const BACKGROUND_NOTIFICATION_SLOT: notificationManager.SlotType = notificationManager.SlotType.SERVICE_INFORMATION;

export class NotificationService {
  private static initialized: boolean = false;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (NotificationService.initialized) {
      return;
    }
    NotificationService.initialized = true;
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      if (!enabled) {
        await notificationManager.requestEnableNotification(context);
      }
    } catch (error) {
      Logger.warn('Notification permission request failed', error.toString());
    }
    try {
      await notificationManager.addSlot(BACKGROUND_NOTIFICATION_SLOT);
    } catch (error) {
      Logger.warn('Notification slot setup failed', error.toString());
    }
  }

  static async publishBackgroundExit(): Promise<void> {
    try {
      const want = NotificationService.buildEntryWant();
      const agentInfo: abilityWantAgent.WantAgentInfo = {
        wants: [want],
        actionType: abilityWantAgent.OperationType.START_ABILITY,
        requestCode: 0
      };
      const agent = await abilityWantAgent.getWantAgent(agentInfo);
      const request: notificationManager.NotificationRequest = {
        id: BACKGROUND_NOTIFICATION_ID,
        notificationSlotType: BACKGROUND_NOTIFICATION_SLOT,
        wantAgent: agent,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Focus paused',
            text: 'You left the app. Your session is paused.'
          }
        }
      };
      await notificationManager.publish(request);
      Logger.info('Background exit notification published');
    } catch (error) {
      Logger.error('Failed to publish background notification', error.toString());
    }
  }

  static async cancelBackgroundExit(): Promise<void> {
    try {
      await notificationManager.cancel(BACKGROUND_NOTIFICATION_ID);
      Logger.info('Background exit notification cancelled');
    } catch (error) {
      Logger.error('Failed to cancel background notification', error.toString());
    }
  }

  private static buildEntryWant(): Want {
    return {
      bundleName: 'com.example.testing_app',
      abilityName: 'EntryAbility'
    };
  }
}
