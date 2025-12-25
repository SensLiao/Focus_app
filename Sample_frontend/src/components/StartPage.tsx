import { useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import { Task } from '../types';

interface StartPageProps {
  onCreateTask: (name: string, description: string) => void;
  onUpdateTask?: (id: string, name: string, description: string) => void;
  onStartWithoutTask: () => void;
  onBack: () => void;
  editTask?: Task | null;
}

export function StartPage({ onCreateTask, onUpdateTask, onStartWithoutTask, onBack, editTask }: StartPageProps) {
  const [taskName, setTaskName] = useState(editTask?.name || '');
  const [taskDescription, setTaskDescription] = useState(editTask?.description || '');

  const handleCreate = () => {
    if (taskName.trim()) {
      if (editTask && onUpdateTask) {
        onUpdateTask(editTask.id, taskName, taskDescription);
      } else {
        onCreateTask(taskName, taskDescription);
      }
      setTaskName('');
      setTaskDescription('');
    }
  };

  return (
    <div className="flex flex-col h-full bg-gray-50">
      <div className="p-4 bg-white border-b flex items-center gap-3">
        <button onClick={onBack} className="text-gray-600 active:text-gray-900 -ml-2 p-2">
          <ArrowLeft className="w-6 h-6" />
        </button>
        <h1 className="text-2xl">{editTask ? 'Edit Task' : 'New Task'}</h1>
      </div>

      <div className="flex-1 p-4 flex flex-col">
        <div className="space-y-5 flex-1">
          <div>
            <label htmlFor="task-name" className="block mb-2 text-gray-700">
              Task Name
            </label>
            <input
              id="task-name"
              type="text"
              value={taskName}
              onChange={(e) => setTaskName(e.target.value)}
              placeholder="Enter task name"
              className="w-full px-4 py-3.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent"
            />
          </div>

          <div>
            <label htmlFor="task-description" className="block mb-2 text-gray-700">
              Task Description
            </label>
            <textarea
              id="task-description"
              value={taskDescription}
              onChange={(e) => setTaskDescription(e.target.value)}
              placeholder="Enter task description (optional)"
              rows={5}
              className="w-full px-4 py-3.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-600 focus:border-transparent resize-none"
            />
          </div>
        </div>

        <div className="space-y-3 mt-6 pb-2">
          <button
            onClick={handleCreate}
            disabled={!taskName.trim()}
            className="w-full py-4 bg-blue-600 text-white rounded-xl active:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            {editTask ? 'Update' : 'Create'}
          </button>
          {!editTask && (
            <button
              onClick={onStartWithoutTask}
              className="w-full py-4 bg-gray-200 text-gray-700 rounded-xl active:bg-gray-300 transition-colors"
            >
              Start without a task
            </button>
          )}
        </div>
      </div>
    </div>
  );
}