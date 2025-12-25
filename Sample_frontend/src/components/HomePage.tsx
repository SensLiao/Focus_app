import { Plus, Edit3, Trash2, X, Play, Coffee } from 'lucide-react';
import { Task } from '../types';
import { useState } from 'react';

interface HomePageProps {
  tasks: Task[];
  onStartTask: (task: Task) => void;
  onAddTask: () => void;
  onEditTask: (task: Task) => void;
  onDeleteTask: (taskId: string) => void;
}

export function HomePage({ tasks, onStartTask, onAddTask, onEditTask, onDeleteTask }: HomePageProps) {
  const [isEditMode, setIsEditMode] = useState(false);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  const formatFocusTime = (seconds: number): string => {
    if (seconds === 0) return '0 min';
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    
    if (hours > 0) {
      if (minutes > 0) {
        return `${hours}h ${minutes}m`;
      }
      return `${hours}h`;
    }
    return `${minutes}m`;
  };

  const handleDeleteClick = (taskId: string) => {
    setDeleteConfirmId(taskId);
  };

  const confirmDelete = () => {
    if (deleteConfirmId) {
      onDeleteTask(deleteConfirmId);
      setDeleteConfirmId(null);
    }
  };

  const cancelDelete = () => {
    setDeleteConfirmId(null);
  };

  const toggleEditMode = () => {
    setIsEditMode(!isEditMode);
  };

  return (
    <div className="flex flex-col h-full bg-gray-50">
      <div className="p-4 bg-white border-b">
        <h1 className="text-2xl">To do List</h1>
      </div>
      
      <div className="flex-1 overflow-y-auto p-4">
        {tasks.length === 0 ? (
          <div className="flex items-center justify-center h-full text-gray-400 px-6 text-center">
            <p>No tasks yet. Add your first task to get started!</p>
          </div>
        ) : (
          <div className="space-y-3">
            {tasks.map((task) => (
              <div
                key={task.id}
                className="bg-white rounded-xl p-4 shadow-sm flex items-center justify-between gap-3"
              >
                <div className="flex-1 min-w-0">
                  <h3 className="truncate">{task.name}</h3>
                  <p className="text-gray-500 mt-1">
                    Focus time: {formatFocusTime(task.totalFocusTime)}
                  </p>
                </div>
                <div className="flex gap-2 shrink-0">
                  {isEditMode ? (
                    <>
                      <button
                        onClick={() => onEditTask(task)}
                        className="p-2.5 bg-blue-100 text-blue-600 rounded-lg active:bg-blue-200 transition-colors"
                      >
                        <Edit3 className="w-5 h-5" />
                      </button>
                      <button
                        onClick={() => handleDeleteClick(task.id)}
                        className="p-2.5 bg-red-100 text-red-600 rounded-lg active:bg-red-200 transition-colors"
                      >
                        <Trash2 className="w-5 h-5" />
                      </button>
                    </>
                  ) : task.timerState?.isRunning ? (
                    // Show rest/in-progress icon for tasks that are active
                    <button
                      onClick={() => onStartTask(task)}
                      className="p-2.5 bg-purple-100 text-purple-600 rounded-lg active:bg-purple-200 transition-colors"
                    >
                      <Coffee className="w-5 h-5" />
                    </button>
                  ) : (
                    <button
                      onClick={() => onStartTask(task)}
                      className="p-2.5 bg-green-100 text-green-600 rounded-lg active:bg-green-200 transition-colors"
                    >
                      <Play className="w-5 h-5" />
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Delete Confirmation Modal */}
      {deleteConfirmId && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-sm w-full shadow-xl">
            <h2 className="text-gray-900 mb-2">Delete Task?</h2>
            <p className="text-gray-600 mb-6">
              Are you sure you want to delete this task? This action cannot be undone.
            </p>
            <div className="flex gap-3">
              <button
                onClick={cancelDelete}
                className="flex-1 py-3 bg-gray-200 text-gray-700 rounded-xl active:bg-gray-300 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={confirmDelete}
                className="flex-1 py-3 bg-red-600 text-white rounded-xl active:bg-red-700 transition-colors"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Floating Action Buttons */}
      <div className="fixed bottom-20 right-4 flex flex-col gap-3 z-10">
        <button
          onClick={toggleEditMode}
          className={`w-16 h-16 ${
            isEditMode ? 'bg-orange-600' : 'bg-gray-600'
          } text-white rounded-full shadow-lg active:scale-95 transition-all flex items-center justify-center`}
        >
          {isEditMode ? <X className="w-7 h-7" /> : <Edit3 className="w-6 h-6" />}
        </button>
        <button
          onClick={onAddTask}
          className="w-16 h-16 bg-blue-600 text-white rounded-full shadow-lg active:scale-95 transition-transform flex items-center justify-center"
        >
          <Plus className="w-7 h-7" />
        </button>
      </div>
    </div>
  );
}