import React, { useState } from 'react';
import { X, CornerDownLeft } from 'lucide-react';

interface GoToLineModalProps {
  isOpen: boolean;
  isDark: boolean;
  currentLine: number;
  totalLines: number;
  onClose: () => void;
  onGoTo: (line: number) => void;
}

export const GoToLineModal: React.FC<GoToLineModalProps> = ({
  isOpen,
  isDark,
  currentLine,
  totalLines,
  onClose,
  onGoTo,
}) => {
  const [target, setTarget] = useState(String(currentLine));

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const lineNum = parseInt(target, 10);
    if (!isNaN(lineNum) && lineNum >= 1 && lineNum <= totalLines) {
      onGoTo(lineNum);
      onClose();
    }
  };

  const bg = isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-[#f4f4f4] border-[#c0c0c0] text-gray-800';
  const inputBg = isDark ? 'bg-[#1e1f22] border-[#4e5258] text-white' : 'bg-white border-[#bbbbbb] text-black';

  return (
    <div className="fixed inset-0 bg-black/45 z-50 flex items-center justify-center p-4 backdrop-blur-xs">
      <div
        className="w-full max-w-sm rounded-lg border shadow-2xl p-4 theme-dialog transition-colors duration-150"
        style={{
          backgroundColor: 'var(--theme-dialog-bg)',
          color: 'var(--theme-dialog-fg)',
          borderColor: 'var(--theme-dialog-border)',
        }}
      >
        <div
          className="flex items-center justify-between pb-3 border-b"
          style={{ borderColor: 'var(--theme-dialog-border)' }}
        >
          <span className="text-xs font-bold">Go to Line (1 - {totalLines})</span>
          <button onClick={onClose} className="p-1 hover:bg-black/10 dark:hover:bg-white/10 rounded">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 pt-3">
          <div className="text-xs opacity-75">
            You are currently on line: <span className="font-bold text-blue-500">{currentLine}</span>
          </div>

          <div>
            <label className="text-xs font-semibold block mb-1">Target line number:</label>
            <input
              type="number"
              min={1}
              max={totalLines}
              value={target}
              onChange={(e) => setTarget(e.target.value)}
              autoFocus
              className="w-full px-3 py-1.5 text-xs rounded border outline-none font-mono theme-dialog-input"
              style={{
                backgroundColor: 'var(--theme-input-bg)',
                borderColor: 'var(--theme-input-border)',
                color: 'var(--theme-input-fg)',
              }}
            />
          </div>

          <div className="flex justify-end space-x-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-3 py-1.5 text-xs rounded border border-gray-400/40 hover:bg-black/5 dark:hover:bg-white/5"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 text-xs font-bold rounded bg-blue-600 hover:bg-blue-500 text-white flex items-center space-x-1"
            >
              <span>Go</span>
              <CornerDownLeft className="w-3 h-3" />
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
