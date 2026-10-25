import React, { useState, useRef, useEffect } from 'react';
import { SUPPORTED_LANGUAGES } from '../lib/languageEngine';
import { TextEncoding, LineEnding } from '../lib/encoding';

interface MacMenuBarProps {
  isDark: boolean;
  currentLanguage: string;
  currentEncoding: TextEncoding;
  currentLineEnding: LineEnding;
  wordWrap: boolean;
  showWhitespace: boolean;
  onNewFile: () => void;
  onOpenFile: () => void;
  onSaveFile: () => void;
  onSaveAll: () => void;
  onCloseTab: () => void;
  onUndo: () => void;
  onRedo: () => void;
  onCut: () => void;
  onCopy: () => void;
  onPaste: () => void;
  onSelectAll: () => void;
  onDuplicateLine: () => void;
  onDeleteLine: () => void;
  onMoveLineUp: () => void;
  onMoveLineDown: () => void;
  onJoinLines: () => void;
  onToggleComment: () => void;
  onConvertTabsToSpaces: () => void;
  onConvertSpacesToTabs: () => void;
  onOpenFind: () => void;
  onOpenReplace: () => void;
  onOpenMark: () => void;
  onGoToLine: () => void;
  onNextBookmark: () => void;
  onPrevBookmark: () => void;
  onClearBookmarks: () => void;
  onToggleWordWrap: () => void;
  onToggleWhitespace: () => void;
  onSetEncoding: (enc: TextEncoding) => void;
  onSetLineEnding: (ending: LineEnding) => void;
  onSetLanguage: (langId: string) => void;
  onOpenSettings: () => void;
  onOpenPluginManager: () => void;
  onRunPluginCommand: (cmdId: string) => void;
  onOpenJavaTools: () => void;
  onOpenGitPanel: () => void;
  onOpenTerminal: () => void;
  onOpenExport: () => void;
  canUndo?: boolean;
  canRedo?: boolean;
  onRunFile?: () => void;
  onOpenTerminalHere?: () => void;
}

export const MacMenuBar: React.FC<MacMenuBarProps> = ({
  isDark,
  currentLanguage,
  currentEncoding,
  currentLineEnding,
  wordWrap,
  showWhitespace,
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
  onSelectAll,
  onDuplicateLine,
  onDeleteLine,
  onMoveLineUp,
  onMoveLineDown,
  onJoinLines,
  onToggleComment,
  onConvertTabsToSpaces,
  onConvertSpacesToTabs,
  onOpenFind,
  onOpenReplace,
  onOpenMark,
  onGoToLine,
  onNextBookmark,
  onPrevBookmark,
  onClearBookmarks,
  onToggleWordWrap,
  onToggleWhitespace,
  onSetEncoding,
  onSetLineEnding,
  onSetLanguage,
  onOpenSettings,
  onOpenPluginManager,
  onRunPluginCommand,
  onOpenJavaTools,
  onOpenGitPanel,
  onOpenTerminal,
  onOpenExport,
  canUndo = true,
  canRedo = true,
  onRunFile,
  onOpenTerminalHere,
}) => {
  const [openMenu, setOpenMenu] = useState<string | null>(null);
  const menuBarRef = useRef<HTMLDivElement>(null);

  // Close menus on outside click
  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (menuBarRef.current && !menuBarRef.current.contains(e.target as Node)) {
        setOpenMenu(null);
      }
    }
    window.addEventListener('mousedown', handleClickOutside);
    return () => window.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleMenuClick = (menu: string) => {
    setOpenMenu(openMenu === menu ? null : menu);
  };

  const handleAction = (action: () => void) => {
    action();
    setOpenMenu(null);
  };

  const dropdownBg = isDark
    ? 'bg-[#2b2d30] border-[#1e1f22] text-gray-200 shadow-2xl'
    : 'bg-[#f6f6f6] border-[#d4d4d4] text-gray-800 shadow-xl';

  const hoverItem = isDark ? 'hover:bg-blue-600 hover:text-white' : 'hover:bg-blue-500 hover:text-white';

  return (
    <div
      ref={menuBarRef}
      className={`h-7 px-3 flex items-center space-x-1 text-xs select-none border-b transition-colors relative z-40 ${
        isDark
          ? 'bg-[#252526] border-[#1e1f22] text-gray-300'
          : 'bg-[#f0f0f0] border-[#d4d4d4] text-gray-700'
      }`}
    >
      {/* File */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('file')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'file' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          File
        </button>
        {openMenu === 'file' && (
          <div className={`absolute left-0 top-full mt-1 w-56 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onNewFile)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>New</span>
              <span className="text-gray-400">⌘N</span>
            </button>
            <button
              onClick={() => handleAction(onOpenFile)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Open...</span>
              <span className="text-gray-400">⌘O</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onSaveFile)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Save</span>
              <span className="text-gray-400">⌘S</span>
            </button>
            <button
              onClick={() => handleAction(onSaveAll)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Save All</span>
              <span className="text-gray-400">⌥⌘S</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onCloseTab)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Close Tab</span>
              <span className="text-gray-400">⌘W</span>
            </button>
          </div>
        )}
      </div>

      {/* Edit */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('edit')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'edit' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Edit
        </button>
        {openMenu === 'edit' && (
          <div className={`absolute left-0 top-full mt-1 w-64 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => canUndo && handleAction(onUndo)}
              disabled={!canUndo}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${
                canUndo ? hoverItem : 'opacity-40 cursor-not-allowed'
              }`}
            >
              <span>Undo</span>
              <span className="text-gray-400">⌘Z</span>
            </button>
            <button
              onClick={() => canRedo && handleAction(onRedo)}
              disabled={!canRedo}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${
                canRedo ? hoverItem : 'opacity-40 cursor-not-allowed'
              }`}
            >
              <span>Redo</span>
              <span className="text-gray-400">⇧⌘Z</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onCut)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Cut</span>
              <span className="text-gray-400">⌘X</span>
            </button>
            <button
              onClick={() => handleAction(onCopy)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Copy</span>
              <span className="text-gray-400">⌘C</span>
            </button>
            <button
              onClick={() => handleAction(onPaste)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Paste</span>
              <span className="text-gray-400">⌘V</span>
            </button>
            <button
              onClick={() => handleAction(onSelectAll)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Select All</span>
              <span className="text-gray-400">⌘A</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onDuplicateLine)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Duplicate Current Line</span>
              <span className="text-gray-400">⌘D</span>
            </button>
            <button
              onClick={() => handleAction(onDeleteLine)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Delete Current Line</span>
              <span className="text-gray-400">⇧⌘K</span>
            </button>
            <button
              onClick={() => handleAction(onMoveLineUp)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Move Line Up</span>
              <span className="text-gray-400">⌥↑</span>
            </button>
            <button
              onClick={() => handleAction(onMoveLineDown)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Move Line Down</span>
              <span className="text-gray-400">⌥↓</span>
            </button>
            <button
              onClick={() => handleAction(onJoinLines)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Join Lines</span>
              <span className="text-gray-400">⌘J</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onToggleComment)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Toggle Line Comment</span>
              <span className="text-gray-400">⌘/</span>
            </button>
            <button
              onClick={() => handleAction(onConvertTabsToSpaces)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Convert Tabs to Spaces</span>
            </button>
            <button
              onClick={() => handleAction(onConvertSpacesToTabs)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Convert Spaces to Tabs</span>
            </button>
          </div>
        )}
      </div>

      {/* Search */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('search')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'search' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Search
        </button>
        {openMenu === 'search' && (
          <div className={`absolute left-0 top-full mt-1 w-60 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onOpenFind)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Find...</span>
              <span className="text-gray-400">⌘F</span>
            </button>
            <button
              onClick={() => handleAction(onOpenReplace)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Replace...</span>
              <span className="text-gray-400">⌘H</span>
            </button>
            <button
              onClick={() => handleAction(onOpenMark)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Mark Lines...</span>
              <span className="text-gray-400">⌘M</span>
            </button>
            <button
              onClick={() => handleAction(onGoToLine)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Go to Line...</span>
              <span className="text-gray-400">⌘G</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onNextBookmark)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Next Bookmark</span>
              <span className="text-gray-400">F2</span>
            </button>
            <button
              onClick={() => handleAction(onPrevBookmark)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Previous Bookmark</span>
              <span className="text-gray-400">⇧F2</span>
            </button>
            <button
              onClick={() => handleAction(onClearBookmarks)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Clear All Bookmarks</span>
            </button>
          </div>
        )}
      </div>

      {/* View */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('view')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'view' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          View
        </button>
        {openMenu === 'view' && (
          <div className={`absolute left-0 top-full mt-1 w-56 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onToggleWordWrap)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Word Wrap</span>
              <span>{wordWrap ? '✓' : ''}</span>
            </button>
            <button
              onClick={() => handleAction(onToggleWhitespace)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Show Whitespace</span>
              <span>{showWhitespace ? '✓' : ''}</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onOpenTerminal)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Developer Terminal</span>
              <span className="text-gray-400">^~</span>
            </button>
          </div>
        )}
      </div>

      {/* Encoding */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('encoding')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'encoding' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Encoding
        </button>
        {openMenu === 'encoding' && (
          <div className={`absolute left-0 top-full mt-1 w-64 rounded-md border p-1 ${dropdownBg}`}>
            <div className="px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-gray-500">
              Character Encoding
            </div>
            {(['UTF-8', 'UTF-8-BOM', 'UTF-16LE', 'UTF-16BE', 'ASCII'] as TextEncoding[]).map((enc) => (
              <button
                key={enc}
                onClick={() => handleAction(() => onSetEncoding(enc))}
                className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
              >
                <span>{enc}</span>
                <span>{currentEncoding === enc ? '✓' : ''}</span>
              </button>
            ))}
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <div className="px-2 py-1 text-[10px] font-bold uppercase tracking-wider text-gray-500">
              Line Endings Format
            </div>
            <button
              onClick={() => handleAction(() => onSetLineEnding('LF'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Unix / macOS (LF)</span>
              <span>{currentLineEnding === 'LF' ? '✓' : ''}</span>
            </button>
            <button
              onClick={() => handleAction(() => onSetLineEnding('CRLF'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Windows (CRLF)</span>
              <span>{currentLineEnding === 'CRLF' ? '✓' : ''}</span>
            </button>
            <button
              onClick={() => handleAction(() => onSetLineEnding('CR'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Classic Mac (CR)</span>
              <span>{currentLineEnding === 'CR' ? '✓' : ''}</span>
            </button>
          </div>
        )}
      </div>

      {/* Language */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('language')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'language' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Language
        </button>
        {openMenu === 'language' && (
          <div className={`absolute left-0 top-full mt-1 w-56 max-h-80 overflow-y-auto rounded-md border p-1 ${dropdownBg}`}>
            {SUPPORTED_LANGUAGES.map((lang) => (
              <button
                key={lang.id}
                onClick={() => handleAction(() => onSetLanguage(lang.id))}
                className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
              >
                <span>{lang.name}</span>
                <span>{currentLanguage === lang.id ? '✓' : ''}</span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Settings */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('settings')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'settings' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Settings
        </button>
        {openMenu === 'settings' && (
          <div className={`absolute left-0 top-full mt-1 w-56 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onOpenSettings)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Preferences...</span>
              <span className="text-gray-400">⌘,</span>
            </button>
            <button
              onClick={() => handleAction(onOpenSettings)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Style Configurator (Theme)...</span>
            </button>
            <button
              onClick={() => handleAction(onOpenSettings)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Shortcut Mapper...</span>
            </button>
          </div>
        )}
      </div>

      {/* Tools */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('tools')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'tools' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Tools
        </button>
        {openMenu === 'tools' && (
          <div className={`absolute left-0 top-full mt-1 w-64 rounded-md border p-1 ${dropdownBg}`}>
            <div className="px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-amber-500">
              ☕ Java & Spring Boot
            </div>
            <button
              onClick={() => handleAction(onOpenJavaTools)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Java Symbol Outline</span>
              <span className="text-gray-400">Outline</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('spring.controller'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Insert @RestController</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('spring.properties'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Insert application.properties</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <div className="px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-orange-500">
              🌿 Git Version Control
            </div>
            <button
              onClick={() => handleAction(onOpenGitPanel)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Git Status & Diffs</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <div className="px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-blue-500">
              Utility Tools
            </div>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('codec.base64.encode'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Base64 Encode Selection</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('codec.base64.decode'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Base64 Decode Selection</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('stats.count'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Document Statistics</span>
              <span className="text-gray-400">⇧⌘I</span>
            </button>
          </div>
        )}
      </div>

      {/* Macro */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('macro')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'macro' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Macro
        </button>
        {openMenu === 'macro' && (
          <div className={`absolute left-0 top-full mt-1 w-60 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('macro.record'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Start Recording</span>
              <span className="text-red-500">●</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('macro.stop'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Stop Recording</span>
              <span className="text-gray-400">■</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('macro.playback'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Playback Macro</span>
              <span className="text-emerald-500">▶</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(() => onRunPluginCommand('macro.playback'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Run a Macro Multiple Times...</span>
            </button>
          </div>
        )}
      </div>

      {/* Run */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('run')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'run' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Run
        </button>
        {openMenu === 'run' && (
          <div className={`absolute left-0 top-full mt-1 w-64 rounded-md border p-1 ${dropdownBg}`}>
            {onRunFile && (
              <button
                onClick={() => handleAction(onRunFile)}
                className={`w-full text-left px-2 py-1 rounded flex justify-between font-semibold text-emerald-600 dark:text-emerald-400 ${hoverItem}`}
              >
                <span>Run Current File</span>
                <span className="text-gray-400">F5</span>
              </button>
            )}
            {onOpenTerminalHere && (
              <button
                onClick={() => handleAction(onOpenTerminalHere)}
                className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
              >
                <span>Open Terminal Here</span>
                <span className="text-gray-400">^`</span>
              </button>
            )}
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onOpenTerminal)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Run in Developer Terminal</span>
              <span className="text-gray-400">^~</span>
            </button>
            <button
              onClick={() => handleAction(onOpenJavaTools)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Java & Spring Boot Runner</span>
            </button>
          </div>
        )}
      </div>

      {/* Plugins */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('plugins')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'plugins' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Plugins
        </button>
        {openMenu === 'plugins' && (
          <div className={`absolute left-0 top-full mt-1 w-64 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onOpenPluginManager)}
              className={`w-full text-left px-2 py-1 rounded font-semibold flex justify-between ${hoverItem}`}
            >
              <span>Plugin Manager...</span>
              <span>⚙️</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(() => onRunPluginCommand('json.format'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Format JSON</span>
              <span className="text-gray-400">⇧⌘F</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('json.minify'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Minify JSON</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('lines.sort.asc'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Sort Lines (A-Z)</span>
            </button>
            <button
              onClick={() => handleAction(() => onRunPluginCommand('lines.dedupe'))}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Remove Duplicate Lines</span>
            </button>
          </div>
        )}
      </div>

      {/* Window */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('window')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'window' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Window
        </button>
        {openMenu === 'window' && (
          <div className={`absolute left-0 top-full mt-1 w-56 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onCloseTab)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Close Tab</span>
              <span className="text-gray-400">⌘W</span>
            </button>
            <button
              onClick={() => handleAction(onCloseTab)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Close All</span>
            </button>
          </div>
        )}
      </div>

      {/* Help */}
      <div className="relative">
        <button
          onClick={() => handleMenuClick('help')}
          className={`px-2 py-0.5 rounded transition-colors ${
            openMenu === 'help' ? (isDark ? 'bg-gray-700' : 'bg-gray-300') : ''
          }`}
        >
          Help
        </button>
        {openMenu === 'help' && (
          <div className={`absolute left-0 top-full mt-1 w-64 rounded-md border p-1 ${dropdownBg}`}>
            <button
              onClick={() => handleAction(onOpenSettings)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>About CodePad++</span>
            </button>
            <button
              onClick={() => handleAction(onOpenSettings)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between ${hoverItem}`}
            >
              <span>Keyboard Shortcuts</span>
              <span className="text-gray-400">⌘?</span>
            </button>
            <div className={`my-1 border-t ${isDark ? 'border-gray-700' : 'border-gray-300'}`} />
            <button
              onClick={() => handleAction(onOpenExport)}
              className={`w-full text-left px-2 py-1 rounded flex justify-between text-emerald-600 dark:text-emerald-400 font-semibold ${hoverItem}`}
            >
              <span>Export Application (.dmg)</span>
              <span>📦</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
