import { LineEnding, TextEncoding } from './lib/encoding';
import { LanguageDefinition } from './lib/languageEngine';

export interface UndoEntry {
  content: string;
  cursorLine: number;
  cursorCol: number;
  selectionStart: number;
  selectionEnd: number;
  timestamp: number;
  label?: string;
}

export type DocumentLifecycleState =
  | 'untitled-clean'
  | 'untitled-modified'
  | 'disk-clean'
  | 'disk-modified'
  | 'disk-missing'
  | 'disk-conflict';

export interface TabItem {
  id: string;
  title: string;
  path?: string;
  content: string;
  savedContent: string;
  isModified: boolean;
  hasEverBeenSaved?: boolean;
  isMissingOnDisk?: boolean;
  diskConflictContent?: string;
  lastSavedAt?: number;
  lastModifiedAt?: number;
  language: string; // language id
  encoding: TextEncoding;
  lineEnding: LineEnding;
  bookmarks: number[]; // 1-indexed line numbers
  cursorLine: number;
  cursorCol: number;
  selectionStart: number;
  selectionEnd: number;
  scrollTop?: number;
  scrollLeft?: number;
  undoStack?: UndoEntry[];
  redoStack?: UndoEntry[];
}

export type EditorTheme =
  | 'npp-classic'
  | 'macos-dark'
  | 'macos-light'
  | 'monokai'
  | 'dracula'
  | 'solarized';

export interface EditorSettings {
  theme: EditorTheme;
  fontSize: number;
  fontFamily: string;
  tabWidth: number;
  insertSpaces: boolean;
  wordWrap: boolean;
  showWhitespace: boolean;
  showLineNumbers: boolean;
  highlightMatchingBrackets: boolean;
  autoCloseBrackets: boolean;
  autoSave: boolean;
}

export type SearchMode = 'normal' | 'extended' | 'regex';

export interface SearchState {
  isOpen: boolean;
  activeTab: 'find' | 'replace' | 'find-files' | 'mark';
  query: string;
  replaceQuery: string;
  caseSensitive: boolean;
  wholeWord: boolean;
  useRegex: boolean;
  searchMode?: SearchMode;
  direction?: 'up' | 'down';
  wrapAround: boolean;
  fileFilter?: string;
  directoryPath?: string;
  lastMessage: string;
}

