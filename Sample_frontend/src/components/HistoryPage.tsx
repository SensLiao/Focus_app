import { CompletedTask } from '../types';
import { Filter, ChevronDown, ChevronUp } from 'lucide-react';
import { useState, useRef, useEffect } from 'react';

interface HistoryPageProps {
  completedTasks: CompletedTask[];
}

export function HistoryPage({ completedTasks }: HistoryPageProps) {
  const [isFilterOpen, setIsFilterOpen] = useState(false);
  const [selectedDate, setSelectedDate] = useState(() => {
    // Default to today's date
    const today = new Date();
    return today.toISOString().split('T')[0];
  });
  const [appliedDate, setAppliedDate] = useState(''); // Actually applied filter
  const [expandedTasks, setExpandedTasks] = useState<Set<string>>(new Set());
  const chartScrollRef = useRef<HTMLDivElement>(null);

  // Scroll to 6am on mount or when appliedDate changes
  useEffect(() => {
    if (chartScrollRef.current && appliedDate) {
      // Each column is approximately 16px wide (15px + 1px gap), scroll to show hour 6
      const columnWidth = 16;
      const scrollTo = 6 * columnWidth;
      chartScrollRef.current.scrollLeft = scrollTo;
    }
  }, [appliedDate]);

  const toggleExpand = (taskId: string) => {
    const newExpanded = new Set(expandedTasks);
    if (newExpanded.has(taskId)) {
      newExpanded.delete(taskId);
    } else {
      newExpanded.add(taskId);
    }
    setExpandedTasks(newExpanded);
  };

  const formatDuration = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (hours > 0) {
      return `${hours}h ${minutes}m`;
    }
    return `${minutes}m`;
  };

  const formatDetailedDuration = (seconds: number) => {
    const days = Math.floor(seconds / (3600 * 24));
    const hours = Math.floor((seconds % (3600 * 24)) / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    const parts = [];
    if (days > 0) parts.push(`${days}d`);
    if (hours > 0) parts.push(`${hours}h`);
    if (minutes > 0 || parts.length === 0) parts.push(`${minutes}m`);
    
    return parts.join(' ');
  };

  const formatDate = (date: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
    }).format(date);
  };

  const filterTasks = () => {
    if (!appliedDate) {
      return completedTasks;
    }

    return completedTasks.filter((task) => {
      const taskDate = new Date(task.completedAt);
      taskDate.setHours(0, 0, 0, 0);

      const selected = new Date(appliedDate);
      selected.setHours(0, 0, 0, 0);
      
      return taskDate.getTime() === selected.getTime();
    });
  };

  const handleClearFilter = () => {
    setSelectedDate('');
    setAppliedDate('');
  };

  const handleApplyFilter = () => {
    setAppliedDate(selectedDate);
  };

  const isFilterChanged = selectedDate !== appliedDate;

  const filteredTasks = filterTasks();

  // Calculate hourly distribution for selected date
  const getHourlyDistribution = () => {
    if (!appliedDate) return null;

    // Fake data for now - show focus time from 12-15
    const hourlyData = Array(24).fill(0);
    hourlyData[12] = 3600; // 1 hour
    hourlyData[13] = 5400; // 1.5 hours
    hourlyData[14] = 2700; // 45 minutes

    return hourlyData;
  };

  const hourlyDistribution = getHourlyDistribution();
  const maxHourlyTime = hourlyDistribution ? Math.max(...hourlyDistribution, 1) : 1;

  return (
    <div className="flex flex-col h-full bg-gray-50">
      <div className="p-4 bg-white border-b flex items-center justify-between">
        <h1 className="text-2xl">History</h1>
        <button 
          className="text-gray-600 active:text-gray-900 p-2 -mr-2"
          onClick={() => setIsFilterOpen(!isFilterOpen)}
        >
          <Filter className="w-6 h-6" />
        </button>
      </div>

      {isFilterOpen && (
        <div className="bg-white border-b p-4 shadow-sm">
          <div className="space-y-3">
            <label className="block text-sm text-gray-600 mb-1">Select date</label>
            <div className="flex gap-2">
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="flex-1 p-3 border border-gray-300 rounded-lg"
              />
              {isFilterChanged && (
                <button
                  onClick={handleApplyFilter}
                  className="px-6 py-3 bg-blue-500 text-white rounded-lg active:bg-blue-600 whitespace-nowrap"
                >
                  Apply
                </button>
              )}
              {selectedDate && (
                <button
                  onClick={handleClearFilter}
                  className="px-6 py-3 bg-gray-100 text-gray-700 rounded-lg active:bg-gray-200 whitespace-nowrap"
                >
                  Clear
                </button>
              )}
            </div>
          </div>
        </div>
      )}

      <div className="flex-1 overflow-y-auto p-4">
        {/* Statistic Board */}
        <div className="bg-white rounded-xl shadow-sm mb-4 overflow-hidden" style={{ height: '240px' }}>
          {!appliedDate ? (
            // Blank state when no filter selected
            <div className="h-full flex items-center justify-center text-gray-400">
              <p>Select a date to view hourly distribution</p>
            </div>
          ) : hourlyDistribution && filteredTasks.length > 0 ? (
            // Hourly distribution chart
            <div className="h-full p-4 flex flex-col">
              <h3 className="text-gray-900 mb-3 text-sm">Focus Time Distribution</h3>
              <div className="flex-1 flex gap-2">
                {/* Y-axis */}
                <div className="flex flex-col justify-between text-xs text-gray-400 pr-2" style={{ width: '40px' }}>
                  <span>60m</span>
                  <span>45m</span>
                  <span>30m</span>
                  <span>15m</span>
                  <span>0m</span>
                </div>
                {/* Chart bars - scrollable horizontally */}
                <div 
                  className="flex-1 overflow-x-auto" 
                  ref={chartScrollRef}
                >
                  <div className="flex items-end gap-1" style={{ minWidth: '400px' }}>
                    {hourlyDistribution.map((seconds, hour) => {
                      const heightPercent = maxHourlyTime > 0 ? (seconds / maxHourlyTime) * 100 : 0;
                      const hasData = seconds > 0;
                      
                      return (
                        <div key={hour} className="flex flex-col items-center gap-1" style={{ width: '15px' }}>
                          <div className="w-full flex items-end justify-center" style={{ height: '140px' }}>
                            {hasData && (
                              <div 
                                className="w-full bg-gradient-to-t from-blue-500 to-purple-500 rounded-t transition-all"
                                style={{ height: `${heightPercent}%`, minHeight: hasData ? '4px' : '0' }}
                                title={`${hour}:00 - ${formatDuration(seconds)}`}
                              >
                              </div>
                            )}
                          </div>
                          <span className="text-xs text-gray-400" style={{ fontSize: '10px' }}>
                            {hour}
                          </span>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </div>
          ) : (
            // No data for selected date
            <div className="h-full flex items-center justify-center text-gray-400">
              <p>No tasks completed on this date</p>
            </div>
          )}
        </div>

        {filteredTasks.length === 0 ? (
          <div className="flex items-center justify-center h-full text-gray-400 px-6 text-center">
            <p>
              {appliedDate 
                ? 'No task completed on this day' 
                : 'No completed tasks yet. Complete your first task to see it here!'}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {filteredTasks.map((task, index) => {
              // Create unique key using index and timestamp for each completed task instance
              const uniqueKey = `${task.id}-${index}-${new Date(task.completedAt).getTime()}`;
              const isExpanded = expandedTasks.has(uniqueKey);
              
              return (
                <div
                  key={uniqueKey}
                  className="bg-white rounded-xl shadow-sm overflow-hidden"
                >
                  <button
                    onClick={() => toggleExpand(uniqueKey)}
                    className="w-full p-4 flex items-center justify-between gap-3 active:bg-gray-50"
                  >
                    <div className="flex-1 min-w-0 text-left">
                      <h3 className="truncate">{task.name}</h3>
                    </div>
                    <div className="shrink-0 flex items-center gap-3">
                      <div className="text-gray-600 text-sm">{formatDate(new Date(task.completedAt))}</div>
                      {isExpanded ? (
                        <ChevronUp className="w-5 h-5 text-gray-500" />
                      ) : (
                        <ChevronDown className="w-5 h-5 text-gray-500" />
                      )}
                    </div>
                  </button>
                  
                  {isExpanded && (
                    <div className="px-4 pb-4 pt-2 border-t bg-gray-50 space-y-3">
                      <div className="flex justify-between">
                        <span className="text-gray-600">Total duration</span>
                        <span className="text-gray-900">{formatDetailedDuration(task.duration)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Total focus time</span>
                        <span className="text-gray-900">{formatDetailedDuration(task.totalFocusTime)}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Rest count</span>
                        <span className="text-gray-900">-</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-600">Total rest time</span>
                        <span className="text-gray-900">-</span>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}