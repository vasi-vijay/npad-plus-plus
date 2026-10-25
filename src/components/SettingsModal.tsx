import React, { useState } from 'react';
import { EditorSettings, EditorTheme } from '../types';
import { THEMES } from '../lib/themeConfig';
import { X, Check, Eye, Type, Sliders, Palette } from 'lucide-react';

interface SettingsModalProps {
  isOpen: boolean;
  isDark: boolean;
  settings: EditorSettings;
  previewTheme?: EditorTheme | null;
  onPreviewTheme?: (theme: EditorTheme | null) => void;
  onUpdateSettings: (partial: Partial<EditorSettings>) => void;
  onClose: () => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({
  isOpen,
  settings,
  previewTheme,
  onPreviewTheme,
  onUpdateSettings,
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState<'themes' | 'typography' | 'editor'>('themes');

  if (!isOpen) return null;

  const effectiveThemeKey = previewTheme || settings.theme;
  const currentTheme = THEMES[effectiveThemeKey] || THEMES['npp-classic'];
  const isPreviewing = Boolean(previewTheme && previewTheme !== settings.theme);

  const handleClose = () => {
    if (onPreviewTheme) onPreviewTheme(null);
    onClose();
  };

  const FONT_OPTIONS = [
    {
      label: 'JetBrains Mono (Recommended)',
      value: "'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
    },
    {
      label: 'SF Mono (macOS Native)',
      value: "-apple-system-monospaced, 'SF Mono', SFMono-Regular, Menlo, Monaco, Consolas, monospace",
    },
    {
      label: 'Fira Code',
      value: "'Fira Code', 'JetBrains Mono', Menlo, Consolas, monospace",
    },
    {
      label: 'Menlo',
      value: "Menlo, Monaco, Consolas, 'Courier New', monospace",
    },
    {
      label: 'Courier New',
      value: "'Courier New', Courier, monospace",
    },
    {
      label: 'System Monospace',
      value: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace",
    },
  ];

  return (
    <div
      className="fixed inset-0 bg-black/55 z-50 flex items-center justify-center p-4 backdrop-blur-xs transition-opacity duration-150"
      onClick={handleClose}
    >
      <div
        className="w-full max-w-2xl rounded-lg border shadow-2xl overflow-hidden theme-dialog transition-colors duration-150 flex flex-col max-h-[88vh]"
        style={{
          backgroundColor: 'var(--theme-dialog-bg)',
          color: 'var(--theme-dialog-fg)',
          borderColor: 'var(--theme-dialog-border)',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          className="px-4 py-3 border-b flex items-center justify-between theme-dialog-header"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          <div className="flex items-center space-x-2">
            <Palette className="w-4 h-4 text-blue-500" />
            <span className="font-bold text-sm tracking-tight">Notepad++ Preferences — macOS Edition</span>
          </div>
          <button
            onClick={handleClose}
            aria-label="Close preferences"
            className="p-1 rounded hover:bg-black/10 dark:hover:bg-white/10 transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div
          className="flex border-b text-xs font-semibold px-4 pt-2 space-x-2"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          <button
            onClick={() => setActiveTab('themes')}
            className={`pb-2 px-3 flex items-center space-x-1.5 border-b-2 transition-colors ${
              activeTab === 'themes'
                ? 'border-blue-500 text-blue-500 font-bold'
                : 'border-transparent opacity-70 hover:opacity-100'
            }`}
          >
            <Palette className="w-3.5 h-3.5" />
            <span>Themes & Real-Time Preview</span>
          </button>
          <button
            onClick={() => setActiveTab('typography')}
            className={`pb-2 px-3 flex items-center space-x-1.5 border-b-2 transition-colors ${
              activeTab === 'typography'
                ? 'border-blue-500 text-blue-500 font-bold'
                : 'border-transparent opacity-70 hover:opacity-100'
            }`}
          >
            <Type className="w-3.5 h-3.5" />
            <span>Fonts & Typography</span>
          </button>
          <button
            onClick={() => setActiveTab('editor')}
            className={`pb-2 px-3 flex items-center space-x-1.5 border-b-2 transition-colors ${
              activeTab === 'editor'
                ? 'border-blue-500 text-blue-500 font-bold'
                : 'border-transparent opacity-70 hover:opacity-100'
            }`}
          >
            <Sliders className="w-3.5 h-3.5" />
            <span>Editor Behavior</span>
          </button>
        </div>

        {/* Body */}
        <div className="p-5 space-y-5 text-xs overflow-y-auto flex-1">
          {/* TAB 1: THEMES WITH REAL-TIME PREVIEW */}
          {activeTab === 'themes' && (
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <span className="font-bold text-sm block">Theme Selection</span>
                  <span className="opacity-70 text-[11px]">
                    Hover over any theme to preview changes in real-time across the editor, dialogs, and scrollbars.
                  </span>
                </div>
                <div
                  className={`px-2.5 py-1 rounded text-[11px] font-mono flex items-center space-x-1.5 border transition-all ${
                    isPreviewing
                      ? 'bg-amber-500/15 border-amber-500/40 text-amber-600 dark:text-amber-400 font-semibold'
                      : 'bg-blue-500/10 border-blue-500/25 text-blue-600 dark:text-blue-400'
                  }`}
                >
                  <Eye className="w-3 h-3" />
                  <span>
                    {isPreviewing
                      ? `Previewing: ${currentTheme.name}`
                      : `Active: ${THEMES[settings.theme]?.name || settings.theme}`}
                  </span>
                </div>
              </div>

              {/* Theme Grid */}
              <div
                className="grid grid-cols-2 gap-2.5"
                onMouseLeave={() => {
                  if (onPreviewTheme) onPreviewTheme(null);
                }}
              >
                {(Object.keys(THEMES) as EditorTheme[]).map((themeKey) => {
                  const isSelected = settings.theme === themeKey;
                  const isHoverPreview = previewTheme === themeKey;
                  const t = THEMES[themeKey];

                  return (
                    <button
                      key={themeKey}
                      onMouseEnter={() => {
                        if (onPreviewTheme) onPreviewTheme(themeKey);
                      }}
                      onFocus={() => {
                        if (onPreviewTheme) onPreviewTheme(themeKey);
                      }}
                      onClick={() => {
                        onUpdateSettings({ theme: themeKey });
                        if (onPreviewTheme) onPreviewTheme(null);
                      }}
                      className={`p-3 rounded-lg border text-left flex items-center justify-between transition-all duration-100 ${
                        isSelected
                          ? 'border-blue-500 ring-2 ring-blue-500/30 font-semibold shadow-sm'
                          : isHoverPreview
                          ? 'border-amber-500 ring-2 ring-amber-500/30'
                          : 'border-gray-300 dark:border-gray-700 hover:border-gray-400'
                      }`}
                      style={{
                        backgroundColor: t.styles.background,
                        color: t.styles.foreground,
                      }}
                      title={`Click to apply ${t.name}. Hover to preview.`}
                    >
                      <div className="flex items-center space-x-2.5 truncate">
                        {/* Theme palette dots */}
                        <div className="flex -space-x-1 flex-shrink-0">
                          <span
                            className="w-3.5 h-3.5 rounded-full border border-black/20 shadow-xs"
                            style={{ backgroundColor: t.styles.background }}
                          />
                          <span
                            className="w-3.5 h-3.5 rounded-full border border-black/20 shadow-xs"
                            style={{ backgroundColor: t.styles.keywordColor }}
                          />
                          <span
                            className="w-3.5 h-3.5 rounded-full border border-black/20 shadow-xs"
                            style={{ backgroundColor: t.styles.typeColor }}
                          />
                        </div>
                        <span className="truncate text-xs">{t.name}</span>
                      </div>

                      <div className="flex items-center space-x-1.5 flex-shrink-0 ml-2">
                        {t.isDark ? (
                          <span className="text-[10px] px-1.5 py-0.5 rounded bg-black/30 opacity-70">Dark</span>
                        ) : (
                          <span className="text-[10px] px-1.5 py-0.5 rounded bg-black/10 opacity-70">Light</span>
                        )}
                        {isSelected && <Check className="w-3.5 h-3.5 text-blue-500 stroke-[3]" />}
                      </div>
                    </button>
                  );
                })}
              </div>

              {/* Real-Time Live Mini Editor Preview Card */}
              <div className="mt-4 pt-4 border-t" style={{ borderColor: 'var(--theme-dialog-border)' }}>
                <div className="flex items-center justify-between mb-2">
                  <span className="font-bold text-xs uppercase tracking-wider opacity-75">
                    Live Code Syntax & Scrollbar Preview
                  </span>
                  <span className="text-[11px] opacity-60 font-mono">
                    {currentTheme.name} ({currentTheme.isDark ? 'Dark Mode' : 'Light Mode'})
                  </span>
                </div>

                <div
                  className="rounded-lg border overflow-hidden font-editor-code text-[12px] leading-relaxed shadow-inner"
                  style={{
                    backgroundColor: currentTheme.styles.background,
                    color: currentTheme.styles.foreground,
                    borderColor: currentTheme.styles.gutterBorder,
                    fontFamily: settings.fontFamily,
                  }}
                >
                  {/* Mini Window Bar */}
                  <div
                    className="px-3 py-1.5 border-b flex items-center justify-between text-[11px]"
                    style={{
                      backgroundColor: currentTheme.styles.tabBg,
                      borderColor: currentTheme.styles.tabBorder,
                      color: currentTheme.styles.foreground,
                    }}
                  >
                    <div className="flex items-center space-x-1.5">
                      <span className="w-2.5 h-2.5 rounded-full bg-red-400 inline-block opacity-80" />
                      <span className="w-2.5 h-2.5 rounded-full bg-amber-400 inline-block opacity-80" />
                      <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 inline-block opacity-80" />
                      <span className="ml-2 font-medium">Preview.java</span>
                    </div>
                    <span className="text-[10px] opacity-60">UTF-8 · LF</span>
                  </div>

                  {/* Mini Code Body with Gutter */}
                  <div className="flex max-h-36 overflow-y-auto">
                    {/* Gutter */}
                    <div
                      className="px-2.5 py-2 text-right select-none border-r opacity-80 text-[11px]"
                      style={{
                        backgroundColor: currentTheme.styles.gutterBg,
                        color: currentTheme.styles.gutterFg,
                        borderColor: currentTheme.styles.gutterBorder,
                        minWidth: '38px',
                      }}
                    >
                      <div>1</div>
                      <div style={{ color: currentTheme.styles.foreground, fontWeight: 700 }}>2</div>
                      <div>3</div>
                      <div>4</div>
                      <div>5</div>
                    </div>

                    {/* Code Lines */}
                    <div className="p-2 flex-1 space-y-0.5 whitespace-pre overflow-x-auto">
                      <div>
                        <span style={{ color: currentTheme.styles.commentColor }}>
                          {'// Live theme preview in CodePad'}
                        </span>
                      </div>
                      <div
                        className="px-1 rounded-xs"
                        style={{ backgroundColor: currentTheme.styles.activeLineBg }}
                      >
                        <span style={{ color: currentTheme.styles.keywordColor, fontWeight: 600 }}>public class </span>
                        <span style={{ color: currentTheme.styles.typeColor }}>Calculator </span>
                        <span>{'{'}</span>
                      </div>
                      <div className="pl-4">
                        <span style={{ color: currentTheme.styles.keywordColor, fontWeight: 600 }}>public static void </span>
                        <span style={{ color: currentTheme.styles.typeColor }}>main</span>
                        <span>(String[] args) {'{'}</span>
                      </div>
                      <div className="pl-8">
                        <span style={{ color: currentTheme.styles.typeColor }}>System</span>.out.println(
                        <span style={{ color: currentTheme.styles.stringColor }}>"Result = "</span> +{' '}
                        <span style={{ color: currentTheme.styles.numberColor }}>42</span>
                        );
                      </div>
                      <div className="pl-4">
                        <span>{'}'}</span>
                      </div>
                      <div>
                        <span>{'}'}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: TYPOGRAPHY & FONT FIXING */}
          {activeTab === 'typography' && (
            <div className="space-y-5">
              <div>
                <label className="font-bold text-xs block mb-1.5">Monospace Font Family:</label>
                <select
                  value={settings.fontFamily}
                  onChange={(e) => onUpdateSettings({ fontFamily: e.target.value })}
                  className="w-full px-3 py-2 rounded-md border text-xs theme-dialog-input outline-none font-mono transition-colors"
                  style={{
                    backgroundColor: 'var(--theme-input-bg)',
                    borderColor: 'var(--theme-input-border)',
                    color: 'var(--theme-input-fg)',
                  }}
                >
                  {FONT_OPTIONS.map((f) => (
                    <option key={f.value} value={f.value}>
                      {f.label}
                    </option>
                  ))}
                </select>
                <p className="mt-1 text-[11px] opacity-70">
                  Controls editor panes, line-number gutter, and syntax token layers with subpixel font smoothing.
                </p>
              </div>

              {/* Font Size & Line Height */}
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div>
                  <div className="flex justify-between items-center mb-1.5">
                    <label className="font-bold text-xs">Font Size:</label>
                    <span className="font-mono font-bold text-blue-500">{settings.fontSize} px</span>
                  </div>
                  <input
                    type="range"
                    min="10"
                    max="24"
                    value={settings.fontSize}
                    onChange={(e) => onUpdateSettings({ fontSize: parseInt(e.target.value, 10) })}
                    className="w-full accent-blue-600 cursor-pointer"
                  />
                  <div className="flex justify-between text-[10px] opacity-50 mt-1">
                    <span>10px</span>
                    <span>13px (Default)</span>
                    <span>24px</span>
                  </div>
                </div>

                <div>
                  <label className="font-bold text-xs block mb-1.5">Tab Size & Indentation:</label>
                  <select
                    value={settings.tabWidth}
                    onChange={(e) => onUpdateSettings({ tabWidth: parseInt(e.target.value, 10) })}
                    className="w-full px-3 py-1.5 rounded-md border text-xs theme-dialog-input outline-none"
                    style={{
                      backgroundColor: 'var(--theme-input-bg)',
                      borderColor: 'var(--theme-input-border)',
                      color: 'var(--theme-input-fg)',
                    }}
                  >
                    <option value="2">2 spaces</option>
                    <option value="4">4 spaces (Standard)</option>
                    <option value="8">8 spaces</option>
                  </select>
                </div>
              </div>

              {/* Live Font Sample */}
              <div className="pt-2 border-t" style={{ borderColor: 'var(--theme-dialog-border)' }}>
                <span className="font-bold text-xs block mb-2 opacity-75 uppercase tracking-wider">
                  Font Rendering Sample ({settings.fontSize}px)
                </span>
                <div
                  className="p-3 rounded-lg border font-editor-code leading-relaxed"
                  style={{
                    fontFamily: settings.fontFamily,
                    fontSize: `${settings.fontSize}px`,
                    backgroundColor: 'var(--theme-input-bg)',
                    borderColor: 'var(--theme-input-border)',
                    color: 'var(--theme-input-fg)',
                  }}
                >
                  <div className="text-gray-400 text-xs mb-1">
                    0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz
                  </div>
                  <div>const greet = (name: string): string =&gt; `Hello, ${'{'}name{'}'}!`;</div>
                  <div className="text-xs text-blue-500/80 mt-1">
                    -&gt; =&gt; != == &lt;= &gt;= /* Crisp ligatures and fixed-width alignment */
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: EDITOR BEHAVIOR */}
          {activeTab === 'editor' && (
            <div className="space-y-3">
              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.wordWrap}
                  onChange={(e) => onUpdateSettings({ wordWrap: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Word wrap long lines</span>
              </label>

              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.showWhitespace}
                  onChange={(e) => onUpdateSettings({ showWhitespace: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Show whitespace and tab characters (· and →)</span>
              </label>

              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.showLineNumbers}
                  onChange={(e) => onUpdateSettings({ showLineNumbers: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Show line numbers in gutter</span>
              </label>

              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.highlightMatchingBrackets}
                  onChange={(e) => onUpdateSettings({ highlightMatchingBrackets: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Highlight matching braces, brackets, and parentheses</span>
              </label>

              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.autoCloseBrackets}
                  onChange={(e) => onUpdateSettings({ autoCloseBrackets: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Auto-close quotes and brackets while typing</span>
              </label>

              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.insertSpaces}
                  onChange={(e) => onUpdateSettings({ insertSpaces: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Insert spaces instead of tab characters</span>
              </label>

              <label className="flex items-center space-x-2.5 cursor-pointer py-1">
                <input
                  type="checkbox"
                  checked={settings.autoSave}
                  onChange={(e) => onUpdateSettings({ autoSave: e.target.checked })}
                  className="rounded text-blue-600 accent-blue-600"
                />
                <span className="text-xs font-medium">Auto-save open tabs periodically</span>
              </label>
            </div>
          )}
        </div>

        {/* Footer */}
        <div
          className="px-4 py-3 border-t flex items-center justify-between theme-dialog-header"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          <div className="text-[11px] opacity-70">
            {isPreviewing && (
              <span className="text-amber-500 font-medium">
                Preview active. Click any theme to apply permanently.
              </span>
            )}
          </div>
          <button
            onClick={handleClose}
            className="px-4 py-1.5 text-xs font-bold rounded-md bg-blue-600 hover:bg-blue-500 text-white shadow-sm transition-colors"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
};
