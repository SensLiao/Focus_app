import { CompletedTask } from '../types';
import { useState } from 'react';

interface SettingsPageProps {
  completedTasks: CompletedTask[];
}

export function SettingsPage({ completedTasks }: SettingsPageProps) {
  const [notificationsEnabled, setNotificationsEnabled] = useState(false);
  const [defaultRestDuration, setDefaultRestDuration] = useState(5);
  const [restIntervalHours, setRestIntervalHours] = useState(0);
  const [restIntervalMinutes, setRestIntervalMinutes] = useState(30);

  const handleRestDurationChange = (value: string) => {
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 0 && numValue <= 30) {
      setDefaultRestDuration(numValue);
    }
  };

  const handleRestIntervalHoursChange = (value: string) => {
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 0 && numValue <= 23) {
      setRestIntervalHours(numValue);
    } else if (value === '') {
      setRestIntervalHours(0);
    }
  };

  const handleRestIntervalMinutesChange = (value: string) => {
    const numValue = parseInt(value);
    if (!isNaN(numValue) && numValue >= 0 && numValue <= 59) {
      setRestIntervalMinutes(numValue);
    } else if (value === '') {
      setRestIntervalMinutes(0);
    }
  };

  return (
    <div className="flex flex-col h-full bg-gray-50">
      <div className="p-4 bg-white border-b">
        <h1 className="text-2xl">Settings</h1>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        <div className="bg-white rounded-xl p-5 shadow-sm">
          <div className="space-y-1">
            <div className="flex justify-between items-center py-3.5 border-b border-gray-100">
              <span className="text-gray-600">Notifications</span>
              <label className="relative inline-block w-14 h-8">
                <input 
                  type="checkbox" 
                  className="peer sr-only" 
                  checked={notificationsEnabled}
                  onChange={(e) => setNotificationsEnabled(e.target.checked)}
                />
                <span className="absolute cursor-pointer inset-0 bg-gray-300 rounded-full transition peer-checked:bg-blue-600"></span>
                <span className="absolute cursor-pointer left-1 top-1 w-6 h-6 bg-white rounded-full transition peer-checked:translate-x-6"></span>
              </label>
            </div>
            <div className="flex justify-between items-center py-3.5">
              <span className="text-gray-600">Default Rest Duration (min)</span>
              <input
                type="number"
                min="0"
                max="30"
                value={defaultRestDuration}
                onChange={(e) => handleRestDurationChange(e.target.value)}
                className="w-20 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent text-center"
              />
            </div>
            <div className="flex justify-between items-center py-3.5">
              <span className="text-gray-600">Rest Interval (hours:minutes)</span>
              <div className="flex">
                <input
                  type="number"
                  min="0"
                  max="23"
                  value={restIntervalHours}
                  onChange={(e) => handleRestIntervalHoursChange(e.target.value)}
                  className="w-20 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent text-center"
                />
                <span className="mx-2">:</span>
                <input
                  type="number"
                  min="0"
                  max="59"
                  value={restIntervalMinutes}
                  onChange={(e) => handleRestIntervalMinutesChange(e.target.value)}
                  className="w-20 px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent text-center"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}