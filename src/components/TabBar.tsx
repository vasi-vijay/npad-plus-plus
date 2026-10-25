import React, { useState, useEffect } from 'react';
import { TabItem } from '../types';
import { X, Plus, FileCode, FileText, AlertTriangle, Save } from 'lucide-react';

interface TabBarProps {
  tabs: TabItem[];
  activeTabId: string;
  isDark: boolean;
  onSelectTab: (id: string) => void;
  onCloseTab: (id: string, e?: React.MouseEvent) => void;
  onCloseOtherTabs?: (keepId: string) => void;
  onSaveTab?: (id: string) => void;
  onOpenTerminalAtTab?: (id: string) => void;
  onNewTab: () => void;
}

export const TabBar: React.FC<TabBarProps> = ({
  tabs,
  activeTabId,
  isDark,
  onSelectTab,
  onCloseTab,
  onCloseOtherTabs,
  onSaveTab,
  onOpenTerminalAtTab,
  onNewTab,
}) => {
  const [tabContextMenu, setTabContextMenu] = useState<{ x: number; y: number; tabId: string } | null>(null);

  useEffect(() => {
    if (!tabContextMenu) return;
    const close = () => setTabContextMenu(null);
    window.addEventListener('click', close);
    return () => window.removeEventListener('click', close);
  }, [tabContextMenu]);

  return (
    <div
      className={`h-8 flex items-end px-1.5 overflow-x-auto select-none border-b transition-colors no-scrollbar relative ${
        isDark ? 'bg-[#1d1e20] border-[#2e3033]' : 'bg-[#dcdcdc] border-[#b8b8b8]'
      }`}
    >
      <div className="flex items-end space-x-0.5">
        {tabs.map((tab) => {
          const isActive = tab.id === activeTabId;
          const isMissing = Boolean(tab.isMissingOnDisk);

          return (
            <div
              key={tab.id}
              onClick={() => onSelectTab(tab.id)}
              onContextMenu={(e) => {
                e.preventDefault();
                e.stopPropagation();
                setTabContextMenu({ x: e.clientX, y: e.clientY, tabId: tab.id });
              }}
              title={
                isMissing
                  ? `${tab.path || tab.title} (Original file missing on disk — unsaved recovery active)`
                  : `${tab.path || tab.title}${tab.isModified ? ' (Modified)' : ''}`
              }
              className={`group relative flex items-center space-x-1.5 px-2.5 py-1 text-xs cursor-pointer border-t-2 border-l border-r transition-all ${
                isActive
                  ? isDark
                    ? 'bg-[#1e1e1e] border-t-[#f59e0b] border-l-[#3e4044] border-r-[#3e4044] text-white font-semibold -mb-px pb-1.5'
                    : 'bg-white border-t-[#e67e22] border-l-[#b0b0b0] border-r-[#b0b0b0] text-gray-900 font-semibold -mb-px pb-1.5'
                  : isDark
                  ? 'bg-[#26282b] border-t-transparent border-l-[#323438] border-r-[#323438] text-gray-400 hover:bg-[#2d3034] hover:text-gray-200'
                  : 'bg-[#cecece] border-t-transparent border-l-[#bababa] border-r-[#bababa] text-gray-700 hover:bg-[#e2e2e2] hover:text-gray-900'
              }`}
              style={{ maxWidth: '220px' }}
            >
              {/* Notepad++ Save State Disk/Status Icon */}
              <span className="flex-shrink-0 flex items-center">
                {isMissing ? (
                  <AlertTriangle className="w-3 h-3 text-red-500" />
                ) : tab.isModified ? (
                  <Save className="w-3 h-3 text-red-500 fill-red-500/20" />
                ) : tab.language === 'java' || tab.language === 'json' || tab.language === 'xml' ? (
                  <FileCode className="w-3 h-3 text-blue-600 dark:text-blue-400" />
                ) : (
                  <FileText className="w-3 h-3 text-blue-600 dark:text-blue-400" />
                )}
              </span>

              {/* Filename */}
              <span className="truncate flex-1 font-mono text-[11px]">
                {tab.title}
                {tab.isModified ? ' *' : ''}
              </span>

              {/* Close button */}
              <button
                onClick={(e) => onCloseTab(tab.id, e)}
                className={`w-4 h-4 rounded-sm flex items-center justify-center transition-colors ${
                  isActive
                    ? 'opacity-90 hover:bg-red-500 hover:text-white'
                    : 'opacity-60 group-hover:opacity-100 hover:bg-red-500 hover:text-white'
                }`}
                aria-label={`Close ${tab.title}`}
              >
                <X className="w-3 h-3" />
              </button>
            </div>
          );
        })}

        {/* New Tab Button */}
        <button
          onClick={onNewTab}
          title="New Document (⌘N)"
          className={`p-1 mb-0.5 ml-1 rounded hover:bg-black/10 dark:hover:bg-white/10 text-gray-600 dark:text-gray-400 transition-colors`}
          aria-label="Add new tab"
        >
          <Plus className="w-3.5 h-3.5" />
        </button>
      </div>

      {/* Tab Right-Click Context Menu */}
      {tabContextMenu && (
        <div
          onClick={(e) => e.stopPropagation()}
          className={`fixed z-50 w-52 py-1 rounded shadow-xl border text-xs font-sans ${
            isDark
              ? 'bg-[#2b2d30] border-[#45484c] text-gray-200'
              : 'bg-[#f8f8f8] border-[#c4c4c4] text-gray-800'
          }`}
          style={{ left: `${tabContextMenu.x}px`, top: `${tabContextMenu.y}px` }}
        >
          <button
            onClick={() => {
              onCloseTab(tabContextMenu.tabId);
              setTabContextMenu(null);
            }}
            className="w-full px-3 py-1.5 text-left hover:bg-blue-600 hover:text-white flex justify-between"
          >
            <span>Close</span>
            <span className="text-[10px] opacity-75 font-mono">⌘W</span>
          </button>
          {onCloseOtherTabs && (
            <button
              onClick={() => {
                onCloseOtherTabs(tabContextMenu.tabId);
                setTabContextMenu(null);
              }}
              className="w-full px-3 py-1.5 text-left hover:bg-blue-600 hover:text-white"
            >
              Close All BUT This
            </button>
          )}
          {onSaveTab && (
            <button
              onClick={() => {
                onSaveTab(tabContextMenu.tabId);
                setTabContextMenu(null);
              }}
              className="w-full px-3 py-1.5 text-left hover:bg-blue-600 hover:text-white flex justify-between"
            >
              <span>Save</span>
              <span className="text-[10px] opacity-75 font-mono">⌘S</span>
            </button>
          )}
          {onOpenTerminalAtTab && (
            <>
              <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
              <button
                onClick={() => {
                  onOpenTerminalAtTab(tabContextMenu.tabId);
                  setTabContextMenu(null);
                }}
                className="w-full px-3 py-1.5 text-left hover:bg-blue-600 hover:text-white"
              >
                Open Containing Folder in Terminal
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
};
