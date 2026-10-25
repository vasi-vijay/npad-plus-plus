import React from 'react';
import { X, Download, Terminal, CheckCircle2, Cpu, Package, Sparkles } from 'lucide-react';

interface ExportAppModalProps {
  isOpen: boolean;
  isDark: boolean;
  onClose: () => void;
}

export const ExportAppModal: React.FC<ExportAppModalProps> = ({
  isOpen,
  isDark,
  onClose,
}) => {
  if (!isOpen) return null;

  const bg = isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-white border-[#d0d0d0] text-gray-800';

  const downloadInstructions = `
# To build and package CodePad++ for Mac on Apple Silicon (M1/M2/M3/M4):
cd macos-app
chmod +x build.sh create_dmg.sh
./build.sh
./create_dmg.sh
# Outputs: CodePad++.dmg
  `.trim();

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
          className="px-5 py-4 border-b flex items-center justify-between theme-dialog-header"
          style={{
            backgroundColor: 'var(--theme-dialog-header-bg)',
            borderColor: 'var(--theme-dialog-border)',
          }}
        >
          <div className="flex items-center space-x-2">
            <Cpu className="w-5 h-5 text-emerald-500" />
            <span className="font-bold text-sm">CodePad++ for Mac — Apple Silicon Native Package</span>
          </div>
          <button onClick={onClose} className="p-1 rounded hover:bg-black/10 dark:hover:bg-white/10">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-5 text-xs max-h-[75vh] overflow-y-auto">
          {/* Badge banner */}
          <div className="p-4 rounded-xl bg-gradient-to-r from-emerald-500/10 via-blue-500/10 to-purple-500/10 border border-emerald-500/20 flex items-start space-x-3">
            <CheckCircle2 className="w-5 h-5 text-emerald-500 flex-shrink-0 mt-0.5" />
            <div className="space-y-1">
              <div className="font-bold text-sm text-emerald-600 dark:text-emerald-400">
                100% Native Apple Silicon Source & Bundle Ready
              </div>
              <p className="text-gray-600 dark:text-gray-300 leading-relaxed font-sans">
                The full native Swift 5.9+ / macOS 14 Sonoma & Sequoia source code, AppKit custom text gutter engine, Package.swift manifest, Info.plist, build scripts, and tests are packaged in <code>/macos-app</code>.
              </p>
            </div>
          </div>

          {/* Deliverables summary */}
          <div className="space-y-2">
            <div className="font-bold uppercase tracking-wider text-gray-500">Deliverables Included in Project:</div>
            <div className="grid grid-cols-2 gap-2 font-mono">
              <div className="p-2.5 rounded border border-gray-300 dark:border-gray-700 bg-black/5 dark:bg-white/5 space-y-1">
                <div className="font-bold text-blue-500 flex items-center space-x-1">
                  <Package className="w-3.5 h-3.5" />
                  <span>1. Native Swift Sources</span>
                </div>
                <div className="text-[11px] text-gray-400">/macos-app/Sources/NotepadPlusMac/</div>
              </div>
              <div className="p-2.5 rounded border border-gray-300 dark:border-gray-700 bg-black/5 dark:bg-white/5 space-y-1">
                <div className="font-bold text-emerald-500 flex items-center space-x-1">
                  <Cpu className="w-3.5 h-3.5" />
                  <span>2. Package.swift (ARM64)</span>
                </div>
                <div className="text-[11px] text-gray-400">Target macOS 14+ / Swift 5.9</div>
              </div>
              <div className="p-2.5 rounded border border-gray-300 dark:border-gray-700 bg-black/5 dark:bg-white/5 space-y-1">
                <div className="font-bold text-purple-500 flex items-center space-x-1">
                  <Terminal className="w-3.5 h-3.5" />
                  <span>3. Reproducible build.sh</span>
                </div>
                <div className="text-[11px] text-gray-400">Generates .app bundle hierarchy</div>
              </div>
              <div className="p-2.5 rounded border border-gray-300 dark:border-gray-700 bg-black/5 dark:bg-white/5 space-y-1">
                <div className="font-bold text-amber-500 flex items-center space-x-1">
                  <Download className="w-3.5 h-3.5" />
                  <span>4. Distributable DMG Creator</span>
                </div>
                <div className="text-[11px] text-gray-400">create_dmg.sh with /Applications symlink</div>
              </div>
            </div>
          </div>

          {/* Quick Terminal Command */}
          <div className="space-y-2">
            <div className="font-bold uppercase tracking-wider text-gray-500">
              One-Step Build Command (on your Mac):
            </div>
            <div className="p-3 rounded-lg bg-black/30 font-mono text-emerald-400 select-all border border-gray-700">
              cd macos-app && ./build.sh && ./create_dmg.sh
            </div>
          </div>

          {/* Code Signing & Notarization Summary */}
          <div className="space-y-2 font-sans">
            <div className="font-bold uppercase tracking-wider text-gray-500">
              Distribution & Notarization Workflow:
            </div>
            <p className="text-gray-600 dark:text-gray-400 leading-relaxed">
              To distribute outside the Mac App Store without Gatekeeper prompts, sign with <code>codesign --sign "Developer ID Application"</code>, package with <code>./create_dmg.sh</code>, and submit with <code>xcrun notarytool submit</code>. See the included <code>/macos-app/README.md</code> for exact flags and instructions.
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className={`px-5 py-3 border-t flex justify-end ${isDark ? 'bg-[#222426] border-[#3e4248]' : 'bg-[#f4f4f4] border-[#d0d0d0]'}`}>
          <button
            onClick={onClose}
            className="px-4 py-2 text-xs font-bold rounded-lg bg-blue-600 hover:bg-blue-500 text-white"
          >
            Got it
          </button>
        </div>
      </div>
    </div>
  );
};
