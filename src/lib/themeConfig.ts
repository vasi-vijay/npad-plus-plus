import { EditorTheme } from '../types';

export interface ThemeStyles {
  background: string;
  foreground: string;
  gutterBg: string;
  gutterFg: string;
  gutterBorder: string;
  activeLineBg: string;
  selectionBg: string;
  matchedBracketBg: string;
  tabBg: string;
  tabActiveBg: string;
  tabBorder: string;
  keywordColor: string;
  typeColor: string;
  stringColor: string;
  commentColor: string;
  numberColor: string;
  annotationColor: string;
  operatorColor: string;
  // Scrollbar colors
  scrollbarThumb: string;
  scrollbarThumbHover: string;
  scrollbarTrack: string;
  // Custom dialogs / modal colors
  dialogBg: string;
  dialogHeaderBg: string;
  dialogBorder: string;
  dialogFg: string;
  inputBg: string;
  inputBorder: string;
  inputFg: string;
}

export interface ThemeDefinition {
  name: string;
  isDark: boolean;
  styles: ThemeStyles;
}

export const THEMES: Record<EditorTheme, { name: string; isDark: boolean; styles: ThemeStyles }> = {
  'npp-classic': {
    name: 'Notepad++ Classic',
    isDark: false,
    styles: {
      background: '#ffffff',
      foreground: '#000000',
      gutterBg: '#f0f0f0',
      gutterFg: '#606060', // 5.8:1 contrast against #f0f0f0
      gutterBorder: '#d4d4d4',
      activeLineBg: '#e8f2fe',
      selectionBg: '#cce8ff',
      matchedBracketBg: '#b3d7ff',
      tabBg: '#e6e6e6',
      tabActiveBg: '#ffffff',
      tabBorder: '#cccccc',
      keywordColor: '#0000ff', // 8.6:1 against #ffffff
      typeColor: '#1b758e',    // 4.9:1 against #ffffff (WCAG AA compliant)
      stringColor: '#a31515',   // 7.8:1 against #ffffff
      commentColor: '#008000',  // 4.5:1 against #ffffff
      numberColor: '#b85400',   // 4.8:1 against #ffffff (WCAG AA compliant)
      annotationColor: '#795e26',
      operatorColor: '#000000',
      // Scrollbars
      scrollbarThumb: 'rgba(0, 0, 0, 0.22)',
      scrollbarThumbHover: 'rgba(0, 0, 0, 0.45)',
      scrollbarTrack: 'rgba(0, 0, 0, 0.03)',
      // Dialogs
      dialogBg: '#f8f9fa',
      dialogHeaderBg: '#eaedf1',
      dialogBorder: '#c2c8d0',
      dialogFg: '#111827',
      inputBg: '#ffffff',
      inputBorder: '#9ca3af',
      inputFg: '#111827',
    },
  },
  'macos-dark': {
    name: 'macOS Sonoma Dark',
    isDark: true,
    styles: {
      background: '#1e1e1e',
      foreground: '#d4d4d4',
      gutterBg: '#181818',
      gutterFg: '#858585',
      gutterBorder: '#2d2d2d',
      activeLineBg: '#282828',
      selectionBg: '#264f78',
      matchedBracketBg: '#3d3d3d',
      tabBg: '#181818',
      tabActiveBg: '#1e1e1e',
      tabBorder: '#2d2d2d',
      keywordColor: '#569cd6',
      typeColor: '#4ec9b0',
      stringColor: '#ce9178',
      commentColor: '#6a9955',
      numberColor: '#b5cea8',
      annotationColor: '#dcdcaa',
      operatorColor: '#d4d4d4',
      // Scrollbars
      scrollbarThumb: 'rgba(255, 255, 255, 0.20)',
      scrollbarThumbHover: 'rgba(255, 255, 255, 0.38)',
      scrollbarTrack: 'rgba(0, 0, 0, 0.25)',
      // Dialogs
      dialogBg: '#25272a',
      dialogHeaderBg: '#1c1e20',
      dialogBorder: '#383b40',
      dialogFg: '#e6edf3',
      inputBg: '#181a1d',
      inputBorder: '#4a4e56',
      inputFg: '#f0f3f6',
    },
  },
  'macos-light': {
    name: 'macOS Sonoma Light',
    isDark: false,
    styles: {
      background: '#ffffff',
      foreground: '#24292f',
      gutterBg: '#f6f8fa',
      gutterFg: '#8c959f',
      gutterBorder: '#d0d7de',
      activeLineBg: '#f3f4f6',
      selectionBg: '#b6e3ff',
      matchedBracketBg: '#ddf4ff',
      tabBg: '#eaeef2',
      tabActiveBg: '#ffffff',
      tabBorder: '#d0d7de',
      keywordColor: '#cf222e',
      typeColor: '#953800',
      stringColor: '#0a3069',
      commentColor: '#6e7781',
      numberColor: '#0550ae',
      annotationColor: '#8250df',
      operatorColor: '#24292f',
      // Scrollbars
      scrollbarThumb: 'rgba(0, 0, 0, 0.20)',
      scrollbarThumbHover: 'rgba(0, 0, 0, 0.42)',
      scrollbarTrack: 'rgba(0, 0, 0, 0.03)',
      // Dialogs
      dialogBg: '#f6f8fa',
      dialogHeaderBg: '#eaeef2',
      dialogBorder: '#d0d7de',
      dialogFg: '#1f2328',
      inputBg: '#ffffff',
      inputBorder: '#afb8c1',
      inputFg: '#1f2328',
    },
  },
  'monokai': {
    name: 'Monokai Dark',
    isDark: true,
    styles: {
      background: '#272822',
      foreground: '#f8f8f2',
      gutterBg: '#1e1f1c',
      gutterFg: '#75715e',
      gutterBorder: '#3e3d32',
      activeLineBg: '#3e3d32',
      selectionBg: '#49483e',
      matchedBracketBg: '#66d9ef44',
      tabBg: '#1e1f1c',
      tabActiveBg: '#272822',
      tabBorder: '#3e3d32',
      keywordColor: '#f92672',
      typeColor: '#66d9ef',
      stringColor: '#e6db74',
      commentColor: '#75715e',
      numberColor: '#ae81ff',
      annotationColor: '#a6e22e',
      operatorColor: '#f8f8f2',
      // Scrollbars
      scrollbarThumb: 'rgba(255, 255, 255, 0.22)',
      scrollbarThumbHover: 'rgba(255, 255, 255, 0.40)',
      scrollbarTrack: 'rgba(0, 0, 0, 0.35)',
      // Dialogs
      dialogBg: '#2c2d26',
      dialogHeaderBg: '#22231d',
      dialogBorder: '#48493d',
      dialogFg: '#f8f8f2',
      inputBg: '#1e1f1c',
      inputBorder: '#5b5a4b',
      inputFg: '#f8f8f2',
    },
  },
  'dracula': {
    name: 'Dracula Pro',
    isDark: true,
    styles: {
      background: '#282a36',
      foreground: '#f8f8f2',
      gutterBg: '#21222c',
      gutterFg: '#6272a4',
      gutterBorder: '#44475a',
      activeLineBg: '#343746',
      selectionBg: '#44475a',
      matchedBracketBg: '#bd93f944',
      tabBg: '#191a21',
      tabActiveBg: '#282a36',
      tabBorder: '#44475a',
      keywordColor: '#ff79c6',
      typeColor: '#8be9fd',
      stringColor: '#f1fa8c',
      commentColor: '#6272a4',
      numberColor: '#bd93f9',
      annotationColor: '#50fa7b',
      operatorColor: '#ff79c6',
      // Scrollbars
      scrollbarThumb: 'rgba(189, 147, 249, 0.35)',
      scrollbarThumbHover: 'rgba(189, 147, 249, 0.55)',
      scrollbarTrack: 'rgba(25, 26, 33, 0.50)',
      // Dialogs
      dialogBg: '#2c2e3b',
      dialogHeaderBg: '#21222c',
      dialogBorder: '#4d5066',
      dialogFg: '#f8f8f2',
      inputBg: '#1f202a',
      inputBorder: '#6272a4',
      inputFg: '#f8f8f2',
    },
  },
  'solarized': {
    name: 'Solarized Dark',
    isDark: true,
    styles: {
      background: '#002b36',
      foreground: '#839496',
      gutterBg: '#073642',
      gutterFg: '#586e75',
      gutterBorder: '#073642',
      activeLineBg: '#073642',
      selectionBg: '#073642',
      matchedBracketBg: '#2aa19844',
      tabBg: '#00212b',
      tabActiveBg: '#002b36',
      tabBorder: '#073642',
      keywordColor: '#859900',
      typeColor: '#b58900',
      stringColor: '#2aa198',
      commentColor: '#586e75',
      numberColor: '#d33682',
      annotationColor: '#cb4b16',
      operatorColor: '#268bd2',
      // Scrollbars
      scrollbarThumb: 'rgba(42, 161, 152, 0.35)',
      scrollbarThumbHover: 'rgba(42, 161, 152, 0.55)',
      scrollbarTrack: 'rgba(0, 33, 43, 0.50)',
      // Dialogs
      dialogBg: '#05313d',
      dialogHeaderBg: '#00252e',
      dialogBorder: '#0f4857',
      dialogFg: '#93a1a1',
      inputBg: '#00212b',
      inputBorder: '#1c5261',
      inputFg: '#93a1a1',
    },
  },
};

/**
 * Applies all theme CSS custom properties to the document root and body,
 * controlling scrollbars, custom dialogs, editor colors, and dark mode class.
 */
export function applyThemeVariables(theme: ThemeDefinition, fontFamily?: string): void {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  const s = theme.styles;

  // Editor colors
  root.style.setProperty('--theme-bg', s.background);
  root.style.setProperty('--theme-fg', s.foreground);
  root.style.setProperty('--theme-gutter-bg', s.gutterBg);
  root.style.setProperty('--theme-gutter-fg', s.gutterFg);
  root.style.setProperty('--theme-gutter-border', s.gutterBorder);
  root.style.setProperty('--theme-active-line-bg', s.activeLineBg);
  root.style.setProperty('--theme-selection-bg', s.selectionBg);
  root.style.setProperty('--theme-matched-bracket-bg', s.matchedBracketBg);
  root.style.setProperty('--theme-tab-bg', s.tabBg);
  root.style.setProperty('--theme-tab-active-bg', s.tabActiveBg);
  root.style.setProperty('--theme-tab-border', s.tabBorder);

  // Syntax tokens
  root.style.setProperty('--theme-keyword', s.keywordColor);
  root.style.setProperty('--theme-type', s.typeColor);
  root.style.setProperty('--theme-string', s.stringColor);
  root.style.setProperty('--theme-comment', s.commentColor);
  root.style.setProperty('--theme-number', s.numberColor);
  root.style.setProperty('--theme-annotation', s.annotationColor);
  root.style.setProperty('--theme-operator', s.operatorColor);

  // Scrollbars
  root.style.setProperty('--theme-scrollbar-thumb', s.scrollbarThumb);
  root.style.setProperty('--theme-scrollbar-thumb-hover', s.scrollbarThumbHover);
  root.style.setProperty('--theme-scrollbar-track', s.scrollbarTrack);

  // Custom Dialogs & Modals
  root.style.setProperty('--theme-dialog-bg', s.dialogBg);
  root.style.setProperty('--theme-dialog-header-bg', s.dialogHeaderBg);
  root.style.setProperty('--theme-dialog-border', s.dialogBorder);
  root.style.setProperty('--theme-dialog-fg', s.dialogFg);
  root.style.setProperty('--theme-input-bg', s.inputBg);
  root.style.setProperty('--theme-input-border', s.inputBorder);
  root.style.setProperty('--theme-input-fg', s.inputFg);

  if (fontFamily) {
    root.style.setProperty('--editor-font-family', fontFamily);
  }

  if (theme.isDark) {
    root.classList.add('dark');
  } else {
    root.classList.remove('dark');
  }
}
