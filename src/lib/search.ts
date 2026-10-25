export interface SearchOptions {
  query: string;
  caseSensitive: boolean;
  wholeWord: boolean;
  useRegex: boolean;
  searchMode?: 'normal' | 'extended' | 'regex';
}

export interface SearchMatch {
  index: number;
  length: number;
  lineNumber: number; // 1-indexed
  columnNumber: number; // 1-indexed
  lineText: string;
}

/**
 * Expands Notepad++ Extended Search escape sequences (\n, \r, \t, \0, \xHH, \\).
 */
export function expandExtendedEscapes(raw: string): string {
  return raw.replace(/\\(n|r|t|0|\\|x[0-9A-Fa-f]{2})/g, (_, seq: string) => {
    if (seq === 'n') return '\n';
    if (seq === 'r') return '\r';
    if (seq === 't') return '\t';
    if (seq === '0') return '\0';
    if (seq === '\\') return '\\';
    if (seq.startsWith('x') || seq.startsWith('X')) {
      const code = parseInt(seq.slice(1), 16);
      return Number.isNaN(code) ? seq : String.fromCharCode(code);
    }
    return seq;
  });
}

/**
 * Builds a RegExp based on user search options, escaping characters if not regex.
 */
export function buildSearchRegex(options: SearchOptions): RegExp | null {
  if (!options.query) return null;

  const isRegex = options.searchMode ? options.searchMode === 'regex' : options.useRegex;
  const isExtended = options.searchMode === 'extended';

  let pattern = isExtended ? expandExtendedEscapes(options.query) : options.query;
  if (!isRegex) {
    pattern = pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  if (options.wholeWord) {
    pattern = `\\b(?:${pattern})\\b`;
  }

  const flags = options.caseSensitive ? 'g' : 'gi';
  try {
    return new RegExp(pattern, flags);
  } catch {
    return null; // Invalid regex
  }
}

/**
 * Finds all matches of the search query in the text.
 */
export function findAllMatches(text: string, options: SearchOptions): SearchMatch[] {
  const regex = buildSearchRegex(options);
  if (!regex) return [];

  const matches: SearchMatch[] = [];
  const lines = text.split('\n');
  const lineStartOffsets: number[] = [0];

  for (let i = 0; i < lines.length - 1; i++) {
    lineStartOffsets.push(lineStartOffsets[i] + lines[i].length + 1);
  }

  let match: RegExpExecArray | null;
  while ((match = regex.exec(text)) !== null) {
    const idx = match.index;
    const matchLength = match[0].length;

    // Binary search or linear search for line number
    let lineIdx = 0;
    while (lineIdx < lineStartOffsets.length - 1 && lineStartOffsets[lineIdx + 1] <= idx) {
      lineIdx++;
    }

    const lineNumber = lineIdx + 1;
    const columnNumber = idx - lineStartOffsets[lineIdx] + 1;
    const lineText = lines[lineIdx] ?? '';

    matches.push({
      index: idx,
      length: matchLength,
      lineNumber,
      columnNumber,
      lineText,
    });

    if (matchLength === 0) {
      regex.lastIndex++;
    }
  }

  return matches;
}

/**
 * Replaces the first match at or after startIndex.
 */
export function replaceNext(
  text: string,
  options: SearchOptions,
  replacement: string,
  startIndex: number = 0
): { newText: string; nextIndex: number; replaced: boolean } {
  const regex = buildSearchRegex(options);
  if (!regex) return { newText: text, nextIndex: startIndex, replaced: false };

  const effectiveReplacement =
    options.searchMode === 'extended' ? expandExtendedEscapes(replacement) : replacement;

  regex.lastIndex = startIndex;
  let match = regex.exec(text);

  // Wrap around if not found after startIndex
  if (!match && startIndex > 0) {
    regex.lastIndex = 0;
    match = regex.exec(text);
  }

  if (!match) {
    return { newText: text, nextIndex: startIndex, replaced: false };
  }

  const matchIdx = match.index;
  const matchLen = match[0].length;

  const newText = text.slice(0, matchIdx) + effectiveReplacement + text.slice(matchIdx + matchLen);
  return {
    newText,
    nextIndex: matchIdx + effectiveReplacement.length,
    replaced: true,
  };
}

/**
 * Replaces all occurrences matching options with replacement.
 */
export function replaceAll(
  text: string,
  options: SearchOptions,
  replacement: string
): { newText: string; count: number } {
  const regex = buildSearchRegex(options);
  if (!regex) return { newText: text, count: 0 };

  const effectiveReplacement =
    options.searchMode === 'extended' ? expandExtendedEscapes(replacement) : replacement;

  let count = 0;
  const newText = text.replace(regex, () => {
    count++;
    return effectiveReplacement;
  });

  return { newText, count };
}

/**
 * Returns distinct line numbers that contain matches (useful for Notepad++ Mark Lines feature).
 */
export function getMarkedLineNumbers(text: string, options: SearchOptions): number[] {
  const matches = findAllMatches(text, options);
  const lineSet = new Set<number>();
  for (const m of matches) {
    lineSet.add(m.lineNumber);
  }
  return Array.from(lineSet).sort((a, b) => a - b);
}
