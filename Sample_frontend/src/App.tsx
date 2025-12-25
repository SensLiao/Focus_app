import { useState } from 'react';
import { HomePage } from './components/HomePage';
import { StartPage } from './components/StartPage';
import { TimerPage } from './components/TimerPage';
import { HistoryPage } from './components/HistoryPage';
import { SettingsPage } from './components/SettingsPage';
import { BottomNav } from './components/BottomNav';
import { Task, CompletedTask } from './types';

type Page = 'home' | 'start' | 'timer' | 'history' | 'settings';
type NavPage = 'home' | 'history' | 'settings';

export default function App() {
  const [currentPage, setCurrentPage] = useState<Page>('home');
  const [tasks, setTasks] = useState<Task[]>([]);
  const [completedTasks, setCompletedTasks] = useState<CompletedTask[]>([]);
  const [currentTask, setCurrentTask] = useState<Task | null>(null);
  const [editingTask, setEditingTask] = useState<Task | null>(null);

  const handleAddTask = () => {
    setEditingTask(null);
    setCurrentPage('start');
  };

  const handleEditTask = (task: Task) => {
    setEditingTask(task);
    setCurrentPage('start');
  };

  const handleCreateTask = (name: string, description: string) => {
    const newTask: Task = {
      id: Date.now().toString(),
      name,
      description,
      createdAt: new Date(),
      totalFocusTime: 0,
    };
    setTasks([...tasks, newTask]);
    setCurrentTask(newTask);
    setCurrentPage('timer');
  };

  const handleUpdateTask = (id: string, name: string, description: string) => {
    setTasks(tasks.map(task => 
      task.id === id 
        ? { ...task, name, description }
        : task
    ));
    setEditingTask(null);
    setCurrentPage('home');
  };

  const handleStartTask = (task: Task) => {
    setCurrentTask(task);
    setCurrentPage('timer');
  };

  const handleStartWithoutTask = () => {
    const anonymousTask: Task = {
      id: Date.now().toString(),
      name: 'Anonymous',
      description: '',
      createdAt: new Date(),
      totalFocusTime: 0,
    };
    setTasks([...tasks, anonymousTask]);
    setCurrentTask(anonymousTask);
    setCurrentPage('timer');
  };

  const handleCompleteTask = (duration: number) => {
    if (currentTask) {
      const completedTask: CompletedTask = {
        ...currentTask,
        completedAt: new Date(),
        duration,
      };
      setCompletedTasks([completedTask, ...completedTasks]);
      
      // Remove the task from the tasks list
      setTasks(tasks.filter(t => t.id !== currentTask.id));
    }
    setCurrentTask(null);
    setCurrentPage('home');
  };

  const handleBackFromTimer = () => {
    setCurrentTask(null);
    setCurrentPage('home');
  };

  const handleUpdateTaskState = (taskId: string, state: any) => {
    setTasks(tasks.map(task =>
      task.id === taskId
        ? { ...task, timerState: state }
        : task
    ));
  };

  const handleBackFromStart = () => {
    setEditingTask(null);
    setCurrentPage('home');
  };

  const handleDeleteTask = (taskId: string) => {
    setTasks(tasks.filter(task => task.id !== taskId));
  };

  const handleNavigation = (page: NavPage) => {
    setCurrentPage(page);
  };

  const showBottomNav = currentPage === 'home' || currentPage === 'history' || currentPage === 'settings';

  return (
    <div className="h-screen flex flex-col max-w-md mx-auto bg-white">
      <div className="flex-1 overflow-hidden">
        {currentPage === 'home' && (
          <HomePage
            tasks={tasks}
            onStartTask={handleStartTask}
            onAddTask={handleAddTask}
            onEditTask={handleEditTask}
            onDeleteTask={handleDeleteTask}
          />
        )}
        {currentPage === 'start' && (
          <StartPage
            onCreateTask={handleCreateTask}
            onUpdateTask={handleUpdateTask}
            onStartWithoutTask={handleStartWithoutTask}
            onBack={handleBackFromStart}
            editTask={editingTask}
          />
        )}
        {currentPage === 'timer' && (
          <TimerPage
            task={currentTask}
            onComplete={handleCompleteTask}
            onBack={handleBackFromTimer}
            onUpdateTaskState={handleUpdateTaskState}
            allTasks={tasks}
            onNavigateToTask={handleStartTask}
          />
        )}
        {currentPage === 'history' && (
          <HistoryPage completedTasks={completedTasks} />
        )}
        {currentPage === 'settings' && (
          <SettingsPage completedTasks={completedTasks} />
        )}
      </div>
      
      {showBottomNav && (
        <BottomNav
          currentPage={currentPage as NavPage}
          onNavigate={handleNavigation}
        />
      )}
    </div>
  );
}