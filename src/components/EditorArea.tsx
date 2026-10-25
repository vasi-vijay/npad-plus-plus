import React, { useRef, useEffect, useState, useMemo, useCallback } from 'react';
import { TabItem, EditorSettings } from '../types';
import { THEMES, ThemeDefinition } from '../lib/themeConfig';
import { tokenizeLine } from '../lib/syntaxTokenizer';
import {
  Bookmark,
  AlertCircle,
  AlertTriangle,
  Undo2,
  Redo2,
  Scissors,
  Copy,
  Clipboard,
  Search,
  Replace,
  Play,
  Terminal,
  CheckSquare,
} from 'lucide-react';
import { CodeDiagnostic } from '../lib/languageEngine';

interface EditorAreaProps {
  activeTab: TabItem;
  secondaryTab?: TabItem;
  isSplitView: boolean;
  settings: EditorSettings;
  diagnostics: CodeDiagnostic[];
  canUndo?: boolean;
  canRedo?: boolean;
  searchQuery?: string;
  onChangeContent: (
    content: string,
    meta?: { selectionStart?: number; selectionEnd?: number; label?: string; coalesce?: boolean }
  ) => void;
  onUpdateCursor: (line: number, col: number, selLength: number, selStart?: number, selEnd?: number) => void;
  onToggleBookmark: (lineNumber: number) => void;
  onUndo?: () => void;
  onRedo?: () => void;
  onOpenFind?: () => void;
  onOpenReplace?: () => void;
  onRunFile?: () => void;
  onOpenTerminalHere?: () => void;
}

interface GutterRowProps {
  lineNum: number;
  isCurrent: boolean;
  isBookmarked: boolean;
  diag?: CodeDiagnostic;
  lineItemHeight: number;
  activeLineBg: string;
  foreground: string;
  gutterFg: string;
  fontFamily: string;
  fontSize: number;
  onToggleBookmark: (lineNum: number) => void;
}

const MemoizedGutterRow = React.memo<GutterRowProps>(
  ({
    lineNum,
    isCurrent,
    isBookmarked,
    diag,
    lineItemHeight,
    activeLineBg,
    foreground,
    gutterFg,
    fontFamily,
    fontSize,
    onToggleBookmark,
  }) => {
    return (
      <div
        onClick={() => onToggleBookmark(lineNum)}
        className={`px-1.5 flex items-center justify-end space-x-1 cursor-pointer transition-colors ${
          isCurrent ? 'font-bold' : ''
        }`}
        style={{
          height: `${lineItemHeight}px`,
          backgroundColor: isCurrent ? activeLineBg : 'transparent',
          color: isCurrent ? foreground : gutterFg,
          fontFamily,
          fontSize: `${fontSize}px`,
        }}
        title={`Line ${lineNum} — Click to toggle bookmark (F2)`}
      >
        {diag && (
          <span title={diag.message}>
            {diag.severity === 'error' ? (
              <AlertCircle className="w-3 h-3 text-red-500" />
            ) : (
              <AlertTriangle className="w-3 h-3 text-amber-500" />
            )}
          </span>
        )}

        {isBookmarked ? (
          <Bookmark className="w-3 h-3 text-blue-500 fill-blue-500" />
        ) : (
          <span className="w-3" />
        )}

        <span className="tabular-nums" style={{ fontFamily, fontSize: `${fontSize}px` }}>
          {lineNum}
        </span>
      </div>
    );
  }
);

interface CodeLineProps {
  lineText: string;
  language: string;
  isCurrent: boolean;
  lineItemHeight: number;
  showWhitespace: boolean;
  theme: ThemeDefinition;
}

const MemoizedCodeLine = React.memo<CodeLineProps>(
  ({ lineText, language, isCurrent, lineItemHeight, showWhitespace, theme }) => {
    const tokens = useMemo(() => tokenizeLine(lineText, language), [lineText, language]);

    return (
      <div
        style={{
          minHeight: `${lineItemHeight}px`,
          lineHeight: `${lineItemHeight}px`,
          backgroundColor: isCurrent ? theme.styles.activeLineBg : 'transparent',
          fontFamily: 'inherit',
          fontSize: 'inherit',
        }}
      >
        {tokens.map((token, tIdx) => {
          let color = theme.styles.foreground;
          let fontWeight: string | undefined = undefined;

          switch (token.type) {
            case 'keyword':
              color = theme.styles.keywordColor;
              fontWeight = '600';
              break;
            case 'type':
              color = theme.styles.typeColor;
              fontWeight = '500';
              break;
            case 'string':
              color = theme.styles.stringColor;
              break;
            case 'comment':
              color = theme.styles.commentColor;
              break;
            case 'number':
              color = theme.styles.numberColor;
              break;
            case 'annotation':
              color = theme.styles.annotationColor;
              fontWeight = '600';
              break;
            case 'operator':
              color = theme.styles.operatorColor;
              break;
            default:
              color = theme.styles.foreground;
          }

          let displayText = token.text;
          if (showWhitespace) {
            displayText = displayText.replace(/ /g, '·').replace(/\t/g, '→   ');
          }

          return (
            <span
              key={tIdx}
              style={{
                color,
                fontWeight,
              }}
            >
              {displayText || '\u00A0'}
            </span>
          );
        })}
        {lineText.length === 0 && <span>&nbsp;</span>}
      </div>
    );
  }
);

export const EditorArea: React.FC<EditorAreaProps> = ({
  activeTab,
  secondaryTab,
  isSplitView,
  settings,
  diagnostics,
  canUndo = false,
  canRedo = false,
  onChangeContent,
  onUpdateCursor,
  onToggleBookmark,
  onUndo,
  onRedo,
  onOpenFind,
  onOpenReplace,
  onRunFile,
  onOpenTerminalHere,
}) => {
  const theme = THEMES[settings.theme] || THEMES['npp-classic'];
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const codeDisplayRef = useRef<HTMLDivElement>(null);
  const gutterRef = useRef<HTMLDivElement>(null);

  // Right-click context menu state
  const [contextMenu, setContextMenu] = useState<{ x: number; y: number } | null>(null);

  const lines = useMemo(() => (activeTab.content || '').split('\n'), [activeTab.content]);
  const lineItemHeight = Math.max(20, Math.round(settings.fontSize * 1.5));
  const isPlainOrMarkdown = activeTab.language === 'plaintext' || !activeTab.language;

  // Keep textarea selection synced when activeTab changes or undo/redo restores selection
  const lastTabIdRef = useRef<string>('');
  useEffect(() => {
    if (lastTabIdRef.current !== activeTab.id) {
      lastTabIdRef.current = activeTab.id;
      if (textareaRef.current) {
        textareaRef.current.focus();
        const safeStart = Math.min(activeTab.selectionStart || 0, activeTab.content.length);
        const safeEnd = Math.min(activeTab.selectionEnd || safeStart, activeTab.content.length);
        textareaRef.current.setSelectionRange(safeStart, safeEnd);
      }
    }
  }, [activeTab.id, activeTab.content.length, activeTab.selectionStart, activeTab.selectionEnd]);

  // Close context menu on outside click or Escape
  useEffect(() => {
    if (!contextMenu) return;
    const closeMenu = () => setContextMenu(null);
    const handleEsc = (e: KeyboardEvent) => {
      if (e.key === 'Escape') setContextMenu(null);
    };
    window.addEventListener('click', closeMenu);
    window.addEventListener('keydown', handleEsc);
    return () => {
      window.removeEventListener('click', closeMenu);
      window.removeEventListener('keydown', handleEsc);
    };
  }, [contextMenu]);

  // Sync scroll between textarea, syntax highlighting layer, and gutter
  const handleScroll = useCallback(() => {
    if (textareaRef.current) {
      const top = textareaRef.current.scrollTop;
      const left = textareaRef.current.scrollLeft;
      if (codeDisplayRef.current) {
        codeDisplayRef.current.scrollTop = top;
        codeDisplayRef.current.scrollLeft = left;
      }
      if (gutterRef.current) {
        gutterRef.current.scrollTop = top;
      }
    }
  }, []);

  const updateCursorAndSelection = useCallback(() => {
    if (!textareaRef.current) return;
    const { selectionStart, selectionEnd, value } = textareaRef.current;
    const textBefore = value.slice(0, selectionStart);
    const lineList = textBefore.split('\n');
    const line = lineList.length;
    const col = lineList[lineList.length - 1].length + 1;
    const selLen = Math.abs(selectionEnd - selectionStart);
    onUpdateCursor(line, col, selLen, selectionStart, selectionEnd);
  }, [onUpdateCursor]);

  // Keyboard shortcut & auto-closing brackets handler
  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    const el = textareaRef.current;
    if (!el) return;

    // Undo: Cmd+Z / Ctrl+Z (without Shift)
    if ((e.metaKey || e.ctrlKey) && !e.shiftKey && e.key.toLowerCase() === 'z') {
      e.preventDefault();
      if (onUndo) onUndo();
      return;
    }

    // Redo: Cmd+Shift+Z / Ctrl+Shift+Z / Ctrl+Y
    if (
      ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key.toLowerCase() === 'z') ||
      (e.ctrlKey && !e.metaKey && e.key.toLowerCase() === 'y')
    ) {
      e.preventDefault();
      if (onRedo) onRedo();
      return;
    }

    // F5: Run File
    if (e.key === 'F5') {
      e.preventDefault();
      if (onRunFile) onRunFile();
      return;
    }

    // Handle Tab key
    if (e.key === 'Tab') {
      e.preventDefault();
      const start = el.selectionStart;
      const end = el.selectionEnd;
      const indentStr = settings.insertSpaces ? ' '.repeat(settings.tabWidth) : '\t';

      if (e.shiftKey) {
        // Unindent
        const before = el.value.slice(0, start);
        const lastLineStart = before.lastIndexOf('\n') + 1;
        const currentLine = el.value.slice(lastLineStart, start);
        if (currentLine.startsWith(indentStr)) {
          const nextCursor = Math.max(lastLineStart, start - indentStr.length);
          const newContent =
            el.value.slice(0, lastLineStart) + el.value.slice(lastLineStart + indentStr.length);
          onChangeContent(newContent, {
            selectionStart: nextCursor,
            selectionEnd: nextCursor,
            label: 'outdent',
            coalesce: false,
          });
          setTimeout(() => {
            el.selectionStart = el.selectionEnd = nextCursor;
            updateCursorAndSelection();
          }, 0);
        }
      } else {
        // Indent
        const nextCursor = start + indentStr.length;
        const newContent = el.value.slice(0, start) + indentStr + el.value.slice(end);
        onChangeContent(newContent, {
          selectionStart: nextCursor,
          selectionEnd: nextCursor,
          label: 'indent',
          coalesce: false,
        });
        setTimeout(() => {
          el.selectionStart = el.selectionEnd = nextCursor;
          updateCursorAndSelection();
        }, 0);
      }
      return;
    }

    // Auto-close brackets and quotes
    if (settings.autoCloseBrackets && !e.metaKey && !e.ctrlKey && !e.altKey) {
      const pairs: Record<string, string> = {
        '(': ')',
        '[': ']',
        '{': '}',
        '"': '"',
        "'": "'",
        '`': '`',
      };

      if (pairs[e.key]) {
        const start = el.selectionStart;
        const end = el.selectionEnd;
        const closing = pairs[e.key];

        // If selection exists, wrap selection
        if (start !== end) {
          e.preventDefault();
          const selectedText = el.value.slice(start, end);
          const newContent =
            el.value.slice(0, start) + e.key + selectedText + closing + el.value.slice(end);
          onChangeContent(newContent, {
            selectionStart: start + 1,
            selectionEnd: end + 1,
            label: 'wrap',
            coalesce: false,
          });
          setTimeout(() => {
            el.selectionStart = start + 1;
            el.selectionEnd = end + 1;
            updateCursorAndSelection();
          }, 0);
          return;
        }

        // Auto insert pair
        if (['(', '[', '{'].includes(e.key)) {
          e.preventDefault();
          const newContent = el.value.slice(0, start) + e.key + closing + el.value.slice(start);
          onChangeContent(newContent, {
            selectionStart: start + 1,
            selectionEnd: start + 1,
            label: 'bracket',
            coalesce: false,
          });
          setTimeout(() => {
            el.selectionStart = el.selectionEnd = start + 1;
            updateCursorAndSelection();
          }, 0);
          return;
        }
      }
    }
  };

  // Context Menu actions for Cut, Copy, Paste, Select All
  const handleCutSelection = () => {
    const el = textareaRef.current;
    if (!el) return;
    el.focus();
    const start = el.selectionStart;
    const end = el.selectionEnd;
    if (start !== end) {
      const selected = el.value.slice(start, end);
      navigator.clipboard?.writeText(selected).catch(() => {});
      const newContent = el.value.slice(0, start) + el.value.slice(end);
      onChangeContent(newContent, {
        selectionStart: start,
        selectionEnd: start,
        label: 'cut',
        coalesce: false,
      });
      setTimeout(() => {
        el.selectionStart = el.selectionEnd = start;
        updateCursorAndSelection();
      }, 0);
    }
    setContextMenu(null);
  };

  const handleCopySelection = () => {
    const el = textareaRef.current;
    if (!el) return;
    el.focus();
    const start = el.selectionStart;
    const end = el.selectionEnd;
    if (start !== end) {
      const selected = el.value.slice(start, end);
      navigator.clipboard?.writeText(selected).catch(() => {});
    }
    setContextMenu(null);
  };

  const handlePasteClipboard = async () => {
    const el = textareaRef.current;
    if (!el) return;
    el.focus();
    try {
      const text = await navigator.clipboard.readText();
      if (text) {
        const start = el.selectionStart;
        const end = el.selectionEnd;
        const nextCursor = start + text.length;
        const newContent = el.value.slice(0, start) + text + el.value.slice(end);
        onChangeContent(newContent, {
          selectionStart: nextCursor,
          selectionEnd: nextCursor,
          label: 'paste',
          coalesce: false,
        });
        setTimeout(() => {
          el.selectionStart = el.selectionEnd = nextCursor;
          updateCursorAndSelection();
        }, 0);
      }
    } catch {
      document.execCommand('paste');
    }
    setContextMenu(null);
  };

  const handleSelectAll = () => {
    const el = textareaRef.current;
    if (!el) return;
    el.focus();
    el.setSelectionRange(0, el.value.length);
    updateCursorAndSelection();
    setContextMenu(null);
  };

  // Group diagnostics by line
  const diagnosticsByLine = useMemo(() => {
    const map = new Map<number, CodeDiagnostic>();
    for (const d of diagnostics) {
      if (!map.has(d.line)) {
        map.set(d.line, d);
      }
    }
    return map;
  }, [diagnostics]);

  const bookmarksSet = useMemo(() => new Set(activeTab.bookmarks), [activeTab.bookmarks]);

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault();
    const menuWidth = 230;
    const menuHeight = 310;
    const x = Math.min(e.clientX, window.innerWidth - menuWidth - 8);
    const y = Math.min(e.clientY, window.innerHeight - menuHeight - 8);
    setContextMenu({ x: Math.max(8, x), y: Math.max(8, y) });
  };

  return (
    <div
      onContextMenu={handleContextMenu}
      className="flex-1 flex overflow-hidden relative select-text"
      style={{
        backgroundColor: theme.styles.background,
        color: theme.styles.foreground,
        fontFamily: settings.fontFamily,
        fontSize: `${settings.fontSize}px`,
      }}
    >
      {/* Primary Editor Pane */}
      <div className="flex-1 flex overflow-hidden relative">
        {/* Line Numbers Gutter */}
        {settings.showLineNumbers && (
          <div
            ref={gutterRef}
            className="flex-shrink-0 select-none overflow-hidden text-right border-r transition-colors z-10"
            style={{
              backgroundColor: theme.styles.gutterBg,
              color: theme.styles.gutterFg,
              borderColor: theme.styles.gutterBorder,
              width: `${Math.max(46, String(lines.length).length * 9 + 24)}px`,
            }}
          >
            <div className="py-2">
              {lines.map((_, idx) => {
                const lineNum = idx + 1;
                return (
                  <MemoizedGutterRow
                    key={lineNum}
                    lineNum={lineNum}
                    isCurrent={lineNum === activeTab.cursorLine}
                    isBookmarked={bookmarksSet.has(lineNum)}
                    diag={diagnosticsByLine.get(lineNum)}
                    lineItemHeight={lineItemHeight}
                    activeLineBg={theme.styles.activeLineBg}
                    foreground={theme.styles.foreground}
                    gutterFg={theme.styles.gutterFg}
                    fontFamily={settings.fontFamily}
                    fontSize={Math.max(11, settings.fontSize - 1)}
                    onToggleBookmark={onToggleBookmark}
                  />
                );
              })}
            </div>
          </div>
        )}

        {/* Editor Content Area (Stacked Textarea + Highlighting Layer) */}
        <div
          className="flex-1 relative overflow-hidden cursor-text"
          onClick={() => textareaRef.current?.focus()}
        >
          {/* Syntax Highlighting & Token Display Layer */}
          {!isPlainOrMarkdown && (
            <div
              ref={codeDisplayRef}
              aria-hidden="true"
              className="absolute inset-0 pointer-events-none p-2 overflow-auto font-mono whitespace-pre"
              style={{
                whiteSpace: settings.wordWrap ? 'pre-wrap' : 'pre',
                tabSize: settings.tabWidth,
                fontFamily: settings.fontFamily,
                fontSize: `${settings.fontSize}px`,
                lineHeight: `${lineItemHeight}px`,
                boxSizing: 'border-box',
              }}
            >
              {lines.map((lineText, idx) => (
                <MemoizedCodeLine
                  key={idx}
                  lineText={lineText}
                  language={activeTab.language}
                  isCurrent={idx + 1 === activeTab.cursorLine}
                  lineItemHeight={lineItemHeight}
                  showWhitespace={settings.showWhitespace}
                  theme={theme}
                />
              ))}
            </div>
          )}

          {/* Interactive Editable Textarea */}
          <textarea
            ref={textareaRef}
            id="codepad-active-editor"
            value={activeTab.content ?? ''}
            readOnly={false}
            disabled={false}
            tabIndex={0}
            autoFocus
            onChange={(e) => {
              const nextVal = e.target.value;
              const selStart = e.target.selectionStart ?? 0;
              const selEnd = e.target.selectionEnd ?? selStart;
              const diffLen = Math.abs(nextVal.length - (activeTab.content?.length ?? 0));
              onChangeContent(nextVal, {
                selectionStart: selStart,
                selectionEnd: selEnd,
                label: diffLen > 1 ? 'paste' : 'typing',
                coalesce: diffLen === 1,
              });
              updateCursorAndSelection();
            }}
            onSelect={updateCursorAndSelection}
            onKeyUp={updateCursorAndSelection}
            onClick={updateCursorAndSelection}
            onScroll={handleScroll}
            onKeyDown={handleKeyDown}
            spellCheck={false}
            autoCapitalize="off"
            autoComplete="off"
            autoCorrect="off"
            className="absolute inset-0 w-full h-full p-2 font-mono bg-transparent resize-none border-none outline-none z-20 pointer-events-auto select-text selection:bg-blue-500/40"
            style={{
              whiteSpace: settings.wordWrap ? 'pre-wrap' : 'pre',
              tabSize: settings.tabWidth,
              fontFamily: settings.fontFamily,
              fontSize: `${settings.fontSize}px`,
              lineHeight: `${lineItemHeight}px`,
              letterSpacing: 'normal',
              wordSpacing: 'normal',
              boxSizing: 'border-box',
              color: isPlainOrMarkdown ? theme.styles.foreground : (theme.isDark ? '#60a5fa' : '#2563eb'),
              WebkitTextFillColor: isPlainOrMarkdown ? 'currentColor' : 'transparent',
              caretColor: theme.isDark ? '#60a5fa' : '#2563eb',
            }}
            aria-label="Code Editor Input"
          />
        </div>
      </div>

      {/* Secondary Split Editor Pane (if split view active) */}
      {isSplitView && secondaryTab && (
        <div className="flex-1 flex overflow-hidden border-l border-gray-400/30">
          <div className="flex-1 p-3 overflow-auto font-mono text-xs">
            <div className="text-xs font-semibold px-2 py-1 mb-2 bg-blue-500/10 text-blue-500 rounded flex justify-between">
              <span>Split View: {secondaryTab.title}</span>
              <span className="uppercase text-[10px]">{secondaryTab.language}</span>
            </div>
            <pre className="whitespace-pre-wrap">{secondaryTab.content}</pre>
          </div>
        </div>
      )}

      {/* Right-Click Editor Context Menu (Priority 3 & Priority 4) */}
      {contextMenu && (
        <div
          onClick={(e) => e.stopPropagation()}
          className="fixed z-50 w-56 py-1 rounded-md shadow-xl border text-xs select-none font-sans theme-dialog"
          style={{
            left: `${contextMenu.x}px`,
            top: `${contextMenu.y}px`,
            backgroundColor: 'var(--theme-dialog-bg)',
            color: 'var(--theme-dialog-fg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
          role="menu"
          aria-label="Editor Context Menu"
        >
          <button
            onClick={() => {
              if (canUndo && onUndo) onUndo();
              setContextMenu(null);
            }}
            disabled={!canUndo}
            className={`w-full px-3 py-1.5 flex items-center justify-between text-left ${
              !canUndo
                ? 'opacity-40 cursor-not-allowed'
                : 'hover:bg-blue-600 hover:text-white'
            }`}
          >
            <span className="flex items-center space-x-2">
              <Undo2 className="w-3.5 h-3.5" />
              <span>Undo</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘Z</span>
          </button>

          <button
            onClick={() => {
              if (canRedo && onRedo) onRedo();
              setContextMenu(null);
            }}
            disabled={!canRedo}
            className={`w-full px-3 py-1.5 flex items-center justify-between text-left ${
              !canRedo
                ? 'opacity-40 cursor-not-allowed'
                : 'hover:bg-blue-600 hover:text-white'
            }`}
          >
            <span className="flex items-center space-x-2">
              <Redo2 className="w-3.5 h-3.5" />
              <span>Redo</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⇧⌘Z</span>
          </button>

          <div className={`my-1 border-t ${theme.isDark ? 'border-[#3e4044]' : 'border-gray-300'}`} />

          <button
            onClick={handleCutSelection}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white"
          >
            <span className="flex items-center space-x-2">
              <Scissors className="w-3.5 h-3.5" />
              <span>Cut</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘X</span>
          </button>

          <button
            onClick={handleCopySelection}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white"
          >
            <span className="flex items-center space-x-2">
              <Copy className="w-3.5 h-3.5" />
              <span>Copy</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘C</span>
          </button>

          <button
            onClick={handlePasteClipboard}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white"
          >
            <span className="flex items-center space-x-2">
              <Clipboard className="w-3.5 h-3.5" />
              <span>Paste</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘V</span>
          </button>

          <button
            onClick={handleSelectAll}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white"
          >
            <span className="flex items-center space-x-2">
              <CheckSquare className="w-3.5 h-3.5" />
              <span>Select All</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘A</span>
          </button>

          <div className={`my-1 border-t ${theme.isDark ? 'border-[#3e4044]' : 'border-gray-300'}`} />

          <button
            onClick={() => {
              if (onOpenFind) onOpenFind();
              setContextMenu(null);
            }}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white"
          >
            <span className="flex items-center space-x-2">
              <Search className="w-3.5 h-3.5" />
              <span>Find...</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘F</span>
          </button>

          <button
            onClick={() => {
              if (onOpenReplace) onOpenReplace();
              setContextMenu(null);
            }}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white"
          >
            <span className="flex items-center space-x-2">
              <Replace className="w-3.5 h-3.5" />
              <span>Replace...</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">⌘H</span>
          </button>

          <div className={`my-1 border-t ${theme.isDark ? 'border-[#3e4044]' : 'border-gray-300'}`} />

          <button
            onClick={() => {
              if (onRunFile) onRunFile();
              setContextMenu(null);
            }}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white font-medium text-emerald-600 dark:text-emerald-400"
          >
            <span className="flex items-center space-x-2">
              <Play className="w-3.5 h-3.5 fill-current" />
              <span>Run File</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">F5</span>
          </button>

          <button
            onClick={() => {
              if (onOpenTerminalHere) onOpenTerminalHere();
              setContextMenu(null);
            }}
            className="w-full px-3 py-1.5 flex items-center justify-between text-left hover:bg-blue-600 hover:text-white font-medium"
          >
            <span className="flex items-center space-x-2">
              <Terminal className="w-3.5 h-3.5 text-emerald-500" />
              <span>Open Terminal Here</span>
            </span>
            <span className="text-[10px] opacity-70 font-mono">^`</span>
          </button>
        </div>
      )}
    </div>
  );
};
