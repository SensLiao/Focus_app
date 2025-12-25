export interface Task {
  id: string;
  name: string;
  description: string;
  createdAt: Date;
  totalFocusTime: number; // in seconds
  timerState?: {
    isRunning: boolean;
    isResting: boolean;
    seconds: number;
    restSeconds: number;
    restCount: number;
    currentRestTimer: number;
    totalFocusTime: number;
    focusSessions: Array<{
      completedDate: Date;
      focusDuration: number;
      restDuration: number;
    }>;
    currentSessionStart: number;
    currentSessionRestStart: number;
    currentSessionRestTime: number;
  };
}

export interface CompletedTask extends Task {
  completedAt: Date;
  duration: number; // in seconds
}