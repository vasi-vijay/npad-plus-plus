import React from 'react';
import { SearchState, SearchMode } from '../types';
import { X, Search, Replace, Bookmark, FolderSearch } from 'lucide-react';

interface FindReplaceModalProps {
  searchState: SearchState;
  isDark: boolean;
  onUpdateState: (partial: Partial<SearchState>) => void;
  onClose: () => void;
  onFindNext: () => void;
  onFindPrev: () => void;
  onReplace: () => void;
  onReplaceAll: () => void;
  onMarkAll: () => void;
  onClearMarks?: () => void;
  onCount: () => void;
}

export const FindReplaceModal: React.FC<FindReplaceModalProps> = ({
  searchState,
  isDark,
  onUpdateState,
  onClose,
  onFindNext,
  onFindPrev,
  onReplace,
  onReplaceAll,
  onMarkAll,
  onClearMarks,
  onCount,
}) => {
  if (!searchState.isOpen) return null;

  const currentSearchMode: SearchMode =
    searchState.searchMode || (searchState.useRegex ? 'regex' : 'normal');
  const currentDirection = searchState.direction || 'down';

  const handleModeChange = (mode: SearchMode) => {
    onUpdateState({
      searchMode: mode,
      useRegex: mode === 'regex',
    });
  };

  const bg = isDark
    ? 'bg-[#2b2d30] border-[#43464b] text-gray-200'
    : 'bg-[#f0f0f0] border-[#a0a0a0] text-gray-900';
  const inputBg = isDark
    ? 'bg-[#1e1f22] border-[#4e5258] text-white'
    : 'bg-white border-[#8e8e8e] text-black';
  const groupBoxBorder = isDark ? 'border-[#43464b]' : 'border-[#c4c4c4]';

  const nppBtn = isDark
    ? 'w-full px-3 py-1.5 text-xs rounded-sm bg-[#3c3f41] hover:bg-[#4c5052] border border-[#585b5e] text-gray-100 text-center transition-colors shadow-xs'
    : 'w-full px-3 py-1.5 text-xs rounded-sm bg-[#e4e4e4] hover:bg-[#d5d5d5] border border-[#999999] text-gray-900 text-center transition-colors shadow-xs';

  return (
    <div className="fixed inset-0 bg-black/45 z-50 flex items-center justify-center p-4 backdrop-blur-xs">
      <div
        className="w-full max-w-[580px] rounded border shadow-2xl overflow-hidden theme-dialog transition-colors duration-150"
        style={{
          backgroundColor: 'var(--theme-dialog-bg)',
          color: 'var(--theme-dialog-fg)',
          borderColor: 'var(--theme-dialog-border)',
        }}
      >
        {/* Classic Notepad++ Dialog Title Bar */}
        <div
          className="px-3 py-1.5 flex items-center justify-between border-b select-none text-xs font-semibold theme-dialog-header"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
            color: 'var(--theme-dialog-fg)',
          }}
        >
          <span>
            {searchState.activeTab === 'find'
              ? 'Find'
              : searchState.activeTab === 'replace'
              ? 'Replace'
              : searchState.activeTab === 'find-files'
              ? 'Find in Files'
              : 'Mark'}
          </span>
          <button
            onClick={onClose}
            className="w-5 h-5 rounded-sm flex items-center justify-center hover:bg-red-500 hover:text-white transition-colors"
            aria-label="Close dialog"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Classic 4-Tab Bar: Find | Replace | Find in Files | Mark */}
        <div
          className="flex border-b px-2 pt-1.5 text-xs select-none"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          {(
            [
              { id: 'find', label: 'Find', icon: Search },
              { id: 'replace', label: 'Replace', icon: Replace },
              { id: 'find-files', label: 'Find in Files', icon: FolderSearch },
              { id: 'mark', label: 'Mark', icon: Bookmark },
            ] as const
          ).map((t) => {
            const Icon = t.icon;
            const active = searchState.activeTab === t.id;
            return (
              <button
                key={t.id}
                onClick={() => onUpdateState({ activeTab: t.id })}
                className={`px-3.5 py-1.5 flex items-center space-x-1.5 rounded-t border-t border-l border-r -mb-px transition-colors ${
                  active
                    ? 'font-semibold border-b-0'
                    : 'border-transparent opacity-70 hover:opacity-100'
                }`}
                style={{
                  backgroundColor: active ? 'var(--theme-dialog-bg)' : 'transparent',
                  borderColor: active ? 'var(--theme-dialog-border)' : 'transparent',
                  color: 'var(--theme-dialog-fg)',
                }}
              >
                <Icon className="w-3 h-3" />
                <span>{t.label}</span>
              </button>
            );
          })}
        </div>

        {/* Dialog Two-Column Layout (Left: Inputs + GroupBoxes, Right: Action Buttons) */}
        <div className="p-4 flex gap-4">
          {/* Left Column */}
          <div className="flex-1 space-y-3">
            {/* Find what */}
            <div className="flex items-center space-x-2">
              <label className="w-24 text-right text-xs font-medium flex-shrink-0">
                Find what :
              </label>
              <input
                type="text"
                value={searchState.query}
                onChange={(e) => onUpdateState({ query: e.target.value })}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    currentDirection === 'up' ? onFindPrev() : onFindNext();
                  } else if (e.key === 'Escape') {
                    onClose();
                  }
                }}
                placeholder="Search query..."
                autoFocus
                className={`flex-1 px-2.5 py-1 text-xs rounded-sm border outline-none font-mono focus:border-blue-500 ${inputBg}`}
              />
            </div>

            {/* Replace with (Replace or Find in Files) */}
            {(searchState.activeTab === 'replace' || searchState.activeTab === 'find-files') && (
              <div className="flex items-center space-x-2">
                <label className="w-24 text-right text-xs font-medium flex-shrink-0">
                  Replace with :
                </label>
                <input
                  type="text"
                  value={searchState.replaceQuery}
                  onChange={(e) => onUpdateState({ replaceQuery: e.target.value })}
                  onKeyDown={(e) => e.key === 'Enter' && onReplace()}
                  placeholder="Replacement text..."
                  className={`flex-1 px-2.5 py-1 text-xs rounded-sm border outline-none font-mono focus:border-blue-500 ${inputBg}`}
                />
              </div>
            )}

            {/* Find in Files Filters & Directory */}
            {searchState.activeTab === 'find-files' && (
              <>
                <div className="flex items-center space-x-2">
                  <label className="w-24 text-right text-xs font-medium flex-shrink-0">
                    Filters :
                  </label>
                  <input
                    type="text"
                    value={searchState.fileFilter ?? '*.java *.ts *.py *.*'}
                    onChange={(e) => onUpdateState({ fileFilter: e.target.value })}
                    className={`flex-1 px-2.5 py-1 text-xs rounded-sm border outline-none font-mono ${inputBg}`}
                  />
                </div>
                <div className="flex items-center space-x-2">
                  <label className="w-24 text-right text-xs font-medium flex-shrink-0">
                    Directory :
                  </label>
                  <input
                    type="text"
                    value={searchState.directoryPath ?? '.'}
                    onChange={(e) => onUpdateState({ directoryPath: e.target.value })}
                    className={`flex-1 px-2.5 py-1 text-xs rounded-sm border outline-none font-mono ${inputBg}`}
                  />
                </div>
              </>
            )}

            {/* Checkboxes: Match whole word only, Match case, Wrap around */}
            <div className="space-y-1.5 pt-1 pl-2">
              <label className="flex items-center space-x-2 text-xs cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={searchState.wholeWord}
                  onChange={(e) => onUpdateState({ wholeWord: e.target.checked })}
                  className="rounded-sm border-gray-400"
                />
                <span>Match whole word only</span>
              </label>
              <label className="flex items-center space-x-2 text-xs cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={searchState.caseSensitive}
                  onChange={(e) => onUpdateState({ caseSensitive: e.target.checked })}
                  className="rounded-sm border-gray-400"
                />
                <span>Match case</span>
              </label>
              <label className="flex items-center space-x-2 text-xs cursor-pointer select-none">
                <input
                  type="checkbox"
                  checked={searchState.wrapAround}
                  onChange={(e) => onUpdateState({ wrapAround: e.target.checked })}
                  className="rounded-sm border-gray-400"
                />
                <span>Wrap around</span>
              </label>
            </div>

            {/* Bottom Row: Search Mode & Direction Group Boxes */}
            <div className="flex gap-3 pt-1">
              {/* Search Mode GroupBox */}
              <fieldset className={`flex-1 border rounded p-2.5 space-y-1.5 text-xs ${groupBoxBorder}`}>
                <legend className="px-1 text-[11px] font-semibold opacity-80">Search Mode</legend>
                <label className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="radio"
                    name="nppSearchMode"
                    checked={currentSearchMode === 'normal'}
                    onChange={() => handleModeChange('normal')}
                  />
                  <span>Normal</span>
                </label>
                <label className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="radio"
                    name="nppSearchMode"
                    checked={currentSearchMode === 'extended'}
                    onChange={() => handleModeChange('extended')}
                  />
                  <span>Extended (\n, \r, \t, \0, \x...)</span>
                </label>
                <label className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="radio"
                    name="nppSearchMode"
                    checked={currentSearchMode === 'regex'}
                    onChange={() => handleModeChange('regex')}
                  />
                  <span>Regular expression</span>
                </label>
              </fieldset>

              {/* Direction GroupBox */}
              <fieldset className={`w-28 border rounded p-2.5 space-y-1.5 text-xs ${groupBoxBorder}`}>
                <legend className="px-1 text-[11px] font-semibold opacity-80">Direction</legend>
                <label className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="radio"
                    name="nppDirection"
                    checked={currentDirection === 'up'}
                    onChange={() => onUpdateState({ direction: 'up' })}
                  />
                  <span>Up</span>
                </label>
                <label className="flex items-center space-x-2 cursor-pointer">
                  <input
                    type="radio"
                    name="nppDirection"
                    checked={currentDirection === 'down'}
                    onChange={() => onUpdateState({ direction: 'down' })}
                  />
                  <span>Down</span>
                </label>
              </fieldset>
            </div>
          </div>

          {/* Right Column: Classic Notepad++ Vertical Action Stack */}
          <div className="w-40 flex flex-col space-y-2">
            <button
              onClick={() => (currentDirection === 'up' ? onFindPrev() : onFindNext())}
              className={`${nppBtn} font-semibold border-blue-500`}
            >
              Find Next
            </button>
            <button onClick={onFindPrev} className={nppBtn}>
              Find Previous
            </button>
            <button onClick={onCount} className={nppBtn}>
              Count
            </button>

            {searchState.activeTab === 'replace' && (
              <>
                <button onClick={onReplace} className={nppBtn}>
                  Replace
                </button>
                <button onClick={onReplaceAll} className={`${nppBtn} font-semibold`}>
                  Replace All
                </button>
              </>
            )}

            {searchState.activeTab === 'find-files' && (
              <button onClick={onCount} className={`${nppBtn} font-semibold`}>
                Find All
              </button>
            )}

            {searchState.activeTab === 'mark' && (
              <>
                <button onClick={onMarkAll} className={`${nppBtn} font-semibold`}>
                  Mark All
                </button>
                {onClearMarks && (
                  <button onClick={onClearMarks} className={nppBtn}>
                    Clear all marks
                  </button>
                )}
              </>
            )}

            <div className="flex-1" />

            <button onClick={onClose} className={nppBtn}>
              Close
            </button>
          </div>
        </div>

        {/* Status Bar Footer inside Find/Replace Dialog */}
        <div
          className={`px-3 py-1.5 text-xs font-mono border-t ${
            isDark
              ? 'bg-[#212325] border-[#383a3e] text-blue-400'
              : 'bg-[#e4e4e4] border-[#c0c0c0] text-blue-800'
          }`}
        >
          {searchState.lastMessage || 'Ready.'}
        </div>
      </div>
    </div>
  );
};
