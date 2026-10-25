import { TabItem, UndoEntry, DocumentLifecycleState } from '../types';

export interface RecoverySnapshot {
  documentId: string;
  title: string;
  path?: string;
  recoverableContent: string;
  savedContent: string;
  hasEverBeenSaved: boolean;
  isModified: boolean;
  isMissingOnDisk: boolean;
  language: string;
  encoding: TabItem['encoding'];
  lineEnding: TabItem['lineEnding'];
  bookmarks: number[];
  cursorLine: number;
  cursorCol: number;
  selectionStart: number;
  selectionEnd: number;
  scrollTop: number;
  scrollLeft: number;
  updatedAt: number;
}

export interface WorkspaceSessionData {
  version: number;
  activeTabId: string;
  secondaryTabId?: string;
  isSplitView?: boolean;
  tabOrder: string[];
  documents: RecoverySnapshot[];
  updatedAt: number;
}

export type TabCloseAction = 'save' | 'dont-save' | 'cancel';

const MAX_UNDO_HISTORY = 250;
const TYPING_COALESCE_MS = 450;

/**
 * Computes the authoritative lifecycle state of a document.
 */
export function getDocumentLifecycleState(doc: TabItem): DocumentLifecycleState {
  if (doc.isMissingOnDisk) {
    return 'disk-missing';
  }
  if (doc.diskConflictContent !== undefined && doc.diskConflictContent !== doc.savedContent) {
    return 'disk-conflict';
  }
  const hasSavedBaseline = Boolean(doc.hasEverBeenSaved || doc.path);
  const isDirty = doc.content !== doc.savedContent || doc.isModified;

  if (!hasSavedBaseline) {
    return isDirty ? 'untitled-modified' : 'untitled-clean';
  }
  return isDirty ? 'disk-modified' : 'disk-clean';
}

/**
 * Generates a unique, stable document ID independent of filename.
 */
export function createDocumentId(): string {
  const randomPart = Math.random().toString(36).substring(2, 10);
  return `doc-${Date.now()}-${randomPart}`;
}

/**
 * Creates a brand new untitled document with a unique ID and clean baseline.
 */
export function createUntitledDocument(indexNumber: number): TabItem {
  return {
    id: createDocumentId(),
    title: `new ${indexNumber}`,
    path: undefined,
    content: '',
    savedContent: '',
    isModified: false,
    hasEverBeenSaved: false,
    isMissingOnDisk: false,
    language: 'plaintext',
    encoding: 'UTF-8',
    lineEnding: 'LF',
    bookmarks: [],
    cursorLine: 1,
    cursorCol: 1,
    selectionStart: 0,
    selectionEnd: 0,
    scrollTop: 0,
    scrollLeft: 0,
    undoStack: [],
    redoStack: [],
  };
}

/**
 * Computes 1-indexed cursorLine and cursorCol from a character offset in text.
 */
export function offsetToLineCol(text: string, offset: number): { line: number; col: number } {
  const safeOffset = Math.max(0, Math.min(offset, text.length));
  const prefix = text.slice(0, safeOffset);
  const lines = prefix.split('\n');
  return {
    line: lines.length,
    col: (lines[lines.length - 1]?.length ?? 0) + 1,
  };
}

/**
 * Determines whether two consecutive edits should be coalesced into one undo group
 * (e.g. rapid single-character typing within TYPING_COALESCE_MS without crossing whitespace/newline).
 */
function shouldCoalesceEdit(
  prevContent: string,
  newContent: string,
  lastEntry: UndoEntry | undefined,
  now: number,
  label?: string
): boolean {
  if (!lastEntry) return false;
  if (label && label !== 'typing') return false;
  if (lastEntry.label && lastEntry.label !== 'typing') return false;
  if (now - lastEntry.timestamp > TYPING_COALESCE_MS) return false;

  const lengthDiff = newContent.length - prevContent.length;
  // Only coalesce single-character insertions
  if (lengthDiff !== 1) return false;

  // Do not coalesce if the inserted character is a newline or space boundary
  for (let i = 0; i < newContent.length; i++) {
    if (newContent[i] !== prevContent[i]) {
      const insertedChar = newContent[i];
      if (insertedChar === '\n' || insertedChar === '\r' || insertedChar === ' ' || insertedChar === '\t') {
        return false;
      }
      break;
    }
  }
  return true;
}

/**
 * Records an edit to a document, updating its per-document undo/redo stack,
 * cursor position, and modification state relative to savedContent.
 */
export function recordDocumentEdit(
  doc: TabItem,
  newContent: string,
  options?: {
    selectionStart?: number;
    selectionEnd?: number;
    cursorLine?: number;
    cursorCol?: number;
    label?: string;
    timestamp?: number;
    coalesce?: boolean;
  }
): TabItem {
  if (newContent === doc.content) {
    return doc;
  }

  const now = options?.timestamp ?? Date.now();
  const currentUndoStack = doc.undoStack ? [...doc.undoStack] : [];
  const lastEntry = currentUndoStack[currentUndoStack.length - 1];

  const canCoalesce =
    options?.coalesce === true &&
    shouldCoalesceEdit(doc.content, newContent, lastEntry, now, options?.label);

  if (!canCoalesce) {
    const snapshot: UndoEntry = {
      content: doc.content,
      cursorLine: doc.cursorLine,
      cursorCol: doc.cursorCol,
      selectionStart: doc.selectionStart,
      selectionEnd: doc.selectionEnd,
      timestamp: now,
      label: options?.label ?? 'edit',
    };
    currentUndoStack.push(snapshot);
    if (currentUndoStack.length > MAX_UNDO_HISTORY) {
      currentUndoStack.shift();
    }
  } else if (lastEntry) {
    // Update timestamp of coalesced typing group
    currentUndoStack[currentUndoStack.length - 1] = {
      ...lastEntry,
      timestamp: now,
    };
  }

  const selStart = options?.selectionStart ?? newContent.length;
  const selEnd = options?.selectionEnd ?? selStart;
  const computedPos = offsetToLineCol(newContent, selStart);

  const isModified = Boolean(doc.isMissingOnDisk) || newContent !== doc.savedContent;

  return {
    ...doc,
    content: newContent,
    isModified,
    lastModifiedAt: now,
    selectionStart: selStart,
    selectionEnd: selEnd,
    cursorLine: options?.cursorLine ?? computedPos.line,
    cursorCol: options?.cursorCol ?? computedPos.col,
    undoStack: currentUndoStack,
    redoStack: [], // Any new edit clears the redo stack
  };
}

export function canUndoDocument(doc: TabItem | undefined): boolean {
  return Boolean(doc && doc.undoStack && doc.undoStack.length > 0);
}

export function canRedoDocument(doc: TabItem | undefined): boolean {
  return Boolean(doc && doc.redoStack && doc.redoStack.length > 0);
}

/**
 * Reverts the most recent edit on the given document and pushes the current state to redoStack.
 */
export function undoDocument(doc: TabItem): TabItem {
  if (!doc.undoStack || doc.undoStack.length === 0) {
    return doc;
  }

  const nextUndoStack = [...doc.undoStack];
  const targetState = nextUndoStack.pop()!;

  const currentSnapshot: UndoEntry = {
    content: doc.content,
    cursorLine: doc.cursorLine,
    cursorCol: doc.cursorCol,
    selectionStart: doc.selectionStart,
    selectionEnd: doc.selectionEnd,
    timestamp: Date.now(),
    label: targetState.label,
  };

  const nextRedoStack = [...(doc.redoStack || []), currentSnapshot];
  const isModified = Boolean(doc.isMissingOnDisk) || targetState.content !== doc.savedContent;

  return {
    ...doc,
    content: targetState.content,
    cursorLine: targetState.cursorLine,
    cursorCol: targetState.cursorCol,
    selectionStart: targetState.selectionStart,
    selectionEnd: targetState.selectionEnd,
    isModified,
    lastModifiedAt: Date.now(),
    undoStack: nextUndoStack,
    redoStack: nextRedoStack,
  };
}

/**
 * Reapplies the most recently undone edit on the given document.
 */
export function redoDocument(doc: TabItem): TabItem {
  if (!doc.redoStack || doc.redoStack.length === 0) {
    return doc;
  }

  const nextRedoStack = [...doc.redoStack];
  const targetState = nextRedoStack.pop()!;

  const currentSnapshot: UndoEntry = {
    content: doc.content,
    cursorLine: doc.cursorLine,
    cursorCol: doc.cursorCol,
    selectionStart: doc.selectionStart,
    selectionEnd: doc.selectionEnd,
    timestamp: Date.now(),
    label: targetState.label,
  };

  const nextUndoStack = [...(doc.undoStack || []), currentSnapshot];
  const isModified = Boolean(doc.isMissingOnDisk) || targetState.content !== doc.savedContent;

  return {
    ...doc,
    content: targetState.content,
    cursorLine: targetState.cursorLine,
    cursorCol: targetState.cursorCol,
    selectionStart: targetState.selectionStart,
    selectionEnd: targetState.selectionEnd,
    isModified,
    lastModifiedAt: Date.now(),
    undoStack: nextUndoStack,
    redoStack: nextRedoStack,
  };
}

/**
 * Marks a document as saved (updating savedContent baseline without losing undo history).
 */
export function markDocumentSaved(doc: TabItem, newPath?: string, newTitle?: string): TabItem {
  const resolvedPath = newPath ?? doc.path;
  const resolvedTitle = newTitle ?? (resolvedPath ? resolvedPath.split('/').pop() || doc.title : doc.title);
  return {
    ...doc,
    path: resolvedPath,
    title: resolvedTitle,
    savedContent: doc.content,
    isModified: false,
    hasEverBeenSaved: true,
    isMissingOnDisk: false,
    diskConflictContent: undefined,
    lastSavedAt: Date.now(),
  };
}

/**
 * Marks a disk-backed document whose underlying file was moved or deleted.
 * Preserves recoverable content and marks it modified so the user never loses data.
 */
export function handleMissingDiskFile(doc: TabItem): TabItem {
  return {
    ...doc,
    isMissingOnDisk: true,
    isModified: true,
  };
}

/**
 * Detects whether an external change occurred on disk and updates conflict state.
 * If the document has no unsaved edits, optionally reloads cleanly; if it has unsaved edits,
 * records diskConflictContent so the user can choose whether to reload or keep their edits.
 */
export function detectExternalFileConflict(
  doc: TabItem,
  currentDiskContent: string,
  autoReloadIfClean = false
): TabItem {
  if (currentDiskContent === doc.savedContent) {
    return doc;
  }

  const hasUnsavedEdits = doc.isModified || doc.content !== doc.savedContent;
  if (!hasUnsavedEdits && autoReloadIfClean) {
    return {
      ...doc,
      content: currentDiskContent,
      savedContent: currentDiskContent,
      isModified: false,
      isMissingOnDisk: false,
      diskConflictContent: undefined,
    };
  }

  return {
    ...doc,
    diskConflictContent: currentDiskContent,
  };
}

/**
 * Evaluates closing a tab according to the user's Save / Don't Save / Cancel choice.
 */
export function applyTabCloseDecision(
  tabs: TabItem[],
  activeTabId: string,
  targetTabId: string,
  decision: TabCloseAction,
  onSaveCallback?: (savedDoc: TabItem) => void
): {
  tabs: TabItem[];
  activeTabId: string;
  closed: boolean;
  discardedRecoveryId?: string;
} {
  const targetIdx = tabs.findIndex((t) => t.id === targetTabId);
  if (targetIdx === -1) {
    return { tabs, activeTabId, closed: false };
  }

  const targetDoc = tabs[targetIdx];

  if (decision === 'cancel') {
    return { tabs, activeTabId, closed: false };
  }

  if (decision === 'save') {
    const savedDoc = markDocumentSaved(targetDoc);
    if (onSaveCallback) {
      onSaveCallback(savedDoc);
    }
  }

  const remaining = tabs.filter((t) => t.id !== targetTabId);
  let nextTabs = remaining;
  let nextActiveId = activeTabId;

  if (remaining.length === 0) {
    const freshDoc = createUntitledDocument(1);
    nextTabs = [freshDoc];
    nextActiveId = freshDoc.id;
  } else if (activeTabId === targetTabId) {
    const fallbackIdx = Math.min(targetIdx, remaining.length - 1);
    nextActiveId = remaining[fallbackIdx].id;
  }

  return {
    tabs: nextTabs,
    activeTabId: nextActiveId,
    closed: true,
    discardedRecoveryId: targetTabId,
  };
}

/**
 * Creates a serializable recovery snapshot for a document.
 * Importantly, `recoverableContent` stores the latest unsaved text while `savedContent`
 * preserves the last known on-disk baseline so the original file is never overwritten until Save.
 */
export function createRecoverySnapshot(doc: TabItem): RecoverySnapshot {
  const isModified = Boolean(doc.isMissingOnDisk) || doc.content !== doc.savedContent || doc.isModified;
  return {
    documentId: doc.id,
    title: doc.title,
    path: doc.path,
    recoverableContent: doc.content,
    savedContent: doc.savedContent,
    hasEverBeenSaved: Boolean(doc.hasEverBeenSaved || doc.path),
    isModified,
    isMissingOnDisk: Boolean(doc.isMissingOnDisk),
    language: doc.language,
    encoding: doc.encoding,
    lineEnding: doc.lineEnding,
    bookmarks: doc.bookmarks || [],
    cursorLine: doc.cursorLine || 1,
    cursorCol: doc.cursorCol || 1,
    selectionStart: doc.selectionStart || 0,
    selectionEnd: doc.selectionEnd || 0,
    scrollTop: doc.scrollTop || 0,
    scrollLeft: doc.scrollLeft || 0,
    updatedAt: Date.now(),
  };
}

/**
 * Serializes the entire workspace session for persistence across application restarts.
 */
export function serializeWorkspaceSession(
  tabs: TabItem[],
  activeTabId: string,
  secondaryTabId?: string,
  isSplitView?: boolean
): WorkspaceSessionData {
  return {
    version: 2,
    activeTabId,
    secondaryTabId,
    isSplitView,
    tabOrder: tabs.map((t) => t.id),
    documents: tabs.map(createRecoverySnapshot),
    updatedAt: Date.now(),
  };
}

/**
 * Restores a workspace session from persisted WorkspaceSessionData, preserving
 * tab order, active tab, untitled documents, unsaved edits to existing files,
 * and missing-file status.
 */
export function deserializeWorkspaceSession(
  session: WorkspaceSessionData,
  diskFileChecker?: (path: string) => { exists: boolean; diskContent?: string }
): {
  tabs: TabItem[];
  activeTabId: string;
  secondaryTabId?: string;
  isSplitView: boolean;
} {
  const docMap = new Map<string, TabItem>();

  for (const snap of session.documents) {
    let isMissingOnDisk = Boolean(snap.isMissingOnDisk);
    let savedBaseline = snap.savedContent;
    let diskConflictContent: string | undefined = undefined;

    if (snap.path && diskFileChecker) {
      const check = diskFileChecker(snap.path);
      if (!check.exists) {
        isMissingOnDisk = true;
      } else if (check.diskContent !== undefined && check.diskContent !== snap.savedContent) {
        // Disk file changed while app was closed
        if (!snap.isModified && snap.recoverableContent === snap.savedContent) {
          savedBaseline = check.diskContent;
          snap.recoverableContent = check.diskContent;
        } else {
          diskConflictContent = check.diskContent;
        }
      }
    }

    const isModified = isMissingOnDisk || snap.recoverableContent !== savedBaseline || snap.isModified;

    const restoredTab: TabItem = {
      id: snap.documentId,
      title: snap.title,
      path: snap.path,
      content: snap.recoverableContent,
      savedContent: savedBaseline,
      isModified,
      hasEverBeenSaved: snap.hasEverBeenSaved,
      isMissingOnDisk,
      diskConflictContent,
      language: snap.language || 'plaintext',
      encoding: snap.encoding || 'UTF-8',
      lineEnding: snap.lineEnding || 'LF',
      bookmarks: Array.isArray(snap.bookmarks) ? snap.bookmarks : [],
      cursorLine: snap.cursorLine || 1,
      cursorCol: snap.cursorCol || 1,
      selectionStart: snap.selectionStart || 0,
      selectionEnd: snap.selectionEnd || 0,
      scrollTop: snap.scrollTop || 0,
      scrollLeft: snap.scrollLeft || 0,
      undoStack: [],
      redoStack: [],
    };

    docMap.set(restoredTab.id, restoredTab);
  }

  // Restore exact tab order
  const orderedTabs: TabItem[] = [];
  if (Array.isArray(session.tabOrder)) {
    for (const id of session.tabOrder) {
      const found = docMap.get(id);
      if (found) {
        orderedTabs.push(found);
        docMap.delete(id);
      }
    }
  }
  for (const remainingDoc of docMap.values()) {
    orderedTabs.push(remainingDoc);
  }

  if (orderedTabs.length === 0) {
    const fallback = createUntitledDocument(1);
    return {
      tabs: [fallback],
      activeTabId: fallback.id,
      isSplitView: false,
    };
  }

  const resolvedActiveId = orderedTabs.some((t) => t.id === session.activeTabId)
    ? session.activeTabId
    : orderedTabs[0].id;

  return {
    tabs: orderedTabs,
    activeTabId: resolvedActiveId,
    secondaryTabId: session.secondaryTabId,
    isSplitView: Boolean(session.isSplitView),
  };
}
