import { useState, useEffect } from 'react';
import { ArrowLeft, Pause, Coffee, CheckCircle, X } from 'lucide-react';
import { Task } from '../types';

interface FocusSession {
  completedDate: Date;
  focusDuration: number; // seconds
  restDuration: number; // seconds
}

interface TimerPageProps {
  task: Task | null;
  onComplete: (duration: number) => void;
  onBack: () => void;
  onUpdateTaskState: (taskId: string, state: any) => void;
  allTasks: Task[];
  onNavigateToTask?: (task: Task) => void;
}

export function TimerPage({ task, onComplete, onBack, onUpdateTaskState, allTasks, onNavigateToTask }: TimerPageProps) {
  const [seconds, setSeconds] = useState(0);
  const [isRunning, setIsRunning] = useState(false);
  const [isResting, setIsResting] = useState(false);
  const [isAnimating, setIsAnimating] = useState(false);
  const [currentRestTimer, setCurrentRestTimer] = useState(0);
  const [restSeconds, setRestSeconds] = useState(0);
  const [restCount, setRestCount] = useState(0);
  const [focusSessions, setFocusSessions] = useState<FocusSession[]>([]);
  const [currentSessionStart, setCurrentSessionStart] = useState(0);
  const [currentSessionRestStart, setCurrentSessionRestStart] = useState(0);
  const [currentSessionRestTime, setCurrentSessionRestTime] = useState(0);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [totalFocusTime, setTotalFocusTime] = useState(0);
  const [showPauseWarning, setShowPauseWarning] = useState(false);
  const [neverShowPauseWarning, setNeverShowPauseWarning] = useState(false);
  const [showLeaveWarning, setShowLeaveWarning] = useState(false);
  const [showActiveTaskWarning, setShowActiveTaskWarning] = useState(false);
  const [isCountdownMode, setIsCountdownMode] = useState(false);
  const [countdownDuration, setCountdownDuration] = useState(25); // Default 25 minutes
  const [countdownSeconds, setCountdownSeconds] = useState(0);

  // Restore state when component mounts
  useEffect(() => {
    if (task?.timerState) {
      const state = task.timerState;
      setSeconds(state.seconds);
      setIsRunning(state.isRunning);
      setIsResting(state.isResting);
      setRestSeconds(state.restSeconds);
      setRestCount(state.restCount);
      setCurrentRestTimer(state.currentRestTimer);
      setTotalFocusTime(state.totalFocusTime);
      setFocusSessions(state.focusSessions);
      setCurrentSessionStart(state.currentSessionStart);
      setCurrentSessionRestStart(state.currentSessionRestStart);
      setCurrentSessionRestTime(state.currentSessionRestTime);
      setIsCountdownMode(state.isCountdownMode ?? false);
      setCountdownDuration(state.countdownDuration ?? 25);
      setCountdownSeconds(state.countdownSeconds ?? 0);
    }
  }, [task?.id]);

  // Save state whenever it changes
  useEffect(() => {
    if (task) {
      onUpdateTaskState(task.id, {
        isRunning,
        isResting,
        seconds,
        restSeconds,
        restCount,
        currentRestTimer,
        totalFocusTime,
        focusSessions,
        currentSessionStart,
        currentSessionRestStart,
        currentSessionRestTime,
        isCountdownMode,
        countdownDuration,
        countdownSeconds,
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isRunning, isResting, seconds, restSeconds, restCount, currentRestTimer, totalFocusTime, focusSessions, currentSessionStart, currentSessionRestStart, currentSessionRestTime, isCountdownMode, countdownDuration, countdownSeconds]);

  useEffect(() => {
    let interval: number | undefined;
    if (isRunning) {
      interval = window.setInterval(() => {
        if (isResting) {
          setCurrentRestTimer((r) => r + 1);
        } else {
          if (isCountdownMode) {
            // Countdown mode: decrease countdown seconds
            setCountdownSeconds((c) => {
              if (c <= 1) {
                // Countdown reached zero
                setIsRunning(false);
                setIsResting(false);
                return 0;
              }
              return c - 1;
            });
          }
          // Always track actual time spent
          setSeconds((s) => s + 1);
          setTotalFocusTime((t) => t + 1);
        }
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [isRunning, isResting, isCountdownMode]);

  const formatTime = (totalSeconds: number) => {
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const secs = totalSeconds % 60;
    
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  };

  const formatMinutes = (totalSeconds: number) => {
    const minutes = Math.floor(totalSeconds / 60);
    return `${minutes} min`;
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { 
      month: 'short', 
      day: 'numeric', 
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    });
  };

  const handlePause = () => {
    if (!neverShowPauseWarning && !isResting && isRunning) {
      setShowPauseWarning(true);
    } else {
      performPause();
    }
  };

  const performPause = () => {
    if (isRunning) {
      // Reset timer
      setSeconds(0);
      setCurrentSessionStart(0);
      setCurrentSessionRestTime(0);
    }
    // Stop the timer and exit rest mode
    setIsRunning(false);
    setIsResting(false);
  };

  const handleRest = () => {
    const wasResting = isResting;
    
    if (!wasResting) {
      // Starting rest mode - trigger fade out first
      setIsAnimating(true);
      
      // After fade out animation completes (300ms), switch to rest mode
      setTimeout(() => {
        setIsResting(true);
        setCurrentRestTimer(0);
        setRestCount((c) => c + 1);
        setCurrentSessionRestStart(restSeconds);
        setIsAnimating(false);
      }, 300);
    } else {
      // Ending rest mode - trigger fade out first
      setIsAnimating(true);
      
      // After fade out animation completes (300ms), switch back to focus mode
      setTimeout(() => {
        setRestSeconds((prev) => prev + currentRestTimer);
        setCurrentSessionRestTime((prev) => prev + currentRestTimer);
        setCurrentRestTimer(0);
        setIsResting(false);
        setIsAnimating(false);
      }, 300);
    }
  };

  const handleComplete = () => {
    onComplete(seconds);
  };

  const handleBack = () => {
    if (isRunning && !isResting) {
      setShowLeaveWarning(true);
    } else {
      onBack();
    }
  };

  const handleFiveMinuteBreak = () => {
    setShowLeaveWarning(false);
    // Start a 5-minute rest
    setIsAnimating(true);
    
    setTimeout(() => {
      setIsResting(true);
      setCurrentRestTimer(0);
      setRestCount((c) => c + 1);
      setCurrentSessionRestStart(restSeconds);
      setIsAnimating(false);
    }, 300);
  };

  return (
    <div className="flex flex-col h-full bg-gray-50">
      <div className="p-4 bg-white border-b flex items-center gap-3">
        <button onClick={handleBack} className="text-gray-600 active:text-gray-900 -ml-2 p-2">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-2xl">{task ? task.name : 'Focus Timer'}</h1>
      </div>

      <div className="flex-1 flex flex-col p-6">
        {/* Task Description Section */}
        {task?.description && (
          <div className="w-full bg-white rounded-xl p-4 shadow-sm mb-6">
            <h3 className="text-gray-900 mb-1">Description</h3>
            <p className="text-gray-600 text-sm">{task.description}</p>
          </div>
        )}

        {/* Timer Circle */}
        <div className="flex justify-center mb-6">
          <div className="w-80 h-80 rounded-full bg-gradient-to-br from-purple-100 to-blue-100 flex items-center justify-center shadow-lg">
            <div className="w-72 h-72 rounded-full bg-white/80 backdrop-blur-sm flex items-center justify-center border border-purple-200/50">
              <div className="text-center w-full px-6 relative flex flex-col items-center justify-center">
                {/* Animated content area - just the main timer */}
                <div className="w-full">
                  {isResting ? (
                    // Rest Mode Layout - just label and timer
                    <div className={`w-full ${isAnimating ? 'animate-fade-out' : 'animate-fade-in'}`}>
                      <div className="text-gray-500 mb-1">
                        Resting
                      </div>
                      <div className="text-6xl text-gray-900 tabular-nums">
                        {formatTime(currentRestTimer)}
                      </div>
                    </div>
                  ) : (
                    // Focus Mode Layout - just label and timer
                    <div className={`w-full ${isAnimating ? 'animate-fade-out' : 'animate-fade-in'}`}>
                      <div className="text-gray-500 mb-1">
                        {task ? 'Focus time' : 'Timer'}
                      </div>
                      <div className="text-6xl text-gray-900 tabular-nums">
                        {isCountdownMode && isRunning ? formatTime(countdownSeconds) : formatTime(seconds)}
                      </div>
                    </div>
                  )}
                </div>
                
                {/* Static stats area - always in same position */}
                <div className="w-full mt-3">
                  {isResting ? (
                    // In rest mode: show focus time and total focus close together
                    <>
                      <div className="text-sm text-gray-400">
                        {isCountdownMode ? `Time left: ${formatTime(countdownSeconds)}` : `Focus time: ${formatTime(seconds)}`}
                      </div>
                      <div className="text-sm text-gray-400">
                        Total focus: {formatTime(totalFocusTime)}
                      </div>
                    </>
                  ) : (
                    // In focus mode: add placeholder to keep total focus at same position
                    <>
                      <div className="text-sm text-gray-400 invisible">
                        Placeholder
                      </div>
                      <div className="text-sm text-gray-400">
                        Total focus: {formatTime(totalFocusTime)}
                      </div>
                    </>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Controls */}
        <div className="flex gap-3 items-center justify-center mb-6">
          {totalFocusTime === 0 || !isRunning ? (
            <div className="flex flex-col items-center gap-3 w-full">
              {/* Countdown mode toggle - subtle inline design */}
              <div className="flex items-center gap-3 px-4 py-2">
                <label className="relative inline-block w-11 h-6">
                  <input 
                    type="checkbox" 
                    className="peer sr-only" 
                    checked={isCountdownMode}
                    onChange={(e) => setIsCountdownMode(e.target.checked)}
                  />
                  <span className="absolute cursor-pointer inset-0 bg-gray-300 rounded-full transition peer-checked:bg-blue-600"></span>
                  <span className="absolute cursor-pointer left-0.5 top-0.5 w-5 h-5 bg-white rounded-full transition peer-checked:translate-x-5"></span>
                </label>
                <span className="text-sm text-gray-600">Countdown Mode</span>
                {isCountdownMode && (
                  <div className="flex items-center gap-1.5 ml-2">
                    <input
                      type="number"
                      min="1"
                      max="180"
                      value={countdownDuration}
                      onChange={(e) => {
                        const value = parseInt(e.target.value);
                        if (!isNaN(value) && value >= 1 && value <= 180) {
                          setCountdownDuration(value);
                        }
                      }}
                      className="w-14 px-2 py-1 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent text-center text-sm"
                    />
                    <span className="text-xs text-gray-500">min</span>
                  </div>
                )}
              </div>
              
              {/* Start Focus Session Button */}
              <button
                onClick={() => {
                  // Check if another task is active
                  const otherActiveTask = allTasks.find(
                    t => t.id !== task?.id && t.timerState?.isRunning
                  );
                  
                  if (otherActiveTask) {
                    setShowActiveTaskWarning(true);
                    return;
                  }

                  setIsRunning(true);
                  setCurrentSessionStart(0);
                  setIsResting(false);
                  
                  // Set countdown seconds if in countdown mode
                  if (isCountdownMode) {
                    setCountdownSeconds(countdownDuration * 60);
                  }
                  
                  // Always create a new focus session
                  setFocusSessions((sessions) => [...sessions, { 
                    completedDate: new Date(), 
                    focusDuration: 0, 
                    restDuration: 0 
                  }]);
                }}
                className="px-8 py-4 bg-blue-600 text-white rounded-full active:bg-blue-700 transition-colors shadow-lg"
              >
                Start Focus Session
              </button>
            </div>
          ) : isResting ? (
            // Expanded Rest Button
            <button
              onClick={handleRest}
              className="px-8 py-4 bg-orange-500 text-white rounded-full active:bg-orange-600 transition-colors shadow-lg flex items-center gap-3"
            >
              <Coffee className="w-5 h-5" />
              <span>End Rest</span>
            </button>
          ) : (
            // Normal Controls
            <>
              <button
                onClick={handleRest}
                className="w-12 h-12 rounded-full flex items-center justify-center transition-colors bg-gray-200 text-gray-600"
              >
                <Coffee className="w-5 h-5" />
              </button>
              <button
                onClick={handlePause}
                className="w-12 h-12 rounded-full bg-gray-200 text-gray-600 flex items-center justify-center"
              >
                <Pause className="w-5 h-5" />
              </button>
              <button
                onClick={handleComplete}
                className="px-6 py-3 bg-blue-600 text-white rounded-full active:bg-blue-700 transition-colors flex items-center justify-center gap-2 shadow-md"
              >
                <CheckCircle className="w-5 h-5" />
                Complete
              </button>
            </>
          )}
        </div>

        {/* Statistics */}
        <div className="w-full bg-white rounded-xl shadow-sm mb-3">
          <div className="flex justify-around items-center px-5 py-3">
            <div className="flex items-center gap-2">
              <span className="text-left text-gray-500">Rest Count:</span>
              <span className="text-gray-900">{restCount}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-left text-gray-500">Rest Time:</span>
              <span className="text-gray-900">{formatMinutes(restSeconds)}</span>
            </div>
          </div>
        </div>

        {/* Focus Sessions */}
        <div className="w-full bg-white rounded-xl shadow-sm px-5 py-3">
          <div className="flex justify-between items-center">
            <span className="text-gray-900">Focus session: {focusSessions.length}</span>
            <button
              onClick={() => setShowDetailModal(true)}
              className="text-blue-600 active:text-blue-700"
            >
              View Detail
            </button>
          </div>
        </div>
      </div>

      {/* Detail Modal */}
      {showDetailModal && (
        <div 
          className="fixed inset-0 bg-black/50 z-50 flex items-end"
          onClick={() => setShowDetailModal(false)}
        >
          <div 
            className="w-full bg-white rounded-t-3xl max-h-[80vh] flex flex-col animate-slide-up"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="flex justify-between items-center p-6 border-b">
              <h2 className="text-gray-900">Focus Session Details</h2>
              <button
                onClick={() => setShowDetailModal(false)}
                className="text-gray-600 active:text-gray-900 p-2 -mr-2"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Scrollable Table */}
            <div className="flex-1 overflow-y-auto">
              <table className="w-full">
                <thead className="bg-white sticky top-0">
                  <tr className="border-b-2 border-gray-300">
                    <th className="px-5 py-3 text-left text-gray-500">Session Date</th>
                    <th className="px-5 py-3 text-left text-gray-500">Rest Time</th>
                    <th className="px-5 py-3 text-left text-gray-500">Focus Time</th>
                  </tr>
                </thead>
                <tbody>
                  {focusSessions.length === 0 ? (
                    <tr>
                      <td colSpan={3} className="px-5 py-8 text-center text-gray-400">
                        No focus sessions yet
                      </td>
                    </tr>
                  ) : (
                    focusSessions.map((session, index) => {
                      // Check if this is the current session (last session and timer is running)
                      const isCurrentSession = index === focusSessions.length - 1 && isRunning;
                      
                      return (
                        <tr key={index} className="border-t">
                          <td className="px-5 py-3 text-gray-900">{formatDate(session.completedDate)}</td>
                          <td className="px-5 py-3 text-gray-900">
                            {isCurrentSession ? (
                              <span className="text-blue-600">In Progress</span>
                            ) : (
                              formatMinutes(session.restDuration)
                            )}
                          </td>
                          <td className="px-5 py-3 text-gray-900">
                            {isCurrentSession ? (
                              <span className="text-blue-600">In Progress</span>
                            ) : (
                              formatMinutes(session.focusDuration)
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Pause Warning Modal */}
      {showPauseWarning && (
        <div 
          className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
          onClick={() => setShowPauseWarning(false)}
        >
          <div 
            className="w-full max-w-sm bg-white rounded-xl shadow-lg flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="flex justify-between items-center p-5">
              <h2 className="text-gray-900">Pause Task</h2>
              <button
                onClick={() => setShowPauseWarning(false)}
                className="text-gray-600 active:text-gray-900 p-2 -mr-2"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="px-5 pb-3">
              <p className="text-gray-600 mb-3">Pausing the task will end the current focus session. Are you sure you want to pause?</p>
              
              {/* Never show again checkbox */}
              <label className="flex items-center gap-2 text-sm text-gray-500 cursor-pointer">
                <input 
                  type="checkbox" 
                  checked={neverShowPauseWarning}
                  onChange={(e) => setNeverShowPauseWarning(e.target.checked)}
                  className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-2 focus:ring-blue-500"
                />
                <span>Don't show this again</span>
              </label>
            </div>

            {/* Modal Footer */}
            <div className="flex justify-between gap-2 p-5">
              <button
                onClick={() => setShowPauseWarning(false)}
                className="px-8 py-3 bg-gray-200 text-gray-700 rounded-full active:bg-gray-300"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  performPause();
                  setShowPauseWarning(false);
                }}
                className="px-8 py-3 bg-red-600 text-white rounded-full active:bg-red-700"
              >
                Pause
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Leave Warning Modal */}
      {showLeaveWarning && (
        <div 
          className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
          onClick={() => setShowLeaveWarning(false)}
        >
          <div 
            className="w-full max-w-sm bg-white rounded-xl shadow-lg flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="flex justify-between items-center p-5">
              <h2 className="text-gray-900">Leave Task</h2>
              <button
                onClick={() => setShowLeaveWarning(false)}
                className="text-gray-600 active:text-gray-900 p-2 -mr-2"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="px-5 pb-5">
              <p className="text-gray-600">The focus session is ongoing. Leaving will end the current focus session.</p>
            </div>

            {/* Modal Footer */}
            <div className="flex flex-col gap-2 p-5 pt-0">
              <button
                onClick={handleFiveMinuteBreak}
                className="w-full py-3 bg-blue-600 text-white rounded-full active:bg-blue-700"
              >
                Have a 5 Minutes Break
              </button>
              <button
                onClick={() => {
                  setShowLeaveWarning(false);
                  performPause();
                  // Use setTimeout to ensure state is saved before navigating
                  setTimeout(() => {
                    onBack();
                  }, 100);
                }}
                className="w-full py-3 bg-red-600 text-white rounded-full active:bg-red-700"
              >
                Leave
              </button>
              <button
                onClick={() => setShowLeaveWarning(false)}
                className="w-full py-3 bg-gray-200 text-gray-700 rounded-full active:bg-gray-300"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Active Task Warning Modal */}
      {showActiveTaskWarning && (() => {
        const activeTask = allTasks.find(t => t.id !== task?.id && t.timerState?.isRunning);
        
        return (
          <div 
            className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
            onClick={() => setShowActiveTaskWarning(false)}
          >
            <div 
              className="w-full max-w-sm bg-white rounded-xl shadow-lg flex flex-col"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Modal Header */}
              <div className="flex justify-between items-center p-5">
                <h2 className="text-gray-900">Active Task Warning</h2>
                <button
                  onClick={() => setShowActiveTaskWarning(false)}
                  className="text-gray-600 active:text-gray-900 p-2 -mr-2"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              {/* Modal Content */}
              <div className="px-5 pb-5">
                <p className="text-gray-600 mb-3">
                  Another task "{activeTask?.name}" is currently active. Please pause or complete it before starting a new focus session.
                </p>
              </div>

              {/* Modal Footer */}
              <div className="flex flex-col gap-2 p-5 pt-0">
                <button
                  onClick={() => {
                    if (activeTask && onNavigateToTask) {
                      setShowActiveTaskWarning(false);
                      onNavigateToTask(activeTask);
                    }
                  }}
                  className="w-full py-3 bg-purple-600 text-white rounded-full active:bg-purple-700"
                >
                  Jump to Active Task
                </button>
                <button
                  onClick={() => setShowActiveTaskWarning(false)}
                  className="w-full py-3 bg-gray-200 text-gray-700 rounded-full active:bg-gray-300"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>
        );
      })()}
    </div>
  );
}