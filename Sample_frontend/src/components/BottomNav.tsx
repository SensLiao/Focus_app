import { Home, History, Settings } from 'lucide-react';

type NavPage = 'home' | 'history' | 'settings';

interface BottomNavProps {
  currentPage: NavPage;
  onNavigate: (page: NavPage) => void;
}

export function BottomNav({ currentPage, onNavigate }: BottomNavProps) {
  return (
    <div className="bg-white border-t border-gray-200 px-2 py-2 flex justify-around items-center safe-area-inset-bottom">
      <button
        onClick={() => onNavigate('history')}
        className={`flex flex-col items-center gap-1 px-8 py-2 rounded-lg transition-colors ${
          currentPage === 'history'
            ? 'text-blue-600'
            : 'text-gray-400 active:text-gray-600'
        }`}
      >
        <History className="w-6 h-6" />
        <span className="text-xs">History</span>
      </button>
      <button
        onClick={() => onNavigate('home')}
        className={`flex flex-col items-center gap-1 px-8 py-2 rounded-lg transition-colors ${
          currentPage === 'home'
            ? 'text-blue-600'
            : 'text-gray-400 active:text-gray-600'
        }`}
      >
        <Home className="w-6 h-6" />
        <span className="text-xs">Home</span>
      </button>
      <button
        onClick={() => onNavigate('settings')}
        className={`flex flex-col items-center gap-1 px-8 py-2 rounded-lg transition-colors ${
          currentPage === 'settings'
            ? 'text-blue-600'
            : 'text-gray-400 active:text-gray-600'
        }`}
      >
        <Settings className="w-6 h-6" />
        <span className="text-xs">Settings</span>
      </button>
    </div>
  );
}