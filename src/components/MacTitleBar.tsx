import React from 'react';
import {
  FilePlus,
  FolderOpen,
  Save,
  Files,
  FileX,
  Scissors,
  Copy,
  Clipboard,
  Undo2,
  Redo2,
  Search,
  Replace,
  ZoomIn,
  ZoomOut,
  WrapText,
  Pilcrow,
  Play,
  Columns,
  Terminal,
  Settings,
  Download,
  Sidebar as SidebarIcon,
} from 'lucide-react';

interface MacTitleBarProps {
  activeTitle: string;
  activePath?: string;
  isModified: boolean;
  isDark: boolean;
  isFullscreen: boolean;
  canUndo?: boolean;
  canRedo?: boolean;
  wordWrap?: boolean;
  showWhitespace?: boolean;
  isExecutingFile?: boolean;
  onToggleFullscreen: () => void;
  onNewFile: () => void;
  onOpenFile: () => void;
  onSaveFile: () => void;
  onSaveAll: () => void;
  onCloseTab?: () => void;
  onUndo: () => void;
  onRedo: () => void;
  onCut: () => void;
  onCopy: () => void;
  onPaste: () => void;
  onOpenSearch: () => void;
  onOpenReplace?: () => void;
  onZoomIn?: () => void;
  onZoomOut?: () => void;
  onToggleWordWrap?: () => void;
  onToggleWhitespace?: () => void;
  onRunFile?: () => void;
  onToggleSplit: () => void;
  onToggleTerminal: () => void;
  onToggleSidebar: () => void;
  onOpenSettings: () => void;
  onOpenExport: () => void;
}

export const MacTitleBar: React.FC<MacTitleBarProps> = ({
  activeTitle,
  activePath,
  isModified,
  isDark,
  onToggleFullscreen,
  onCloseTab,
  onToggleSidebar,
  onOpenExport,
}) => {
  return (
    <div
      className={`h-7 px-3 flex items-center justify-between select-none border-b text-xs transition-colors ${
        isDark
          ? 'bg-[#252629] border-[#18191b] text-gray-300'
          : 'bg-[#e4e4e4] border-[#c8c8c8] text-gray-800'
      }`}
    >
      {/* Left: macOS Window Controls */}
      <div className="flex items-center space-x-2">
        <div className="flex items-center space-x-1.5 mr-1">
          <button
            onClick={() => onCloseTab && onCloseTab()}
            title="Close Active Document (⌘W)"
            className="w-3 h-3 rounded-full bg-[#ff5f56] border border-[#e0443e] hover:brightness-90 transition-all flex items-center justify-center group"
            aria-label="Close active document"
          >
            <span className="opacity-0 group-hover:opacity-100 text-[8px] text-black font-bold leading-none">×</span>
          </button>
          <button
            onClick={onToggleSidebar}
            title="Toggle Sidebar (⌘B)"
            className="w-3 h-3 rounded-full bg-[#ffbd2e] border border-[#dea123] hover:brightness-90 transition-all flex items-center justify-center group"
            aria-label="Toggle sidebar"
          >
            <span className="opacity-0 group-hover:opacity-100 text-[8px] text-black font-bold leading-none">−</span>
          </button>
          <button
            onClick={onToggleFullscreen}
            title="Toggle Fullscreen"
            className="w-3 h-3 rounded-full bg-[#27c93f] border border-[#1aab29] hover:brightness-90 transition-all flex items-center justify-center group"
            aria-label="Zoom window"
          >
            <span className="opacity-0 group-hover:opacity-100 text-[7px] text-black font-bold leading-none">+</span>
          </button>
        </div>

        <span className="font-mono font-bold tracking-tight text-[11px] text-emerald-700 dark:text-emerald-400">
          CodePad++
        </span>
      </div>

      {/* Center: Classic Notepad++ Window Title Format: [path/title * - CodePad++] */}
      <div className="flex items-center space-x-1.5 truncate max-w-[520px] font-mono text-[11px]">
        {isModified && (
          <span className="w-2 h-2 rounded-full bg-red-500 flex-shrink-0" title="Unsaved changes" />
        )}
        <span className="truncate">
          {activePath || activeTitle}
          {isModified ? ' *' : ''} — CodePad++
        </span>
      </div>

      {/* Right: Export Native App Bundle */}
      <div className="flex items-center space-x-1.5">
        <button
          onClick={onOpenExport}
          title="Export macOS .app & .dmg"
          className={`px-2 py-0.5 text-[10px] font-medium rounded border flex items-center space-x-1 transition-colors ${
            isDark
              ? 'bg-[#323438] hover:bg-[#3e4146] border-[#484b51] text-gray-200'
              : 'bg-[#f4f4f4] hover:bg-white border-[#bcbcbc] text-gray-800'
          }`}
          aria-label="Export macOS Application"
        >
          <Download className="w-2.5 h-2.5" />
          <span className="hidden sm:inline">macOS .app</span>
        </button>
      </div>
    </div>
  );
};

/**
 * Compact Notepad++ Classic Icon Toolbar positioned directly under the Menu Bar
 */
export const NppIconToolbar: React.FC<MacTitleBarProps> = ({
  isModified,
  isDark,
  canUndo = false,
  canRedo = false,
  wordWrap = false,
  showWhitespace = false,
  isExecutingFile = false,
  onNewFile,
  onOpenFile,
  onSaveFile,
  onSaveAll,
  onCloseTab,
  onUndo,
  onRedo,
  onCut,
  onCopy,
  onPaste,
  onOpenSearch,
  onOpenReplace,
  onZoomIn,
  onZoomOut,
  onToggleWordWrap,
  onToggleWhitespace,
  onRunFile,
  onToggleSplit,
  onToggleTerminal,
  onToggleSidebar,
  onOpenSettings,
}) => {
  const btnBase = `p-1 rounded transition-colors flex items-center justify-center ${
    isDark
      ? 'hover:bg-[#3c3f43] text-gray-200 disabled:opacity-30 disabled:hover:bg-transparent'
      : 'hover:bg-[#d8d8d8] text-gray-800 disabled:opacity-35 disabled:hover:bg-transparent'
  }`;

  const activeToggle = isDark
    ? 'bg-blue-600/30 text-blue-300 border border-blue-500/50'
    : 'bg-blue-600/15 text-blue-800 border border-blue-600/40';

  const sep = (
    <div className={`h-4 w-px mx-1 flex-shrink-0 ${isDark ? 'bg-[#3c3f43]' : 'bg-[#c6c6c6]'}`} />
  );

  return (
    <div
      className={`h-8 px-2 flex items-center space-x-0.5 select-none border-b overflow-x-auto no-scrollbar ${
        isDark
          ? 'bg-[#2b2d30] border-[#1e1f22] text-gray-200'
          : 'bg-[#f0f0f0] border-[#cfcfcf] text-gray-800'
      }`}
      role="toolbar"
      aria-label="Notepad++ Standard Toolbar"
    >
      {/* File Operations */}
      <button onClick={onNewFile} title="New (⌘N)" className={btnBase} aria-label="New File">
        <FilePlus className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
      </button>
      <button onClick={onOpenFile} title="Open... (⌘O)" className={btnBase} aria-label="Open File">
        <FolderOpen className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
      </button>
      <button
        onClick={onSaveFile}
        title="Save (⌘S)"
        className={`${btnBase} ${isModified ? 'text-blue-600 dark:text-blue-400' : ''}`}
        aria-label="Save File"
      >
        <Save className="w-3.5 h-3.5" />
      </button>
      <button onClick={onSaveAll} title="Save All (⌥⌘S)" className={btnBase} aria-label="Save All Files">
        <Files className="w-3.5 h-3.5" />
      </button>
      {onCloseTab && (
        <button onClick={onCloseTab} title="Close Current Document (⌘W)" className={btnBase} aria-label="Close Active Document">
          <FileX className="w-3.5 h-3.5 text-red-600 dark:text-red-400" />
        </button>
      )}

      {sep}

      {/* Clipboard Operations */}
      <button onClick={onCut} title="Cut (⌘X)" className={btnBase} aria-label="Cut">
        <Scissors className="w-3.5 h-3.5" />
      </button>
      <button onClick={onCopy} title="Copy (⌘C)" className={btnBase} aria-label="Copy">
        <Copy className="w-3.5 h-3.5" />
      </button>
      <button onClick={onPaste} title="Paste (⌘V)" className={btnBase} aria-label="Paste">
        <Clipboard className="w-3.5 h-3.5" />
      </button>

      {sep}

      {/* Undo / Redo (Priority 2) */}
      <button
        onClick={onUndo}
        disabled={!canUndo}
        title="Undo (⌘Z)"
        className={btnBase}
        aria-label="Undo"
      >
        <Undo2 className="w-3.5 h-3.5" />
      </button>
      <button
        onClick={onRedo}
        disabled={!canRedo}
        title="Redo (⇧⌘Z)"
        className={btnBase}
        aria-label="Redo"
      >
        <Redo2 className="w-3.5 h-3.5" />
      </button>

      {sep}

      {/* Search & Replace */}
      <button onClick={onOpenSearch} title="Find... (⌘F)" className={btnBase} aria-label="Find">
        <Search className="w-3.5 h-3.5 text-blue-600 dark:text-blue-400" />
      </button>
      {onOpenReplace && (
        <button onClick={onOpenReplace} title="Replace... (⌘H)" className={btnBase} aria-label="Replace">
          <Replace className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
        </button>
      )}

      {sep}

      {/* Zoom & View Formatting */}
      {onZoomIn && (
        <button onClick={onZoomIn} title="Zoom In (⌘+)" className={btnBase} aria-label="Zoom In">
          <ZoomIn className="w-3.5 h-3.5" />
        </button>
      )}
      {onZoomOut && (
        <button onClick={onZoomOut} title="Zoom Out (⌘-)" className={btnBase} aria-label="Zoom Out">
          <ZoomOut className="w-3.5 h-3.5" />
        </button>
      )}
      {onToggleWordWrap && (
        <button
          onClick={onToggleWordWrap}
          title="Word Wrap"
          className={`${btnBase} ${wordWrap ? activeToggle : ''}`}
          aria-label="Toggle Word Wrap"
        >
          <WrapText className="w-3.5 h-3.5" />
        </button>
      )}
      {onToggleWhitespace && (
        <button
          onClick={onToggleWhitespace}
          title="Show All Characters (Spaces & Tabs)"
          className={`${btnBase} ${showWhitespace ? activeToggle : ''}`}
          aria-label="Show Whitespace Characters"
        >
          <Pilcrow className="w-3.5 h-3.5" />
        </button>
      )}

      {sep}

      {/* Run Source Code Directly (Priority 4) */}
      {onRunFile && (
        <button
          onClick={onRunFile}
          title="Run Current File (F5)"
          className={`px-2 py-0.5 rounded text-[11px] font-semibold flex items-center space-x-1 transition-colors ${
            isExecutingFile
              ? 'bg-amber-600 text-white animate-pulse'
              : isDark
              ? 'bg-emerald-700/80 hover:bg-emerald-600 text-white'
              : 'bg-emerald-700 hover:bg-emerald-800 text-white'
          }`}
          aria-label="Run File"
        >
          <Play className="w-3 h-3 fill-current" />
          <span>Run File</span>
        </button>
      )}

      {sep}

      {/* Workspace Panels */}
      <button
        onClick={onToggleSidebar}
        title="Toggle Document & Project Sidebar (⌘B)"
        className={btnBase}
        aria-label="Toggle Project Sidebar"
      >
        <SidebarIcon className="w-3.5 h-3.5" />
      </button>
      <button
        onClick={onToggleSplit}
        title="Clone / Move to Other View (Split View)"
        className={btnBase}
        aria-label="Toggle Split View"
      >
        <Columns className="w-3.5 h-3.5" />
      </button>
      <button
        onClick={onToggleTerminal}
        title="Toggle Integrated Terminal (^`)"
        className={btnBase}
        aria-label="Toggle Terminal"
      >
        <Terminal className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
      </button>
      <button
        onClick={onOpenSettings}
        title="Preferences... (⌘,)"
        className={btnBase}
        aria-label="Editor Settings"
      >
        <Settings className="w-3.5 h-3.5" />
      </button>
    </div>
  );
};
