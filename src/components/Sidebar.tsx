import React, { useState, useEffect } from 'react';
import {
  Folder,
  FileCode,
  FileText,
  ChevronDown,
  ChevronRight,
  Bookmark,
  Files,
  Boxes,
  RefreshCw,
  Plus,
} from 'lucide-react';
import { TabItem } from '../types';
import { PluginManifest } from '../lib/pluginSystem';

interface SidebarProps {
  isVisible: boolean;
  isDark: boolean;
  tabs: TabItem[];
  activeTabId: string;
  plugins: PluginManifest[];
  onSelectTab: (id: string) => void;
  onJumpToLine: (line: number) => void;
  onOpenFileByPath: (path: string) => void;
  onNewFile: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  isVisible,
  isDark,
  tabs,
  activeTabId,
  plugins,
  onSelectTab,
  onJumpToLine,
  onOpenFileByPath,
  onNewFile,
}) => {
  const [activeSection, setActiveSection] = useState<'files' | 'open' | 'bookmarks' | 'plugins'>('files');
  const [fileTree, setFileTree] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isVisible) {
      fetchFileTree();
    }
  }, [isVisible]);

  const fetchFileTree = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/files/tree');
      if (res.ok) {
        const data = await res.json();
        setFileTree(data.tree || []);
      }
    } catch {
      // Fallback
    } finally {
      setLoading(false);
    }
  };

  if (!isVisible) return null;

  const bg = isDark ? 'bg-[#181818] border-[#2d2d2d] text-gray-300' : 'bg-[#f0f0f0] border-[#d4d4d4] text-gray-700';
  const activeTabDoc = tabs.find((t) => t.id === activeTabId);

  const renderTreeItem = (item: any, depth: number = 0) => {
    const isDir = item.type === 'directory';
    return (
      <div key={item.path || item.name} style={{ paddingLeft: `${depth * 12 + 6}px` }}>
        <div
          onClick={() => {
            if (!isDir) onOpenFileByPath(item.path);
          }}
          className={`flex items-center space-x-1.5 py-1 px-1.5 rounded cursor-pointer text-xs truncate transition-colors ${
            isDark ? 'hover:bg-gray-700/50' : 'hover:bg-gray-200'
          }`}
        >
          {isDir ? (
            <Folder className="w-3.5 h-3.5 text-blue-400 flex-shrink-0" />
          ) : item.name.endsWith('.java') ? (
            <span className="text-[11px] flex-shrink-0">☕</span>
          ) : item.name.endsWith('.swift') ? (
            <span className="text-[11px] flex-shrink-0">🐦</span>
          ) : (
            <FileText className="w-3.5 h-3.5 text-gray-400 flex-shrink-0" />
          )}
          <span className="truncate">{item.name}</span>
        </div>
        {isDir && item.children && item.children.map((child: any) => renderTreeItem(child, depth + 1))}
      </div>
    );
  };

  return (
    <div className={`w-60 border-r flex flex-col h-full select-none text-xs ${bg}`}>
      {/* Sidebar Header Sections */}
      <div className={`flex border-b text-[11px] font-medium ${isDark ? 'border-[#2d2d2d] bg-[#222222]' : 'border-[#d4d4d4] bg-[#e4e4e4]'}`}>
        <button
          onClick={() => setActiveSection('files')}
          className={`flex-1 py-1.5 text-center transition-colors ${activeSection === 'files' ? 'font-bold text-blue-500 border-b-2 border-blue-500' : 'text-gray-500'}`}
          title="Project Files"
        >
          Files
        </button>
        <button
          onClick={() => setActiveSection('open')}
          className={`flex-1 py-1.5 text-center transition-colors ${activeSection === 'open' ? 'font-bold text-blue-500 border-b-2 border-blue-500' : 'text-gray-500'}`}
          title="Open Documents"
        >
          Open ({tabs.length})
        </button>
        <button
          onClick={() => setActiveSection('bookmarks')}
          className={`flex-1 py-1.5 text-center transition-colors ${activeSection === 'bookmarks' ? 'font-bold text-blue-500 border-b-2 border-blue-500' : 'text-gray-500'}`}
          title="Bookmarks"
        >
          Marks ({activeTabDoc?.bookmarks.length || 0})
        </button>
        <button
          onClick={() => setActiveSection('plugins')}
          className={`flex-1 py-1.5 text-center transition-colors ${activeSection === 'plugins' ? 'font-bold text-blue-500 border-b-2 border-blue-500' : 'text-gray-500'}`}
          title="Installed Plugins"
        >
          Plugins
        </button>
      </div>

      {/* Section Content */}
      <div className="flex-1 overflow-y-auto p-2">
        {/* FILES */}
        {activeSection === 'files' && (
          <div>
            <div className="flex items-center justify-between pb-2 mb-2 border-b border-gray-400/20">
              <span className="font-bold text-[11px] uppercase text-gray-500 tracking-wider">Workspace</span>
              <div className="flex items-center space-x-1">
                <button onClick={onNewFile} title="New File" className="p-1 hover:bg-black/10 rounded">
                  <Plus className="w-3.5 h-3.5" />
                </button>
                <button onClick={fetchFileTree} title="Refresh Tree" className="p-1 hover:bg-black/10 rounded">
                  <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
                </button>
              </div>
            </div>

            {fileTree.length > 0 ? (
              <div className="space-y-0.5">{fileTree.map((item) => renderTreeItem(item))}</div>
            ) : (
              <div className="space-y-1">
                {tabs.map((t) => (
                  <div
                    key={t.id}
                    onClick={() => onSelectTab(t.id)}
                    className="flex items-center space-x-1.5 py-1 px-1.5 rounded cursor-pointer hover:bg-black/10"
                  >
                    <FileCode className="w-3.5 h-3.5 text-blue-500" />
                    <span className="truncate">{t.title}</span>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* OPEN DOCUMENTS */}
        {activeSection === 'open' && (
          <div className="space-y-1">
            <div className="font-bold text-[11px] uppercase text-gray-500 tracking-wider pb-1 mb-1 border-b border-gray-400/20">
              Open Tabs
            </div>
            {tabs.map((tab) => {
              const isActive = tab.id === activeTabId;
              return (
                <div
                  key={tab.id}
                  onClick={() => onSelectTab(tab.id)}
                  className={`flex items-center justify-between px-2 py-1.5 rounded cursor-pointer transition-colors ${
                    isActive
                      ? 'bg-blue-600 text-white font-medium'
                      : isDark
                      ? 'hover:bg-gray-700/50 text-gray-300'
                      : 'hover:bg-gray-200 text-gray-800'
                  }`}
                >
                  <span className="truncate">{tab.title}</span>
                  {tab.isModified && <span className="w-2 h-2 rounded-full bg-amber-400" />}
                </div>
              );
            })}
          </div>
        )}

        {/* BOOKMARKS */}
        {activeSection === 'bookmarks' && (
          <div className="space-y-2">
            <div className="font-bold text-[11px] uppercase text-gray-500 tracking-wider pb-1 mb-1 border-b border-gray-400/20">
              Bookmarked Lines in {activeTabDoc?.title}
            </div>
            {activeTabDoc && activeTabDoc.bookmarks.length > 0 ? (
              activeTabDoc.bookmarks.map((lineNum) => {
                const lineContent = activeTabDoc.content.split('\n')[lineNum - 1] || '';
                return (
                  <div
                    key={lineNum}
                    onClick={() => onJumpToLine(lineNum)}
                    className="p-1.5 rounded border border-blue-500/20 hover:border-blue-500 cursor-pointer bg-blue-500/5 transition-colors"
                  >
                    <div className="flex items-center justify-between text-blue-500 font-bold">
                      <span className="flex items-center space-x-1">
                        <Bookmark className="w-3 h-3 fill-blue-500" />
                        <span>Line {lineNum}</span>
                      </span>
                    </div>
                    <div className="text-[11px] text-gray-500 font-mono truncate mt-0.5">
                      {lineContent.trim() || '(empty line)'}
                    </div>
                  </div>
                );
              })
            ) : (
              <div className="text-gray-400 italic p-2 text-center">
                No bookmarks in this file. Click the gutter or press F2 to bookmark lines.
              </div>
            )}
          </div>
        )}

        {/* PLUGINS */}
        {activeSection === 'plugins' && (
          <div className="space-y-2">
            <div className="font-bold text-[11px] uppercase text-gray-500 tracking-wider pb-1 mb-1 border-b border-gray-400/20">
              Active Plugins ({plugins.filter((p) => p.enabled).length})
            </div>
            {plugins.map((p) => (
              <div
                key={p.id}
                className="p-2 rounded border border-gray-400/20 bg-black/5 dark:bg-white/5 space-y-1"
              >
                <div className="flex items-center justify-between">
                  <span className="font-bold text-xs truncate">{p.name}</span>
                  <span className="text-[10px] text-emerald-500 font-semibold">v{p.version}</span>
                </div>
                <div className="text-[11px] text-gray-400 leading-tight">{p.description}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
