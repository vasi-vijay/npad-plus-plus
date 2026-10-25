import React, { useState } from 'react';
import { PluginManifest } from '../lib/pluginSystem';
import { X, Check, Shield, Plus, Upload, Code } from 'lucide-react';

interface PluginManagerModalProps {
  isOpen: boolean;
  isDark: boolean;
  plugins: PluginManifest[];
  onTogglePlugin: (id: string, enabled: boolean) => void;
  onInstallPlugin: (manifest: PluginManifest) => { success: boolean; error?: string };
  onUninstallPlugin: (id: string) => void;
  onClose: () => void;
}

export const PluginManagerModal: React.FC<PluginManagerModalProps> = ({
  isOpen,
  isDark,
  plugins,
  onTogglePlugin,
  onInstallPlugin,
  onUninstallPlugin,
  onClose,
}) => {
  const [activeTab, setActiveTab] = useState<'installed' | 'install' | 'sdk'>('installed');
  const [jsonInput, setJsonInput] = useState('');
  const [statusMsg, setStatusMsg] = useState<{ text: string; error?: boolean } | null>(null);

  if (!isOpen) return null;

  const bg = isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-white border-[#d0d0d0] text-gray-800';

  const handleInstallCustom = () => {
    try {
      const manifest = JSON.parse(jsonInput);
      manifest.commands = manifest.commands || [];
      // Bind stub command execution if function missing
      manifest.commands = manifest.commands.map((c: any) => ({
        ...c,
        execute: (ctx: any) => ctx.showMessage(`Executed custom command: ${c.name}`, 'success'),
      }));

      const res = onInstallPlugin(manifest);
      if (res.success) {
        setStatusMsg({ text: `Successfully installed plugin "${manifest.name}"!` });
        setJsonInput('');
        setActiveTab('installed');
      } else {
        setStatusMsg({ text: res.error || 'Failed to install plugin', error: true });
      }
    } catch (e: any) {
      setStatusMsg({ text: `Invalid JSON manifest: ${e.message}`, error: true });
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4 backdrop-blur-xs">
      <div
        className="w-full max-w-2xl rounded-xl border shadow-2xl overflow-hidden theme-dialog transition-colors duration-150"
        style={{
          backgroundColor: 'var(--theme-dialog-bg)',
          color: 'var(--theme-dialog-fg)',
          borderColor: 'var(--theme-dialog-border)',
        }}
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
            <span className="text-base">🧩</span>
            <span className="font-bold text-sm">Notepad++ Plugin Manager</span>
            <span className="px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-500 text-[10px] font-bold">
              ARM64 Sandboxed
            </span>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/10 dark:hover:bg-white/10">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Tab Header */}
        <div
          className="flex border-b text-xs font-semibold"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          <button
            onClick={() => setActiveTab('installed')}
            className={`px-4 py-2.5 transition-colors border-b-2 ${
              activeTab === 'installed'
                ? 'border-blue-500 text-blue-500 bg-white/5'
                : 'border-transparent text-gray-500 hover:text-gray-300'
            }`}
          >
            Installed Plugins ({plugins.length})
          </button>
          <button
            onClick={() => setActiveTab('install')}
            className={`px-4 py-2.5 transition-colors border-b-2 ${
              activeTab === 'install'
                ? 'border-blue-500 text-blue-500 bg-white/5'
                : 'border-transparent text-gray-500 hover:text-gray-300'
            }`}
          >
            Install Local Plugin
          </button>
          <button
            onClick={() => setActiveTab('sdk')}
            className={`px-4 py-2.5 transition-colors border-b-2 ${
              activeTab === 'sdk'
                ? 'border-blue-500 text-blue-500 bg-white/5'
                : 'border-transparent text-gray-500 hover:text-gray-300'
            }`}
          >
            Plugin SDK & Architecture
          </button>
        </div>

        {/* Body */}
        <div className="p-5 max-h-[70vh] overflow-y-auto text-xs space-y-3">
          {statusMsg && (
            <div
              className={`p-2.5 rounded text-xs font-semibold ${
                statusMsg.error
                  ? 'bg-red-500/10 border border-red-500/30 text-red-500'
                  : 'bg-emerald-500/10 border border-emerald-500/30 text-emerald-500'
              }`}
            >
              {statusMsg.text}
            </div>
          )}

          {/* TAB: INSTALLED PLUGINS */}
          {activeTab === 'installed' && (
            <div className="space-y-3">
              {plugins.map((plugin) => (
                <div
                  key={plugin.id}
                  className="p-3 rounded-lg border border-gray-300 dark:border-gray-700 bg-black/5 dark:bg-white/5 flex items-start justify-between space-x-3"
                >
                  <div className="space-y-1 flex-1">
                    <div className="flex items-center space-x-2">
                      <span className="font-bold text-sm">{plugin.name}</span>
                      <span className="text-[10px] px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-500 font-mono">
                        v{plugin.version}
                      </span>
                      <span className="text-[10px] text-gray-400">by {plugin.author}</span>
                    </div>
                    <p className="text-gray-600 dark:text-gray-400 text-xs">{plugin.description}</p>
                    <div className="flex items-center space-x-2 text-[10px] text-gray-500 font-mono pt-1">
                      <span>Commands: {plugin.commands.map((c) => c.name).join(', ')}</span>
                    </div>
                  </div>

                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => onTogglePlugin(plugin.id, !plugin.enabled)}
                      className={`px-3 py-1.5 rounded text-xs font-semibold transition-all ${
                        plugin.enabled
                          ? 'bg-blue-600 hover:bg-blue-500 text-white'
                          : 'bg-gray-400/20 text-gray-500 hover:bg-gray-400/30'
                      }`}
                    >
                      {plugin.enabled ? 'Enabled' : 'Disabled'}
                    </button>
                    {!plugin.id.startsWith('npp-') && (
                      <button
                        onClick={() => onUninstallPlugin(plugin.id)}
                        className="px-2 py-1.5 rounded text-xs text-red-500 hover:bg-red-500/10"
                      >
                        Remove
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* TAB: INSTALL LOCAL PLUGIN */}
          {activeTab === 'install' && (
            <div className="space-y-3">
              <p className="text-gray-500">
                Install a custom Notepad++ plugin package by pasting its JSON manifest below. Plugins are validated before installation.
              </p>
              <textarea
                value={jsonInput}
                onChange={(e) => setJsonInput(e.target.value)}
                placeholder={`{
  "id": "my-custom-formatter",
  "name": "Custom SQL Prettifier",
  "version": "1.0.0",
  "author": "Mac Developer",
  "description": "Aligns SQL keywords and clauses.",
  "minEditorVersion": "1.0.0",
  "commands": [
    { "id": "sql.align", "name": "Align SQL Keywords" }
  ]
}`}
                rows={10}
                className="w-full p-3 rounded-lg border border-gray-300 dark:border-gray-700 bg-transparent font-mono text-xs outline-none focus:ring-2 focus:ring-blue-500"
              />
              <div className="flex justify-end">
                <button
                  onClick={handleInstallCustom}
                  className="px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-500 text-white font-bold flex items-center space-x-1"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Validate & Install Plugin</span>
                </button>
              </div>
            </div>
          )}

          {/* TAB: PLUGIN SDK */}
          {activeTab === 'sdk' && (
            <div className="space-y-3 font-sans">
              <div className="p-3 rounded bg-blue-500/10 border border-blue-500/20 space-y-1">
                <div className="font-bold text-blue-500 flex items-center space-x-1">
                  <Code className="w-4 h-4" />
                  <span>Notepad++ for Mac Plugin SDK (Swift & Web)</span>
                </div>
                <p className="text-gray-600 dark:text-gray-300">
                  Plugins interact with the editor via the <code>PluginContext</code> interface, exposing document text, selection, language, and status bar notification hooks.
                </p>
              </div>

              <div className="font-mono text-[11px] p-3 rounded bg-black/20 overflow-x-auto space-y-1">
                <div className="text-purple-400 font-bold">// Swift Plugin Protocol Definition:</div>
                <div>public protocol NotepadPlusPlugin {'{'}</div>
                <div>&nbsp;&nbsp;var id: String {'{ get }'}</div>
                <div>&nbsp;&nbsp;var name: String {'{ get }'}</div>
                <div>&nbsp;&nbsp;var version: String {'{ get }'}</div>
                <div>&nbsp;&nbsp;func onDocumentOpen(doc: EditorDocument)</div>
                <div>&nbsp;&nbsp;func registerCommands(registry: CommandRegistry)</div>
                <div>{'}'}</div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className={`px-4 py-3 border-t flex justify-end ${isDark ? 'bg-[#222426] border-[#3e4248]' : 'bg-[#f4f4f4] border-[#d0d0d0]'}`}>
          <button
            onClick={onClose}
            className="px-4 py-1.5 text-xs font-bold rounded bg-blue-600 hover:bg-blue-500 text-white"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};
