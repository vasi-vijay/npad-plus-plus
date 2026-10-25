import React, { useState } from 'react';
import { TextEncoding, LineEnding } from '../lib/encoding';
import { SUPPORTED_LANGUAGES } from '../lib/languageEngine';
import { ChevronDown, Cpu } from 'lucide-react';

interface StatusBarProps {
  isDark: boolean;
  cursorLine: number;
  cursorCol: number;
  selectionLength: number;
  totalLines: number;
  encoding: TextEncoding;
  lineEnding: LineEnding;
  languageId: string;
  onSetEncoding: (enc: TextEncoding) => void;
  onSetLineEnding: (ending: LineEnding) => void;
  onSetLanguage: (langId: string) => void;
}

export const StatusBar: React.FC<StatusBarProps> = ({
  isDark,
  cursorLine,
  cursorCol,
  selectionLength,
  totalLines,
  encoding,
  lineEnding,
  languageId,
  onSetEncoding,
  onSetLineEnding,
  onSetLanguage,
}) => {
  const [showEncMenu, setShowEncMenu] = useState(false);
  const [showEndingMenu, setShowEndingMenu] = useState(false);
  const [showLangMenu, setShowLangMenu] = useState(false);

  const [isOvertype, setIsOvertype] = useState(false);
  const langObj = SUPPORTED_LANGUAGES.find((l) => l.id === languageId) || SUPPORTED_LANGUAGES[0];

  const lineEndingLabel = lineEnding === 'CRLF' ? 'Windows (CRLF)' : lineEnding === 'CR' ? 'Macintosh (CR)' : 'Unix (LF)';

  return (
    <div
      className={`h-6 px-3 flex items-center justify-between text-[11px] font-mono select-none border-t transition-colors relative z-30 ${
        isDark ? 'bg-[#202020] border-[#2d2d2d] text-gray-400' : 'bg-[#f0f0f0] border-[#d4d4d4] text-gray-700'
      }`}
    >
      {/* Left: Notepad++ Classic Sections */}
      <div className="flex items-center space-x-3 divide-x divide-gray-400/30">
        <span className="pr-3">
          length : <strong className="text-blue-500 font-semibold">{totalLines.toLocaleString()}</strong> lines
        </span>

        <span className="px-3">
          Ln : <strong className="text-blue-500 font-semibold">{cursorLine}</strong>  Col :{' '}
          <strong className="text-blue-500 font-semibold">{cursorCol}</strong>  Sel :{' '}
          <span className={selectionLength > 0 ? 'text-amber-500 font-bold' : ''}>
            {selectionLength.toLocaleString()}
          </span>
        </span>

        {/* Insert / Overwrite Mode */}
        <button
          onClick={() => setIsOvertype(!isOvertype)}
          title="Click to toggle INS/OVR mode"
          className="px-3 hover:text-blue-500 font-semibold cursor-pointer"
        >
          {isOvertype ? 'OVR' : 'INS'}
        </button>

        {/* Read/Write Editable Status Indicator */}
        <span
          className="px-3 text-emerald-600 dark:text-emerald-400 font-semibold flex items-center space-x-1.5"
          title="Editing Enabled: Text input, typing, cut/paste and modification are fully active"
        >
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse inline-block"></span>
          <span>Editable</span>
        </span>
      </div>

      {/* Right: Line Ending, Encoding, Language */}
      <div className="flex items-center space-x-3 divide-x divide-gray-400/30">
        {/* Line Ending Format Selector */}
        <div className="relative pr-3">
          <button
            onClick={() => setShowEndingMenu(!showEndingMenu)}
            className="hover:text-blue-500 flex items-center space-x-1 transition-colors"
            title="Line Endings format (click to change)"
          >
            <span>{lineEndingLabel}</span>
            <ChevronDown className="w-3 h-3 opacity-60" />
          </button>
          {showEndingMenu && (
            <div
              className={`absolute right-0 bottom-full mb-1 w-44 rounded border shadow-xl p-1 text-xs ${
                isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-white border-[#d0d0d0] text-gray-800'
              }`}
            >
              {(['LF', 'CRLF', 'CR'] as LineEnding[]).map((le) => (
                <button
                  key={le}
                  onClick={() => {
                    onSetLineEnding(le);
                    setShowEndingMenu(false);
                  }}
                  className="w-full text-left px-2 py-1 rounded hover:bg-blue-600 hover:text-white flex justify-between"
                >
                  <span>{le === 'LF' ? 'Unix (LF)' : le === 'CRLF' ? 'Windows (CRLF)' : 'Macintosh (CR)'}</span>
                  {lineEnding === le && <span>✓</span>}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Encoding Selector */}
        <div className="relative px-3">
          <button
            onClick={() => setShowEncMenu(!showEncMenu)}
            className="hover:text-blue-500 flex items-center space-x-1 transition-colors"
            title="Character encoding (click to change)"
          >
            <span>{encoding}</span>
            <ChevronDown className="w-3 h-3 opacity-60" />
          </button>
          {showEncMenu && (
            <div
              className={`absolute right-0 bottom-full mb-1 w-36 rounded border shadow-xl p-1 text-xs ${
                isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-white border-[#d0d0d0] text-gray-800'
              }`}
            >
              {(['UTF-8', 'UTF-8-BOM', 'UTF-16LE', 'UTF-16BE', 'ASCII'] as TextEncoding[]).map((enc) => (
                <button
                  key={enc}
                  onClick={() => {
                    onSetEncoding(enc);
                    setShowEncMenu(false);
                  }}
                  className="w-full text-left px-2 py-1 rounded hover:bg-blue-600 hover:text-white flex justify-between"
                >
                  <span>{enc}</span>
                  {encoding === enc && <span>✓</span>}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Language Selector */}
        <div className="relative pl-3">
          <button
            onClick={() => setShowLangMenu(!showLangMenu)}
            className="hover:text-blue-500 flex items-center space-x-1 font-semibold transition-colors"
            title="Programming language syntax (click to change)"
          >
            <span>{langObj.name} file</span>
            <ChevronDown className="w-3 h-3 opacity-60" />
          </button>
          {showLangMenu && (
            <div
              className={`absolute right-0 bottom-full mb-1 w-48 max-h-56 overflow-y-auto rounded border shadow-xl p-1 text-xs ${
                isDark ? 'bg-[#2b2d30] border-[#3e4248] text-gray-200' : 'bg-white border-[#d0d0d0] text-gray-800'
              }`}
            >
              {SUPPORTED_LANGUAGES.map((lang) => (
                <button
                  key={lang.id}
                  onClick={() => {
                    onSetLanguage(lang.id);
                    setShowLangMenu(false);
                  }}
                  className="w-full text-left px-2 py-1 rounded hover:bg-blue-600 hover:text-white flex justify-between"
                >
                  <span>{lang.name}</span>
                  {languageId === lang.id && <span>✓</span>}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
