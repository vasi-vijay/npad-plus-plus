import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { TabItem, EditorSettings, EditorTheme, SearchState } from './types';
import { INITIAL_TABS } from './lib/sampleFiles';
import { THEMES, applyThemeVariables } from './lib/themeConfig';
import {
  detectLineEnding,
  convertLineEnding,
  TextEncoding,
  LineEnding,
} from './lib/encoding';
import {
  findAllMatches,
  replaceNext,
  replaceAll,
  getMarkedLineNumbers,
} from './lib/search';
import {
  duplicateLineOrSelection,
  deleteCurrentLine,
  moveLineUp,
  moveLineDown,
  joinLines,
  convertTabsToSpaces,
  convertSpacesToTabs,
  toggleLineComment,
} from './lib/textOperations';
import {
  detectLanguage,
  validateCodeSyntax,
  CodeDiagnostic,
} from './lib/languageEngine';
import {
  PluginManager,
  PluginContext,
} from './lib/pluginSystem';
import {
  recordDocumentEdit,
  undoDocument,
  redoDocument,
  canUndoDocument,
  canRedoDocument,
  markDocumentSaved,
  createUntitledDocument,
  applyTabCloseDecision,
  serializeWorkspaceSession,
  deserializeWorkspaceSession,
  TabCloseAction,
} from './lib/sessionRecovery';
import { resolveTerminalDirectory } from './lib/codeRunner';

import { MacTitleBar, NppIconToolbar } from './components/MacTitleBar';
import { MacMenuBar } from './components/MacMenuBar';
import { TabBar } from './components/TabBar';
import { EditorArea } from './components/EditorArea';
import { Sidebar } from './components/Sidebar';
import { BottomPanel, TerminalLogItem } from './components/BottomPanel';
import { StatusBar } from './components/StatusBar';
import { FindReplaceModal } from './components/FindReplaceModal';
import { GoToLineModal } from './components/GoToLineModal';
import { CommandPalette, PaletteCommand } from './components/CommandPalette';
import { SettingsModal } from './components/SettingsModal';
import { PluginManagerModal } from './components/PluginManagerModal';
import { ExportAppModal } from './components/ExportAppModal';

const SESSION_STORAGE_KEY = 'codepad_session_v2';
const LEGACY_TABS_KEY = 'npp_tabs';

export default function App() {
  // Restore workspace session from localStorage on initial mount
  const initialSession = useMemo(() => {
    try {
      const savedSessionRaw = localStorage.getItem(SESSION_STORAGE_KEY);
      if (savedSessionRaw) {
        const parsed = JSON.parse(savedSessionRaw);
        if (parsed && Array.isArray(parsed.documents) && parsed.documents.length > 0) {
          return deserializeWorkspaceSession(parsed);
        }
      }
      const legacyRaw = localStorage.getItem(LEGACY_TABS_KEY);
      if (legacyRaw) {
        const legacyTabs: TabItem[] = JSON.parse(legacyRaw);
        if (Array.isArray(legacyTabs) && legacyTabs.length > 0) {
          const normalized = legacyTabs.map((t) => ({
            ...t,
            isModified: Boolean(t.isModified || t.content !== t.savedContent),
            undoStack: Array.isArray(t.undoStack) ? t.undoStack : [],
            redoStack: Array.isArray(t.redoStack) ? t.redoStack : [],
          }));
          return {
            tabs: normalized,
            activeTabId: normalized[0].id,
            secondaryTabId: normalized[1]?.id || normalized[0].id,
            isSplitView: false,
          };
        }
      }
    } catch {}
    return {
      tabs: INITIAL_TABS.map((t) => ({
        ...t,
        hasEverBeenSaved: true,
        undoStack: [],
        redoStack: [],
      })),
      activeTabId: INITIAL_TABS[0]?.id || 'tab-java-1',
      secondaryTabId: INITIAL_TABS[1]?.id || INITIAL_TABS[0]?.id || '',
      isSplitView: false,
    };
  }, []);

  const [tabs, setTabs] = useState<TabItem[]>(initialSession.tabs);
  const [activeTabId, setActiveTabId] = useState<string>(initialSession.activeTabId);
  const [secondaryTabId, setSecondaryTabId] = useState<string>(
    initialSession.secondaryTabId || initialSession.tabs[0]?.id || ''
  );
  const [isSplitView, setIsSplitView] = useState<boolean>(initialSession.isSplitView);

  // Pending close confirmation modal state (Priority 1.4: Save / Don't Save / Cancel)
  const [pendingCloseTabId, setPendingCloseTabId] = useState<string | null>(null);

  // Workspace root directory for terminal & file runner
  const [workspaceCwd, setWorkspaceCwd] = useState<string>('');
  const [requestedTerminalCwd, setRequestedTerminalCwd] = useState<{
    path: string;
    timestamp: number;
  } | null>(null);
  const [externalTerminalLogs, setExternalTerminalLogs] = useState<TerminalLogItem[]>([]);
  const [isExecutingFile, setIsExecutingFile] = useState<boolean>(false);

  // Layout states
  const [isSidebarVisible, setIsSidebarVisible] = useState(() => {
    if (typeof window !== 'undefined') {
      return window.innerWidth >= 800;
    }
    return true;
  });
  const [isBottomPanelOpen, setIsBottomPanelOpen] = useState(false);
  const [activeBottomTab, setActiveBottomTab] = useState<
    'terminal' | 'git' | 'java' | 'diagnostics' | 'diff' | 'markdown'
  >('terminal');
  const [isFullscreen, setIsFullscreen] = useState(false);

  // Modals
  const [isGoToLineOpen, setIsGoToLineOpen] = useState(false);
  const [isPaletteOpen, setIsPaletteOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isPluginModalOpen, setIsPluginModalOpen] = useState(false);
  const [isExportModalOpen, setIsExportModalOpen] = useState(false);

  // Toast notification
  const [toast, setToast] = useState<{
    message: string;
    type: 'info' | 'success' | 'warning' | 'error';
  } | null>(null);

  const showToast = useCallback(
    (message: string, type: 'info' | 'success' | 'warning' | 'error' = 'info') => {
      setToast({ message, type });
      setTimeout(() => {
        setToast((cur) => (cur?.message === message ? null : cur));
      }, 3500);
    },
    []
  );

  // Editor Settings
  const [settings, setSettings] = useState<EditorSettings>(() => {
    const saved = localStorage.getItem('npp_settings');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch {}
    }
    return {
      theme: 'npp-classic',
      fontSize: 13,
      fontFamily: 'SF Mono, Menlo, monospace',
      tabWidth: 4,
      insertSpaces: true,
      wordWrap: false,
      showWhitespace: false,
      showLineNumbers: true,
      highlightMatchingBrackets: true,
      autoCloseBrackets: true,
      autoSave: false,
    };
  });

  // Real-time hover preview theme state
  const [previewTheme, setPreviewTheme] = useState<EditorTheme | null>(null);

  // Load workspace info and check server-backed recovery session if localStorage had none
  useEffect(() => {
    fetch('/api/terminal/info')
      .then((r) => r.json())
      .then((info) => {
        if (info?.cwd) setWorkspaceCwd(info.cwd);
      })
      .catch(() => {});

    if (!localStorage.getItem(SESSION_STORAGE_KEY) && !localStorage.getItem(LEGACY_TABS_KEY)) {
      fetch('/api/session/load')
        .then((r) => r.json())
        .then((data) => {
          if (data?.hasSession && data.session?.documents?.length > 0) {
            const restored = deserializeWorkspaceSession(data.session);
            setTabs(restored.tabs);
            setActiveTabId(restored.activeTabId);
            if (restored.secondaryTabId) setSecondaryTabId(restored.secondaryTabId);
            setIsSplitView(restored.isSplitView);
          }
        })
        .catch(() => {});
    }
  }, []);

  // Debounced Session & Recovery Snapshot Persistence (Priority 1.2 & 1.3)
  const saveTimerRef = useRef<number | null>(null);
  useEffect(() => {
    const sessionPayload = serializeWorkspaceSession(
      tabs,
      activeTabId,
      secondaryTabId,
      isSplitView
    );
    try {
      localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(sessionPayload));
      localStorage.setItem(LEGACY_TABS_KEY, JSON.stringify(tabs));
    } catch {}

    if (saveTimerRef.current) {
      window.clearTimeout(saveTimerRef.current);
    }
    saveTimerRef.current = window.setTimeout(() => {
      fetch('/api/session/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ session: sessionPayload }),
      }).catch(() => {});
    }, 350);

    return () => {
      if (saveTimerRef.current) {
        window.clearTimeout(saveTimerRef.current);
      }
    };
  }, [tabs, activeTabId, secondaryTabId, isSplitView]);

  // Flush pending recovery state on page unload / restart
  useEffect(() => {
    const handleBeforeUnload = () => {
      try {
        const sessionPayload = serializeWorkspaceSession(
          tabs,
          activeTabId,
          secondaryTabId,
          isSplitView
        );
        localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(sessionPayload));
        localStorage.setItem(LEGACY_TABS_KEY, JSON.stringify(tabs));
      } catch {}
    };
    window.addEventListener('beforeunload', handleBeforeUnload);
    return () => window.removeEventListener('beforeunload', handleBeforeUnload);
  }, [tabs, activeTabId, secondaryTabId, isSplitView]);

  useEffect(() => {
    localStorage.setItem('npp_settings', JSON.stringify(settings));
  }, [settings]);

  // Plugin System
  const [pluginManager] = useState(() => new PluginManager());
  const [pluginsList, setPluginsList] = useState(() => pluginManager.getPlugins());

  // Search state
  const [searchState, setSearchState] = useState<SearchState>({
    isOpen: false,
    activeTab: 'find',
    query: '',
    replaceQuery: '',
    caseSensitive: false,
    wholeWord: false,
    useRegex: false,
    searchMode: 'normal',
    direction: 'down',
    wrapAround: true,
    lastMessage: '',
  });

  // Active Tab item
  const activeTab = useMemo(() => {
    return tabs.find((t) => t.id === activeTabId) || tabs[0];
  }, [tabs, activeTabId]);

  const secondaryTab = useMemo(() => {
    return tabs.find((t) => t.id === secondaryTabId) || tabs[1] || tabs[0];
  }, [tabs, secondaryTabId]);

  const effectiveThemeKey = previewTheme || settings.theme;
  const currentTheme = THEMES[effectiveThemeKey] || THEMES['npp-classic'];

  // Apply theme CSS variables to document root for real-time scrollbar, dialog, and editor styling
  useEffect(() => {
    applyThemeVariables(currentTheme, settings.fontFamily);
  }, [currentTheme, settings.fontFamily]);

  // Code Diagnostics for active file
  const diagnostics: CodeDiagnostic[] = useMemo(() => {
    if (!activeTab) return [];
    return validateCodeSyntax(activeTab.content, activeTab.language);
  }, [activeTab?.content, activeTab?.language]);

  // Tab update helper
  const updateActiveTab = useCallback(
    (updater: (tab: TabItem) => TabItem) => {
      setTabs((prev) =>
        prev.map((t) => {
          if (t.id === activeTabId) {
            return updater(t);
          }
          return t;
        })
      );
    },
    [activeTabId]
  );

  // Content change with Per-Document Undo/Redo Recording (Priority 1 & Priority 2)
  const handleChangeContent = useCallback(
    (
      newContent: string,
      meta?: {
        selectionStart?: number;
        selectionEnd?: number;
        label?: string;
        coalesce?: boolean;
      }
    ) => {
      updateActiveTab((tab) =>
        recordDocumentEdit(tab, newContent, {
          selectionStart: meta?.selectionStart,
          selectionEnd: meta?.selectionEnd,
          label: meta?.label,
          coalesce: meta?.coalesce,
        })
      );
    },
    [updateActiveTab]
  );

  // Per-Document Undo & Redo Actions (Priority 2)
  const handleUndo = useCallback(() => {
    if (!activeTab || !canUndoDocument(activeTab)) return;
    updateActiveTab((tab) => undoDocument(tab));
  }, [activeTab, updateActiveTab]);

  const handleRedo = useCallback(() => {
    if (!activeTab || !canRedoDocument(activeTab)) return;
    updateActiveTab((tab) => redoDocument(tab));
  }, [activeTab, updateActiveTab]);

  const canUndo = useMemo(() => canUndoDocument(activeTab), [activeTab]);
  const canRedo = useMemo(() => canRedoDocument(activeTab), [activeTab]);

  // Cursor and Selection update
  const handleUpdateCursor = useCallback(
    (line: number, col: number, selLength: number, selStart?: number, selEnd?: number) => {
      updateActiveTab((tab) => ({
        ...tab,
        cursorLine: line,
        cursorCol: col,
        selectionStart: selStart !== undefined ? selStart : tab.selectionStart,
        selectionEnd:
          selEnd !== undefined
            ? selEnd
            : (selStart !== undefined ? selStart : tab.selectionStart) + selLength,
      }));
    },
    [updateActiveTab]
  );

  // New File
  const handleNewFile = useCallback(() => {
    // Calculate next untitled number
    const existingNums = tabs
      .map((t) => {
        const m = t.title.match(/^new\s+(\d+)$/i);
        return m ? parseInt(m[1], 10) : 0;
      })
      .filter((n) => n > 0);
    const nextNum = existingNums.length > 0 ? Math.max(...existingNums) + 1 : tabs.length + 1;
    const newDoc = createUntitledDocument(nextNum);
    setTabs((prev) => [...prev, newDoc]);
    setActiveTabId(newDoc.id);
    showToast(`Created ${newDoc.title}`, 'info');
  }, [tabs, showToast]);

  // Open File from disk or browser picker
  const handleOpenFileByServerPath = useCallback(
    async (filePath: string) => {
      const existing = tabs.find(
        (t) => t.path === filePath || t.title === filePath.split('/').pop()
      );
      if (existing) {
        setActiveTabId(existing.id);
        return;
      }
      try {
        const res = await fetch(`/api/files/read?path=${encodeURIComponent(filePath)}`);
        if (res.ok) {
          const data = await res.json();
          if (data.exists && typeof data.content === 'string') {
            const lang = detectLanguage(data.title);
            const ending = detectLineEnding(data.content);
            const newDoc: TabItem = {
              id: `doc-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
              title: data.title,
              path: data.path,
              language: lang.id,
              encoding: 'UTF-8',
              lineEnding: ending,
              bookmarks: [],
              cursorLine: 1,
              cursorCol: 1,
              selectionStart: 0,
              selectionEnd: 0,
              isModified: false,
              hasEverBeenSaved: true,
              isMissingOnDisk: false,
              savedContent: data.content,
              content: data.content,
              undoStack: [],
              redoStack: [],
            };
            setTabs((prev) => [...prev, newDoc]);
            setActiveTabId(newDoc.id);
            showToast(`Opened ${data.title}`, 'success');
            return;
          }
        }
      } catch {}
    },
    [tabs, showToast]
  );

  const handleOpenFile = useCallback(() => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '*/*';
    input.onchange = (e) => {
      const file = (e.target as HTMLInputElement).files?.[0];
      if (!file) return;

      const reader = new FileReader();
      reader.onload = (re) => {
        const text = String(re.target?.result || '');
        const lang = detectLanguage(file.name);
        const ending = detectLineEnding(text);

        const newDoc: TabItem = {
          id: `doc-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
          title: file.name,
          path: workspaceCwd ? `${workspaceCwd}/${file.name}` : file.name,
          language: lang.id,
          encoding: 'UTF-8',
          lineEnding: ending,
          bookmarks: [],
          cursorLine: 1,
          cursorCol: 1,
          selectionStart: 0,
          selectionEnd: 0,
          isModified: false,
          hasEverBeenSaved: true,
          isMissingOnDisk: false,
          savedContent: text,
          content: text,
          undoStack: [],
          redoStack: [],
        };

        setTabs((prev) => [...prev, newDoc]);
        setActiveTabId(newDoc.id);
        showToast(`Opened ${file.name}`, 'success');
      };
      reader.readAsText(file);
    };
    input.click();
  }, [workspaceCwd, showToast]);

  // Persist a specific tab to disk & mark baseline saved
  const saveTabById = useCallback(
    (tabId: string) => {
      const target = tabs.find((t) => t.id === tabId);
      if (!target) return;

      const targetPath = target.path || target.title;
      fetch('/api/files/save', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ filePath: targetPath, content: target.content }),
      }).catch(() => {});

      setTabs((prev) =>
        prev.map((t) => (t.id === tabId ? markDocumentSaved(t, t.path, t.title) : t))
      );
      showToast(`Saved ${target.title}`, 'success');
    },
    [tabs, showToast]
  );

  // Save active file
  const handleSaveFile = useCallback(() => {
    if (!activeTab) return;
    saveTabById(activeTab.id);
  }, [activeTab, saveTabById]);

  // Save all files
  const handleSaveAll = useCallback(() => {
    for (const t of tabs) {
      if (t.isModified || t.content !== t.savedContent) {
        fetch('/api/files/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ filePath: t.path || t.title, content: t.content }),
        }).catch(() => {});
      }
    }
    setTabs((prev) => prev.map((t) => markDocumentSaved(t, t.path, t.title)));
    showToast('Saved all open documents', 'success');
  }, [tabs, showToast]);

  // Safe Tab Closing Workflow (Priority 1.4: Save / Don't Save / Cancel)
  const handleCloseTab = useCallback(
    (idToClose?: string, e?: React.MouseEvent) => {
      if (e) e.stopPropagation();
      const targetId = idToClose || activeTabId;
      const doc = tabs.find((t) => t.id === targetId);
      if (!doc) return;

      // If document has unsaved edits, show the 3-option Save / Don't Save / Cancel modal
      if (doc.isModified || doc.content !== doc.savedContent) {
        setPendingCloseTabId(targetId);
        return;
      }

      const result = applyTabCloseDecision(tabs, activeTabId, targetId, 'dont-save');
      setTabs(result.tabs);
      setActiveTabId(result.activeTabId);
    },
    [tabs, activeTabId]
  );

  const handleConfirmCloseDecision = useCallback(
    (decision: TabCloseAction) => {
      if (!pendingCloseTabId) return;
      const targetId = pendingCloseTabId;
      setPendingCloseTabId(null);

      if (decision === 'cancel') {
        return;
      }

      const result = applyTabCloseDecision(
        tabs,
        activeTabId,
        targetId,
        decision,
        (savedDoc) => {
          fetch('/api/files/save', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              filePath: savedDoc.path || savedDoc.title,
              content: savedDoc.content,
            }),
          }).catch(() => {});
          showToast(`Saved ${savedDoc.title}`, 'success');
        }
      );

      setTabs(result.tabs);
      setActiveTabId(result.activeTabId);
    },
    [pendingCloseTabId, tabs, activeTabId, showToast]
  );

  // Close all tabs except one
  const handleCloseOtherTabs = useCallback(
    (keepId: string) => {
      const keepDoc = tabs.find((t) => t.id === keepId);
      if (!keepDoc) return;
      const dirtyOthers = tabs.filter(
        (t) => t.id !== keepId && (t.isModified || t.content !== t.savedContent)
      );
      if (dirtyOthers.length > 0) {
        showToast(
          `Cannot close ${dirtyOthers.length} other tab(s) with unsaved changes — save or close them individually.`,
          'warning'
        );
        return;
      }
      setTabs([keepDoc]);
      setActiveTabId(keepDoc.id);
    },
    [tabs, showToast]
  );

  // Priority 3: Open Terminal Here (from Editor Context Menu, Menu Bar, or Tab Context Menu)
  const handleOpenTerminalHere = useCallback(
    (tabId?: string) => {
      const targetDoc = (tabId ? tabs.find((t) => t.id === tabId) : activeTab) || activeTab;
      const resolvedDir = resolveTerminalDirectory(
        {
          activeFilePath: targetDoc?.path,
          workspaceRoot: workspaceCwd || '/tmp',
          defaultDirectory: workspaceCwd || '/tmp',
        },
        true
      );
      setIsBottomPanelOpen(true);
      setActiveBottomTab('terminal');
      setRequestedTerminalCwd({ path: resolvedDir, timestamp: Date.now() });
      showToast(`Terminal directory: ${resolvedDir}`, 'info');
    },
    [tabs, activeTab, workspaceCwd, showToast]
  );

  // Priority 4: Run Source Code Directly From Editor
  const handleRunActiveFile = useCallback(async () => {
    if (!activeTab) return;
    setIsBottomPanelOpen(true);
    setActiveBottomTab('terminal');
    setIsExecutingFile(true);

    const targetDir = resolveTerminalDirectory(
      {
        activeFilePath: activeTab.path,
        workspaceRoot: workspaceCwd || '/tmp',
        defaultDirectory: workspaceCwd || '/tmp',
      },
      true
    );

    setExternalTerminalLogs((prev) => [
      ...prev,
      {
        text: `[Running ${activeTab.title} (${activeTab.language})...]`,
        type: 'info',
      },
    ]);

    try {
      const res = await fetch('/api/run/execute', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: activeTab.title,
          filePath: activeTab.path,
          language: activeTab.language,
          content: activeTab.content,
          isModified: activeTab.isModified,
          cwd: targetDir,
        }),
      });

      const data = await res.json();
      const newLogs: TerminalLogItem[] = [];

      if (data.command) {
        newLogs.push({ text: `$ ${data.command}`, type: 'cmd' });
      }
      if (data.stdout && data.stdout.trim().length > 0) {
        newLogs.push({ text: data.stdout.trimEnd(), type: 'stdout' });
      }
      if (data.stderr && data.stderr.trim().length > 0) {
        newLogs.push({ text: data.stderr.trimEnd(), type: 'stderr' });
      }
      newLogs.push({
        text: `[Process finished with exit code ${data.exitCode ?? 0}${
          data.durationMs ? ` in ${data.durationMs}ms` : ''
        }]`,
        type: data.exitCode === 0 ? 'info' : 'stderr',
      });

      setExternalTerminalLogs((prev) => [...prev, ...newLogs]);
    } catch (err: any) {
      setExternalTerminalLogs((prev) => [
        ...prev,
        { text: `Execution error: ${err?.message || 'Failed to run file'}`, type: 'stderr' },
      ]);
    } finally {
      setIsExecutingFile(false);
    }
  }, [activeTab, workspaceCwd]);

  const handleKillExecution = useCallback(() => {
    fetch('/api/run/kill', { method: 'POST' }).catch(() => {});
    setIsExecutingFile(false);
    setExternalTerminalLogs((prev) => [
      ...prev,
      { text: '[Process terminated by user]', type: 'stderr' },
    ]);
  }, []);

  // Duplicate line (Cmd+D)
  const handleDuplicateLine = () => {
    if (!activeTab) return;
    const res = duplicateLineOrSelection(activeTab.content, {
      start: activeTab.selectionStart,
      end: activeTab.selectionEnd,
    });
    handleChangeContent(res.newText, {
      selectionStart: res.newSelection.start,
      selectionEnd: res.newSelection.end,
      label: 'duplicate-line',
    });
    showToast('Line duplicated (⌘D)', 'info');
  };

  // Delete current line (Shift+Cmd+K)
  const handleDeleteLine = () => {
    if (!activeTab) return;
    const res = deleteCurrentLine(activeTab.content, {
      start: activeTab.selectionStart,
      end: activeTab.selectionEnd,
    });
    handleChangeContent(res.newText, {
      selectionStart: res.newCursor,
      selectionEnd: res.newCursor,
      label: 'delete-line',
    });
    showToast('Line deleted (⇧⌘K)', 'info');
  };

  // Move line up (Alt+Up)
  const handleMoveLineUp = () => {
    if (!activeTab) return;
    const res = moveLineUp(activeTab.content, activeTab.selectionStart);
    handleChangeContent(res.newText, {
      selectionStart: res.newCursor,
      selectionEnd: res.newCursor,
      label: 'move-line-up',
    });
  };

  // Move line down (Alt+Down)
  const handleMoveLineDown = () => {
    if (!activeTab) return;
    const res = moveLineDown(activeTab.content, activeTab.selectionStart);
    handleChangeContent(res.newText, {
      selectionStart: res.newCursor,
      selectionEnd: res.newCursor,
      label: 'move-line-down',
    });
  };

  // Join lines (Cmd+J)
  const handleJoinLines = () => {
    if (!activeTab) return;
    const res = joinLines(activeTab.content, activeTab.selectionStart);
    handleChangeContent(res.newText, {
      selectionStart: res.newCursor,
      selectionEnd: res.newCursor,
      label: 'join-lines',
    });
    showToast('Lines joined (⌘J)', 'info');
  };

  // Toggle line comment (Cmd+/)
  const handleToggleComment = () => {
    if (!activeTab) return;
    const prefix =
      activeTab.language === 'python' ||
      activeTab.language === 'shell' ||
      activeTab.language === 'properties'
        ? '#'
        : '//';
    const res = toggleLineComment(
      activeTab.content,
      { start: activeTab.selectionStart, end: activeTab.selectionEnd },
      prefix
    );
    handleChangeContent(res.newText, {
      selectionStart: res.newSelection.start,
      selectionEnd: res.newSelection.end,
      label: 'toggle-comment',
    });
  };

  // Convert tabs to spaces
  const handleConvertTabsToSpaces = () => {
    if (!activeTab) return;
    const converted = convertTabsToSpaces(activeTab.content, settings.tabWidth);
    handleChangeContent(converted, { label: 'tabs-to-spaces' });
    showToast(`Converted tabs to ${settings.tabWidth} spaces`, 'success');
  };

  // Convert spaces to tabs
  const handleConvertSpacesToTabs = () => {
    if (!activeTab) return;
    const converted = convertSpacesToTabs(activeTab.content, settings.tabWidth);
    handleChangeContent(converted, { label: 'spaces-to-tabs' });
    showToast('Converted leading spaces to tabs', 'success');
  };

  // Toggle bookmark on line
  const handleToggleBookmark = (lineNum: number) => {
    updateActiveTab((tab) => {
      const exists = tab.bookmarks.includes(lineNum);
      const bookmarks = exists
        ? tab.bookmarks.filter((b) => b !== lineNum)
        : [...tab.bookmarks, lineNum].sort((a, b) => a - b);
      return { ...tab, bookmarks };
    });
  };

  // Navigate to next bookmark (F2)
  const handleNextBookmark = () => {
    if (!activeTab || activeTab.bookmarks.length === 0) {
      showToast('No bookmarks in active document', 'info');
      return;
    }
    const current = activeTab.cursorLine;
    const next = activeTab.bookmarks.find((b) => b > current) || activeTab.bookmarks[0];
    handleJumpToLine(next);
    showToast(`Jumped to bookmark at Line ${next}`, 'info');
  };

  // Navigate to previous bookmark (Shift+F2)
  const handlePrevBookmark = () => {
    if (!activeTab || activeTab.bookmarks.length === 0) {
      showToast('No bookmarks in active document', 'info');
      return;
    }
    const current = activeTab.cursorLine;
    const reversed = [...activeTab.bookmarks].reverse();
    const prev = reversed.find((b) => b < current) || reversed[0];
    handleJumpToLine(prev);
    showToast(`Jumped to bookmark at Line ${prev}`, 'info');
  };

  // Clear bookmarks
  const handleClearBookmarks = () => {
    updateActiveTab((tab) => ({ ...tab, bookmarks: [] }));
    showToast('Cleared all bookmarks in document', 'info');
  };

  // Jump to line
  const handleJumpToLine = (line: number) => {
    updateActiveTab((tab) => ({
      ...tab,
      cursorLine: line,
      cursorCol: 1,
    }));
  };

  // Search actions
  const handleFindNext = () => {
    if (!activeTab || !searchState.query) return;
    const matches = findAllMatches(activeTab.content, searchState);
    if (matches.length === 0) {
      setSearchState((prev) => ({ ...prev, lastMessage: `Cannot find "${prev.query}"` }));
      return;
    }

    const currentLine = activeTab.cursorLine;
    const nextMatch = matches.find((m) => m.lineNumber > currentLine) || matches[0];
    handleJumpToLine(nextMatch.lineNumber);
    setSearchState((prev) => ({
      ...prev,
      lastMessage: `Found match at Line ${nextMatch.lineNumber}, Col ${nextMatch.columnNumber} (${
        matches.indexOf(nextMatch) + 1
      } of ${matches.length})`,
    }));
  };

  const handleFindPrev = () => {
    if (!activeTab || !searchState.query) return;
    const matches = findAllMatches(activeTab.content, searchState);
    if (matches.length === 0) {
      setSearchState((prev) => ({ ...prev, lastMessage: `Cannot find "${prev.query}"` }));
      return;
    }

    const currentLine = activeTab.cursorLine;
    const prevMatch =
      [...matches].reverse().find((m) => m.lineNumber < currentLine) ||
      matches[matches.length - 1];
    handleJumpToLine(prevMatch.lineNumber);
    setSearchState((prev) => ({
      ...prev,
      lastMessage: `Found match at Line ${prevMatch.lineNumber}, Col ${prevMatch.columnNumber}`,
    }));
  };

  const handleReplace = () => {
    if (!activeTab || !searchState.query) return;
    const res = replaceNext(
      activeTab.content,
      searchState,
      searchState.replaceQuery,
      activeTab.selectionStart
    );
    if (res.replaced) {
      handleChangeContent(res.newText, {
        selectionStart: res.nextIndex,
        selectionEnd: res.nextIndex,
        label: 'replace',
      });
      setSearchState((prev) => ({ ...prev, lastMessage: 'Replaced 1 occurrence.' }));
    } else {
      setSearchState((prev) => ({ ...prev, lastMessage: 'No occurrences found to replace.' }));
    }
  };

  const handleReplaceAll = () => {
    if (!activeTab || !searchState.query) return;
    const res = replaceAll(activeTab.content, searchState, searchState.replaceQuery);
    if (res.count > 0) {
      handleChangeContent(res.newText, { label: 'replace-all' });
      setSearchState((prev) => ({
        ...prev,
        lastMessage: `Replace All: ${res.count} occurrence(s) replaced.`,
      }));
      showToast(`Replaced ${res.count} occurrences`, 'success');
    } else {
      setSearchState((prev) => ({ ...prev, lastMessage: 'No occurrences found to replace.' }));
    }
  };

  const handleMarkAll = () => {
    if (!activeTab || !searchState.query) return;
    const markedLines = getMarkedLineNumbers(activeTab.content, searchState);
    if (markedLines.length === 0) {
      setSearchState((prev) => ({ ...prev, lastMessage: 'No matching lines to mark.' }));
      return;
    }

    updateActiveTab((tab) => {
      const merged = Array.from(new Set([...tab.bookmarks, ...markedLines])).sort(
        (a, b) => a - b
      );
      return { ...tab, bookmarks: merged };
    });

    setSearchState((prev) => ({
      ...prev,
      lastMessage: `Mark: ${markedLines.length} line(s) bookmarked.`,
    }));
    showToast(`Bookmarked ${markedLines.length} lines matching search`, 'success');
  };

  const handleCountMatches = () => {
    if (!activeTab || !searchState.query) return;
    const matches = findAllMatches(activeTab.content, searchState);
    setSearchState((prev) => ({
      ...prev,
      lastMessage: `Count: ${matches.length} match(es) in entire file.`,
    }));
  };

  // Convert or set encoding
  const handleSetEncoding = (enc: TextEncoding) => {
    updateActiveTab((tab) => ({ ...tab, encoding: enc }));
    showToast(`Encoding set to ${enc}`, 'info');
  };

  // Convert or set line endings
  const handleSetLineEnding = (ending: LineEnding) => {
    updateActiveTab((tab) => {
      const converted = convertLineEnding(tab.content, ending);
      return {
        ...tab,
        content: converted,
        lineEnding: ending,
        isModified: true,
      };
    });
    showToast(
      `Converted line endings to ${
        ending === 'LF' ? 'Unix (LF)' : ending === 'CRLF' ? 'Windows (CRLF)' : 'Mac (CR)'
      }`,
      'success'
    );
  };

  // Set language
  const handleSetLanguage = (langId: string) => {
    updateActiveTab((tab) => ({ ...tab, language: langId }));
    showToast(`Language set to ${langId}`, 'info');
  };

  // Run plugin command by ID
  const handleRunPluginCommand = (cmdId: string) => {
    if (!activeTab) return;

    const mockCtx: PluginContext = {
      getText: () => activeTab.content,
      setText: (newText: string) => handleChangeContent(newText, { label: `plugin:${cmdId}` }),
      getSelection: () => {
        const sel = activeTab.content.slice(activeTab.selectionStart, activeTab.selectionEnd);
        return { start: activeTab.selectionStart, end: activeTab.selectionEnd, text: sel };
      },
      setSelection: (start: number, end: number) => {
        updateActiveTab((tab) => ({ ...tab, selectionStart: start, selectionEnd: end }));
      },
      getActiveFile: () => ({
        name: activeTab.title,
        language: activeTab.language,
        encoding: activeTab.encoding,
      }),
      showMessage: (msg: string, type?: 'info' | 'success' | 'warning' | 'error') => {
        showToast(msg, type || 'info');
      },
    };

    const allCmds = pluginManager.getAllCommands();
    const item = allCmds.find((c) => c.command.id === cmdId);
    if (item) {
      item.command.execute(mockCtx);
    } else {
      showToast(`Plugin command ${cmdId} executed`, 'info');
    }
  };

  // Global keyboard shortcuts
  useEffect(() => {
    const handleGlobalKeys = (e: KeyboardEvent) => {
      const target = e.target as HTMLElement | null;
      const isInput =
        target &&
        (target.tagName === 'INPUT' ||
          (target.tagName === 'TEXTAREA' &&
            target.getAttribute('aria-label') !== 'Code Editor Input'));

      // Cmd+Z / Cmd+Shift+Z when focus is not inside a modal input field
      if (!isInput && (e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'z') {
        e.preventDefault();
        if (e.shiftKey) {
          handleRedo();
        } else {
          handleUndo();
        }
        return;
      }

      // Cmd+F or Ctrl+F: Find
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'f' && !e.shiftKey) {
        e.preventDefault();
        setSearchState((prev) => ({ ...prev, isOpen: true, activeTab: 'find' }));
        return;
      }
      // Cmd+H or Ctrl+H: Replace
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'h') {
        e.preventDefault();
        setSearchState((prev) => ({ ...prev, isOpen: true, activeTab: 'replace' }));
        return;
      }
      // Cmd+G: Go to line
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'g') {
        e.preventDefault();
        setIsGoToLineOpen(true);
        return;
      }
      // Cmd+P or Cmd+Shift+P: Command palette
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'p') {
        e.preventDefault();
        setIsPaletteOpen(true);
        return;
      }
      // Cmd+S: Save
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 's') {
        e.preventDefault();
        if (e.altKey) {
          handleSaveAll();
        } else {
          handleSaveFile();
        }
        return;
      }
      // Cmd+N: New file
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'n') {
        e.preventDefault();
        handleNewFile();
        return;
      }
      // Cmd+W: Close tab
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'w') {
        e.preventDefault();
        handleCloseTab();
        return;
      }
      // Cmd+B: Toggle sidebar
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'b') {
        e.preventDefault();
        setIsSidebarVisible((prev) => !prev);
        return;
      }
      // Cmd+D: Duplicate line
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'd') {
        e.preventDefault();
        handleDuplicateLine();
        return;
      }
      // Cmd+J: Join lines
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'j') {
        e.preventDefault();
        handleJoinLines();
        return;
      }
      // F5: Run File
      if (e.key === 'F5') {
        e.preventDefault();
        handleRunActiveFile();
        return;
      }
      // F2: Next bookmark
      if (e.key === 'F2') {
        e.preventDefault();
        if (e.shiftKey) {
          handlePrevBookmark();
        } else {
          handleNextBookmark();
        }
        return;
      }
      // Ctrl+~ or Ctrl+` : Toggle terminal
      if (e.ctrlKey && (e.key === '`' || e.key === '~')) {
        e.preventDefault();
        setIsBottomPanelOpen((prev) => !prev);
        return;
      }
      // Cmd+, : Settings
      if ((e.metaKey || e.ctrlKey) && e.key === ',') {
        e.preventDefault();
        setIsSettingsOpen(true);
        return;
      }
    };

    window.addEventListener('keydown', handleGlobalKeys);
    return () => window.removeEventListener('keydown', handleGlobalKeys);
  }, [
    activeTab,
    searchState,
    tabs,
    handleUndo,
    handleRedo,
    handleSaveFile,
    handleSaveAll,
    handleNewFile,
    handleCloseTab,
    handleRunActiveFile,
  ]);

  // Command palette commands
  const paletteCommands: PaletteCommand[] = useMemo(() => {
    return [
      { id: 'file.new', name: 'New File', category: 'File', shortcut: '⌘N', action: handleNewFile },
      { id: 'file.open', name: 'Open File...', category: 'File', shortcut: '⌘O', action: handleOpenFile },
      { id: 'file.save', name: 'Save File', category: 'File', shortcut: '⌘S', action: handleSaveFile },
      { id: 'file.saveall', name: 'Save All Files', category: 'File', shortcut: '⌥⌘S', action: handleSaveAll },
      { id: 'run.file', name: 'Run Current File', category: 'Run', shortcut: 'F5', action: handleRunActiveFile },
      { id: 'run.termhere', name: 'Open Terminal Here', category: 'Run', shortcut: '^`', action: () => handleOpenTerminalHere() },
      { id: 'edit.undo', name: 'Undo', category: 'Edit', shortcut: '⌘Z', action: handleUndo },
      { id: 'edit.redo', name: 'Redo', category: 'Edit', shortcut: '⇧⌘Z', action: handleRedo },
      { id: 'search.find', name: 'Find...', category: 'Search', shortcut: '⌘F', action: () => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'find' })) },
      { id: 'search.replace', name: 'Replace...', category: 'Search', shortcut: '⌘H', action: () => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'replace' })) },
      { id: 'search.goto', name: 'Go to Line...', category: 'Search', shortcut: '⌘G', action: () => setIsGoToLineOpen(true) },
      { id: 'search.nextbm', name: 'Next Bookmark', category: 'Search', shortcut: 'F2', action: handleNextBookmark },
      { id: 'search.prevbm', name: 'Previous Bookmark', category: 'Search', shortcut: '⇧F2', action: handlePrevBookmark },
      { id: 'edit.dup', name: 'Duplicate Current Line', category: 'Edit', shortcut: '⌘D', action: handleDuplicateLine },
      { id: 'edit.del', name: 'Delete Current Line', category: 'Edit', shortcut: '⇧⌘K', action: handleDeleteLine },
      { id: 'edit.join', name: 'Join Lines', category: 'Edit', shortcut: '⌘J', action: handleJoinLines },
      { id: 'edit.comment', name: 'Toggle Line Comment', category: 'Edit', shortcut: '⌘/', action: handleToggleComment },
      { id: 'edit.tab2space', name: 'Convert Tabs to Spaces', category: 'Edit', action: handleConvertTabsToSpaces },
      { id: 'edit.space2tab', name: 'Convert Spaces to Tabs', category: 'Edit', action: handleConvertSpacesToTabs },
      { id: 'view.wrap', name: 'Toggle Word Wrap', category: 'View', action: () => setSettings((s) => ({ ...s, wordWrap: !s.wordWrap })) },
      { id: 'view.whitespace', name: 'Toggle Whitespace', category: 'View', action: () => setSettings((s) => ({ ...s, showWhitespace: !s.showWhitespace })) },
      { id: 'view.terminal', name: 'Toggle Developer Terminal', category: 'View', shortcut: '^~', action: () => setIsBottomPanelOpen((p) => !p) },
      { id: 'java.controller', name: 'Insert Spring Boot @RestController Template', category: 'Java', action: () => handleRunPluginCommand('spring.controller') },
      { id: 'java.properties', name: 'Insert Spring Boot application.properties', category: 'Java', action: () => handleRunPluginCommand('spring.properties') },
      { id: 'plugin.json.format', name: 'Format JSON', category: 'Plugin', shortcut: '⇧⌘F', action: () => handleRunPluginCommand('json.format') },
      { id: 'plugin.json.minify', name: 'Minify JSON', category: 'Plugin', action: () => handleRunPluginCommand('json.minify') },
      { id: 'plugin.base64.enc', name: 'Base64 Encode Selection', category: 'Plugin', action: () => handleRunPluginCommand('codec.base64.encode') },
      { id: 'plugin.base64.dec', name: 'Base64 Decode Selection', category: 'Plugin', action: () => handleRunPluginCommand('codec.base64.decode') },
      { id: 'plugin.sort.asc', name: 'Sort Lines Ascending (A-Z)', category: 'Plugin', action: () => handleRunPluginCommand('lines.sort.asc') },
      { id: 'plugin.sort.desc', name: 'Sort Lines Descending (Z-A)', category: 'Plugin', action: () => handleRunPluginCommand('lines.sort.desc') },
      { id: 'plugin.dedupe', name: 'Remove Duplicate Lines', category: 'Plugin', action: () => handleRunPluginCommand('lines.dedupe') },
      { id: 'plugin.stats', name: 'Show Document Statistics', category: 'Plugin', shortcut: '⇧⌘I', action: () => handleRunPluginCommand('stats.count') },
      { id: 'app.export', name: 'Export macOS .dmg / .app', category: 'macOS', action: () => setIsExportModalOpen(true) },
      { id: 'app.prefs', name: 'Preferences...', category: 'Settings', shortcut: '⌘,', action: () => setIsSettingsOpen(true) },
      { id: 'app.plugins', name: 'Plugin Manager...', category: 'Settings', action: () => setIsPluginModalOpen(true) },
    ];
  }, [
    activeTab,
    settings,
    handleNewFile,
    handleOpenFile,
    handleSaveFile,
    handleSaveAll,
    handleRunActiveFile,
    handleOpenTerminalHere,
    handleUndo,
    handleRedo,
  ]);

  const totalLines = activeTab ? activeTab.content.split('\n').length : 0;
  const pendingCloseDoc = useMemo(
    () => (pendingCloseTabId ? tabs.find((t) => t.id === pendingCloseTabId) : null),
    [pendingCloseTabId, tabs]
  );

  const sharedToolbarProps = {
    activeTitle: activeTab?.title || 'CodePad',
    activePath: activeTab?.path,
    isModified: Boolean(activeTab?.isModified),
    isDark: currentTheme.isDark,
    isFullscreen,
    canUndo,
    canRedo,
    wordWrap: settings.wordWrap,
    showWhitespace: settings.showWhitespace,
    isExecutingFile,
    onToggleFullscreen: () => setIsFullscreen(!isFullscreen),
    onNewFile: handleNewFile,
    onOpenFile: handleOpenFile,
    onSaveFile: handleSaveFile,
    onSaveAll: handleSaveAll,
    onCloseTab: () => handleCloseTab(),
    onUndo: handleUndo,
    onRedo: handleRedo,
    onCut: () => document.execCommand('cut'),
    onCopy: () => document.execCommand('copy'),
    onPaste: () => document.execCommand('paste'),
    onOpenSearch: () => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'find' })),
    onOpenReplace: () => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'replace' })),
    onZoomIn: () => setSettings((s) => ({ ...s, fontSize: Math.min(32, s.fontSize + 1) })),
    onZoomOut: () => setSettings((s) => ({ ...s, fontSize: Math.max(9, s.fontSize - 1) })),
    onToggleWordWrap: () => setSettings((s) => ({ ...s, wordWrap: !s.wordWrap })),
    onToggleWhitespace: () => setSettings((s) => ({ ...s, showWhitespace: !s.showWhitespace })),
    onRunFile: handleRunActiveFile,
    onToggleSplit: () => setIsSplitView((p) => !p),
    onToggleTerminal: () => {
      setIsBottomPanelOpen((p) => !p);
      setActiveBottomTab('terminal');
    },
    onToggleSidebar: () => setIsSidebarVisible((p) => !p),
    onOpenSettings: () => setIsSettingsOpen(true),
    onOpenExport: () => setIsExportModalOpen(true),
  };

  return (
    <div
      className={`w-screen h-screen flex flex-col overflow-hidden select-none font-sans ${
        currentTheme.isDark ? 'dark bg-[#1e1e1e] text-gray-200' : 'bg-[#f4f4f4] text-gray-800'
      }`}
    >
      {/* 1. Compact Window Title Bar */}
      <MacTitleBar {...sharedToolbarProps} />

      {/* 2. 13-Item Notepad++ Application Menu Bar */}
      <MacMenuBar
        isDark={currentTheme.isDark}
        currentLanguage={activeTab?.language || 'plaintext'}
        currentEncoding={activeTab?.encoding || 'UTF-8'}
        currentLineEnding={activeTab?.lineEnding || 'LF'}
        wordWrap={settings.wordWrap}
        showWhitespace={settings.showWhitespace}
        canUndo={canUndo}
        canRedo={canRedo}
        onNewFile={handleNewFile}
        onOpenFile={handleOpenFile}
        onSaveFile={handleSaveFile}
        onSaveAll={handleSaveAll}
        onCloseTab={() => handleCloseTab()}
        onUndo={handleUndo}
        onRedo={handleRedo}
        onCut={() => document.execCommand('cut')}
        onCopy={() => document.execCommand('copy')}
        onPaste={() => document.execCommand('paste')}
        onSelectAll={() => document.execCommand('selectAll')}
        onDuplicateLine={handleDuplicateLine}
        onDeleteLine={handleDeleteLine}
        onMoveLineUp={handleMoveLineUp}
        onMoveLineDown={handleMoveLineDown}
        onJoinLines={handleJoinLines}
        onToggleComment={handleToggleComment}
        onConvertTabsToSpaces={handleConvertTabsToSpaces}
        onConvertSpacesToTabs={handleConvertSpacesToTabs}
        onOpenFind={() => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'find' }))}
        onOpenReplace={() => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'replace' }))}
        onOpenMark={() => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'mark' }))}
        onGoToLine={() => setIsGoToLineOpen(true)}
        onNextBookmark={handleNextBookmark}
        onPrevBookmark={handlePrevBookmark}
        onClearBookmarks={handleClearBookmarks}
        onToggleWordWrap={() => setSettings((s) => ({ ...s, wordWrap: !s.wordWrap }))}
        onToggleWhitespace={() => setSettings((s) => ({ ...s, showWhitespace: !s.showWhitespace }))}
        onSetEncoding={handleSetEncoding}
        onSetLineEnding={handleSetLineEnding}
        onSetLanguage={handleSetLanguage}
        onOpenSettings={() => setIsSettingsOpen(true)}
        onOpenPluginManager={() => setIsPluginModalOpen(true)}
        onRunPluginCommand={handleRunPluginCommand}
        onRunFile={handleRunActiveFile}
        onOpenTerminalHere={() => handleOpenTerminalHere()}
        onOpenJavaTools={() => {
          setIsBottomPanelOpen(true);
          setActiveBottomTab('java');
        }}
        onOpenGitPanel={() => {
          setIsBottomPanelOpen(true);
          setActiveBottomTab('git');
        }}
        onOpenTerminal={() => {
          setIsBottomPanelOpen(true);
          setActiveBottomTab('terminal');
        }}
        onOpenExport={() => setIsExportModalOpen(true)}
      />

      {/* 3. Classic Notepad++ Standard Icon Toolbar */}
      <NppIconToolbar {...sharedToolbarProps} />

      {/* 4. Document Tab Bar */}
      <TabBar
        tabs={tabs}
        activeTabId={activeTabId}
        isDark={currentTheme.isDark}
        onSelectTab={(id) => setActiveTabId(id)}
        onCloseTab={handleCloseTab}
        onCloseOtherTabs={handleCloseOtherTabs}
        onSaveTab={saveTabById}
        onOpenTerminalAtTab={(id) => handleOpenTerminalHere(id)}
        onNewTab={handleNewFile}
      />

      {/* 5. Main Workspace: Sidebar + Editor + Bottom Docked Panel */}
      <div className="flex-1 flex overflow-hidden relative">
        {/* Left Sidebar */}
        <Sidebar
          isVisible={isSidebarVisible}
          isDark={currentTheme.isDark}
          tabs={tabs}
          activeTabId={activeTabId}
          plugins={pluginsList}
          onSelectTab={(id) => setActiveTabId(id)}
          onJumpToLine={handleJumpToLine}
          onOpenFileByPath={(filePath) => handleOpenFileByServerPath(filePath)}
          onNewFile={handleNewFile}
        />

        {/* Center: Missing/Conflict Banner + Editor + Bottom Panel */}
        <div className="flex-1 flex flex-col overflow-hidden relative">
          {/* Missing or Externally Modified File Banner (Priority 1.5) */}
          {activeTab?.isMissingOnDisk && (
            <div className="px-3 py-1.5 bg-red-600/15 border-b border-red-500/40 text-red-700 dark:text-red-300 text-xs flex items-center justify-between">
              <span>
                Original file <strong>{activeTab.path || activeTab.title}</strong> was moved or
                deleted on disk. Your recoverable content is preserved in this tab.
              </span>
              <button
                onClick={handleSaveFile}
                className="px-2.5 py-0.5 rounded bg-red-600 text-white font-semibold hover:bg-red-500"
              >
                Save Copy to Disk
              </button>
            </div>
          )}

          {activeTab?.diskConflictContent !== undefined && (
            <div className="px-3 py-1.5 bg-amber-500/15 border-b border-amber-500/40 text-amber-800 dark:text-amber-200 text-xs flex items-center justify-between">
              <span>
                File <strong>{activeTab.title}</strong> has been modified externally on disk.
              </span>
              <div className="flex items-center space-x-2">
                <button
                  onClick={() => {
                    updateActiveTab((t) => ({
                      ...t,
                      content: t.diskConflictContent ?? t.content,
                      savedContent: t.diskConflictContent ?? t.savedContent,
                      diskConflictContent: undefined,
                      isModified: false,
                    }));
                  }}
                  className="px-2 py-0.5 rounded bg-amber-600 text-white font-semibold"
                >
                  Reload from Disk
                </button>
                <button
                  onClick={() => {
                    updateActiveTab((t) => ({
                      ...t,
                      diskConflictContent: undefined,
                      isModified: true,
                    }));
                  }}
                  className="px-2 py-0.5 rounded border border-amber-600/50"
                >
                  Keep My Edits
                </button>
              </div>
            </div>
          )}

          {activeTab ? (
            <EditorArea
              activeTab={activeTab}
              secondaryTab={secondaryTab}
              isSplitView={isSplitView}
              settings={settings}
              diagnostics={diagnostics}
              canUndo={canUndo}
              canRedo={canRedo}
              searchQuery={searchState.isOpen ? searchState.query : undefined}
              onChangeContent={handleChangeContent}
              onUpdateCursor={handleUpdateCursor}
              onToggleBookmark={handleToggleBookmark}
              onUndo={handleUndo}
              onRedo={handleRedo}
              onOpenFind={() => setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'find' }))}
              onOpenReplace={() =>
                setSearchState((p) => ({ ...p, isOpen: true, activeTab: 'replace' }))
              }
              onRunFile={handleRunActiveFile}
              onOpenTerminalHere={() => handleOpenTerminalHere()}
            />
          ) : (
            <div className="flex-1 flex items-center justify-center text-gray-400">
              No document open. Press ⌘N to create a new file.
            </div>
          )}

          {/* Bottom Docked Panel (Terminal, Git, Java, Diagnostics, Diff, Markdown) */}
          <BottomPanel
            isOpen={isBottomPanelOpen}
            isDark={currentTheme.isDark}
            activeTab={activeBottomTab}
            activeDocument={activeTab}
            diagnostics={diagnostics}
            requestedCwd={requestedTerminalCwd}
            externalLogs={externalTerminalLogs}
            isExecutingFile={isExecutingFile}
            onKillExecution={handleKillExecution}
            onSelectTab={(tab) => setActiveBottomTab(tab as any)}
            onClose={() => setIsBottomPanelOpen(false)}
            onJumpToLine={handleJumpToLine}
          />
        </div>
      </div>

      {/* 6. Notepad++ Bottom Status Bar */}
      <StatusBar
        isDark={currentTheme.isDark}
        cursorLine={activeTab?.cursorLine || 1}
        cursorCol={activeTab?.cursorCol || 1}
        selectionLength={
          activeTab ? Math.abs(activeTab.selectionEnd - activeTab.selectionStart) : 0
        }
        totalLines={totalLines}
        encoding={activeTab?.encoding || 'UTF-8'}
        lineEnding={activeTab?.lineEnding || 'LF'}
        languageId={activeTab?.language || 'plaintext'}
        onSetEncoding={handleSetEncoding}
        onSetLineEnding={handleSetLineEnding}
        onSetLanguage={handleSetLanguage}
      />

      {/* Safe Tab Closing Confirmation Modal (Priority 1.4: Save / Don't Save / Cancel) */}
      {pendingCloseDoc && (
        <div
          className="fixed inset-0 bg-black/45 z-50 flex items-center justify-center p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby="save-changes-title"
        >
          <div
            className="w-full max-w-md rounded-md border shadow-2xl p-5 theme-dialog"
            style={{
              backgroundColor: 'var(--theme-dialog-bg)',
              color: 'var(--theme-dialog-fg)',
              borderColor: 'var(--theme-dialog-border)',
            }}
          >
            <h3 id="save-changes-title" className="text-sm font-bold mb-2">
              Save changes to "{pendingCloseDoc.title}" before closing?
            </h3>
            <p className="text-xs opacity-80 mb-5 leading-relaxed">
              Your changes will be lost if you choose "Don't Save". Choosing "Cancel" will keep the
              document open in CodePad.
            </p>
            <div className="flex items-center justify-end space-x-2 text-xs">
              <button
                onClick={() => handleConfirmCloseDecision('dont-save')}
                className="px-3 py-1.5 rounded border border-red-500/50 text-red-600 dark:text-red-400 hover:bg-red-600 hover:text-white font-medium transition-colors"
              >
                Don't Save
              </button>
              <button
                onClick={() => handleConfirmCloseDecision('cancel')}
                className={`px-3 py-1.5 rounded border font-medium transition-colors ${
                  currentTheme.isDark
                    ? 'border-gray-600 hover:bg-gray-700'
                    : 'border-gray-400 hover:bg-gray-200'
                }`}
              >
                Cancel
              </button>
              <button
                onClick={() => handleConfirmCloseDecision('save')}
                className="px-4 py-1.5 rounded bg-blue-600 hover:bg-blue-500 text-white font-semibold shadow-sm transition-colors"
              >
                Save
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toast && (
        <div
          className={`fixed bottom-8 right-6 px-3.5 py-2 rounded shadow-xl text-xs font-medium flex items-center space-x-2 z-50 border transition-all ${
            toast.type === 'success'
              ? 'bg-emerald-700 text-white border-emerald-500'
              : toast.type === 'error'
              ? 'bg-red-700 text-white border-red-500'
              : toast.type === 'warning'
              ? 'bg-amber-700 text-white border-amber-500'
              : 'bg-[#25272a] text-white border-gray-600'
          }`}
        >
          <span>{toast.message}</span>
        </div>
      )}

      {/* Modals & Dialogs */}
      <FindReplaceModal
        searchState={searchState}
        isDark={currentTheme.isDark}
        onUpdateState={(partial) => setSearchState((prev) => ({ ...prev, ...partial }))}
        onClose={() => setSearchState((prev) => ({ ...prev, isOpen: false }))}
        onFindNext={handleFindNext}
        onFindPrev={handleFindPrev}
        onReplace={handleReplace}
        onReplaceAll={handleReplaceAll}
        onMarkAll={handleMarkAll}
        onClearMarks={handleClearBookmarks}
        onCount={handleCountMatches}
      />

      <GoToLineModal
        isOpen={isGoToLineOpen}
        isDark={currentTheme.isDark}
        currentLine={activeTab?.cursorLine || 1}
        totalLines={totalLines}
        onClose={() => setIsGoToLineOpen(false)}
        onGoTo={handleJumpToLine}
      />

      <CommandPalette
        isOpen={isPaletteOpen}
        isDark={currentTheme.isDark}
        commands={paletteCommands}
        onClose={() => setIsPaletteOpen(false)}
      />

      <SettingsModal
        isOpen={isSettingsOpen}
        isDark={currentTheme.isDark}
        settings={settings}
        previewTheme={previewTheme}
        onPreviewTheme={setPreviewTheme}
        onUpdateSettings={(partial) => setSettings((s) => ({ ...s, ...partial }))}
        onClose={() => {
          setPreviewTheme(null);
          setIsSettingsOpen(false);
        }}
      />

      <PluginManagerModal
        isOpen={isPluginModalOpen}
        isDark={currentTheme.isDark}
        plugins={pluginsList}
        onTogglePlugin={(id, enabled) => {
          pluginManager.togglePlugin(id, enabled);
          setPluginsList([...pluginManager.getPlugins()]);
        }}
        onInstallPlugin={(manifest) => {
          const res = pluginManager.installPlugin(manifest);
          if (res.success) {
            setPluginsList([...pluginManager.getPlugins()]);
          }
          return res;
        }}
        onUninstallPlugin={(id) => {
          pluginManager.uninstallPlugin(id);
          setPluginsList([...pluginManager.getPlugins()]);
        }}
        onClose={() => setIsPluginModalOpen(false)}
      />

      <ExportAppModal
        isOpen={isExportModalOpen}
        isDark={currentTheme.isDark}
        onClose={() => setIsExportModalOpen(false)}
      />
    </div>
  );
}
