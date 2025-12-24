/**
 * Notification service for background warnings.
 */

import notificationManager from '@ohos.notificationManager';
import abilityWantAgent from '@ohos.app.ability.wantAgent';
import type Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { Logger } from '../common/logger';

const BACKGROUND_NOTIFICATION_ID: number = 1001;
const BREAK_END_NOTIFICATION_ID: number = 1002;
const REST_INTERVAL_NOTIFICATION_ID: number = 1003;
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

  static async isEnabled(): Promise<boolean> {
    try {
      return await notificationManager.isNotificationEnabled();
    } catch (error) {
      Logger.warn('Failed to read notification permission status', error.toString());
      return true;
    }
  }

  static async requestEnable(context: common.UIAbilityContext): Promise<void> {
    try {
      await notificationManager.requestEnableNotification(context);
    } catch (error) {
      Logger.warn('Notification permission request failed', error.toString());
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

  static async publishBreakEnd(): Promise<void> {
    try {
      const want = NotificationService.buildEntryWant();
      const agentInfo: abilityWantAgent.WantAgentInfo = {
        wants: [want],
        actionType: abilityWantAgent.OperationType.START_ABILITY,
        requestCode: 0
      };
      const agent = await abilityWantAgent.getWantAgent(agentInfo);
      const request: notificationManager.NotificationRequest = {
        id: BREAK_END_NOTIFICATION_ID,
        notificationSlotType: BACKGROUND_NOTIFICATION_SLOT,
        wantAgent: agent,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Rest finished',
            text: 'Tap to return to your focus session.'
          }
        }
      };
      await notificationManager.publish(request);
      Logger.info('Break end notification published');
    } catch (error) {
      Logger.error('Failed to publish break end notification', error.toString());
    }
  }

  static async cancelBreakEnd(): Promise<void> {
    try {
      await notificationManager.cancel(BREAK_END_NOTIFICATION_ID);
      Logger.info('Break end notification cancelled');
    } catch (error) {
      Logger.error('Failed to cancel break end notification', error.toString());
    }
  }

  static async publishRestInterval(): Promise<void> {
    try {
      const want = NotificationService.buildEntryWant();
      const agentInfo: abilityWantAgent.WantAgentInfo = {
        wants: [want],
        actionType: abilityWantAgent.OperationType.START_ABILITY,
        requestCode: 0
      };
      const agent = await abilityWantAgent.getWantAgent(agentInfo);
      const request: notificationManager.NotificationRequest = {
        id: REST_INTERVAL_NOTIFICATION_ID,
        notificationSlotType: BACKGROUND_NOTIFICATION_SLOT,
        wantAgent: agent,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Rest time',
            text: 'Tap to return to your focus session.'
          }
        }
      };
      await notificationManager.publish(request);
      Logger.info('Rest interval notification published');
    } catch (error) {
      Logger.error('Failed to publish rest interval notification', error.toString());
    }
  }

  static async cancelRestInterval(): Promise<void> {
    try {
      await notificationManager.cancel(REST_INTERVAL_NOTIFICATION_ID);
      Logger.info('Rest interval notification cancelled');
    } catch (error) {
      Logger.error('Failed to cancel rest interval notification', error.toString());
    }
  }

  static async playRestIntervalSound(): Promise<void> {
    try {
      const request: notificationManager.NotificationRequest = {
        id: REST_INTERVAL_NOTIFICATION_ID,
        notificationSlotType: BACKGROUND_NOTIFICATION_SLOT,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: 'Rest time',
            text: 'Rest interval ended.'
          }
        }
      };
      await notificationManager.publish(request);
      setTimeout(() => {
        void NotificationService.cancelRestInterval();
      }, 1500);
      Logger.info('Rest interval sound triggered');
    } catch (error) {
      Logger.error('Failed to trigger rest interval sound', error.toString());
    }
  }

  private static buildEntryWant(): Want {
    return {
      bundleName: 'com.example.testing_app',
      abilityName: 'EntryAbility'
    };
  }
}
