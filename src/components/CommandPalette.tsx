import React, { useState, useEffect, useRef } from 'react';
import { Search, Terminal, Zap, ArrowRight } from 'lucide-react';

export interface PaletteCommand {
  id: string;
  name: string;
  category: string;
  shortcut?: string;
  action: () => void;
}

interface CommandPaletteProps {
  isOpen: boolean;
  isDark: boolean;
  commands: PaletteCommand[];
  onClose: () => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({
  isOpen,
  isDark,
  commands,
  onClose,
}) => {
  const [query, setQuery] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setQuery('');
      setSelectedIndex(0);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  const filtered = commands.filter((cmd) =>
    `${cmd.category} ${cmd.name}`.toLowerCase().includes(query.toLowerCase())
  );

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % Math.max(1, filtered.length));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + filtered.length) % Math.max(1, filtered.length));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (filtered[selectedIndex]) {
        filtered[selectedIndex].action();
        onClose();
      }
    } else if (e.key === 'Escape') {
      onClose();
    }
  };

  if (!isOpen) return null;

  const bg = isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-white border-[#d0d0d0] text-gray-800';
  const inputBg = isDark ? 'bg-[#1e1f22] text-white' : 'bg-[#f4f4f4] text-black';

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-start justify-center pt-20 p-4 backdrop-blur-xs">
      <div
        className="w-full max-w-xl rounded-xl border shadow-2xl overflow-hidden theme-dialog transition-colors duration-150"
        style={{
          backgroundColor: 'var(--theme-dialog-bg)',
          color: 'var(--theme-dialog-fg)',
          borderColor: 'var(--theme-dialog-border)',
        }}
      >
        {/* Search Input */}
        <div
          className="p-3 border-b flex items-center space-x-2 theme-dialog-header"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          <Search className="w-4 h-4 opacity-60" />
          <input
            ref={inputRef}
            type="text"
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setSelectedIndex(0);
            }}
            onKeyDown={handleKeyDown}
            placeholder="Type a command or search action (e.g. format, git, java, theme)..."
            className="w-full px-2.5 py-1.5 text-sm outline-none font-mono rounded-md theme-dialog-input border"
            style={{
              backgroundColor: 'var(--theme-input-bg)',
              borderColor: 'var(--theme-input-border)',
              color: 'var(--theme-input-fg)',
            }}
          />
          <kbd className="text-[10px] px-1.5 py-0.5 rounded bg-black/10 dark:bg-white/10 opacity-70 font-mono">
            ESC
          </kbd>
        </div>

        {/* Results List */}
        <div className="max-h-80 overflow-y-auto p-1 text-xs">
          {filtered.length === 0 ? (
            <div className="p-4 text-center text-gray-400">No matching commands found</div>
          ) : (
            filtered.map((cmd, idx) => {
              const isSelected = idx === selectedIndex;
              return (
                <div
                  key={cmd.id}
                  onClick={() => {
                    cmd.action();
                    onClose();
                  }}
                  onMouseEnter={() => setSelectedIndex(idx)}
                  className={`px-3 py-2 rounded-lg flex items-center justify-between cursor-pointer transition-colors ${
                    isSelected
                      ? 'bg-blue-600 text-white font-medium'
                      : isDark
                      ? 'hover:bg-gray-700/60 text-gray-300'
                      : 'hover:bg-gray-100 text-gray-700'
                  }`}
                >
                  <div className="flex items-center space-x-2.5">
                    <span className="text-xs opacity-70 px-1.5 py-0.5 rounded bg-black/20 font-mono uppercase text-[10px]">
                      {cmd.category}
                    </span>
                    <span>{cmd.name}</span>
                  </div>
                  {cmd.shortcut && (
                    <kbd className="text-[10px] px-1.5 py-0.5 rounded bg-black/20 font-mono opacity-80">
                      {cmd.shortcut}
                    </kbd>
                  )}
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
};
