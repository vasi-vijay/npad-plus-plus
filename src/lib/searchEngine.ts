export interface SearchOptions {
  caseSensitive: boolean;
  wholeWord: boolean;
  isRegex: boolean;
  wrapAround: boolean;
}

export interface MatchRange {
  index: number;
  length: number;
}

export interface SearchResult {
  matches: MatchRange[];
  totalCount: number;
  activeIndex: number;
  error?: string;
}

export function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export function findAllMatches(
  text: string,
  query: string,
  options: SearchOptions,
  cursorPos = 0
): SearchResult {
  if (!query) {
    return { matches: [], totalCount: 0, activeIndex: 0 };
  }

  let pattern = query;
  if (!options.isRegex) {
    const escaped = escapeRegex(query);
    pattern = options.wholeWord ? `\\b${escaped}\\b` : escaped;
  }

  let regex: RegExp;
  try {
    const flags = options.caseSensitive ? 'gu' : 'giu';
    regex = new RegExp(pattern, flags);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { matches: [], totalCount: 0, activeIndex: 0, error: msg };
  }

  const matches: MatchRange[] = [];
  let m: RegExpExecArray | null;
  while ((m = regex.exec(text)) !== null) {
    matches.push({ index: m.index, length: m[0].length });
    if (m[0].length === 0) {
      regex.lastIndex++; // Prevent infinite loops on zero-length matches
    }
  }

  let activeIndex = 0;
  if (matches.length > 0) {
    const nextIdx = matches.findIndex((match) => match.index >= cursorPos);
    activeIndex = nextIdx !== -1 ? nextIdx + 1 : 1;
  }

  return {
    matches,
    totalCount: matches.length,
    activeIndex,
  };
}

export function getNextMatchIndex(
  currentIndex: number,
  totalMatches: number,
  wrapAround: boolean
): number | null {
  if (totalMatches === 0) return null;
  if (currentIndex < totalMatches) return currentIndex + 1;
  return wrapAround ? 1 : null;
}

export function getPreviousMatchIndex(
  currentIndex: number,
  totalMatches: number,
  wrapAround: boolean
): number | null {
  if (totalMatches === 0) return null;
  if (currentIndex > 1) return currentIndex - 1;
  return wrapAround ? totalMatches : null;
}

export function replaceAllText(
  text: string,
  query: string,
  replacement: string,
  options: SearchOptions
): { newText: string; count: number; error?: string } {
  if (!query) return { newText: text, count: 0 };

  let pattern = query;
  if (!options.isRegex) {
    const escaped = escapeRegex(query);
    pattern = options.wholeWord ? `\\b${escaped}\\b` : escaped;
  }

  try {
    const flags = options.caseSensitive ? 'gu' : 'giu';
    const regex = new RegExp(pattern, flags);
    let count = 0;
    const newText = text.replace(regex, () => {
      count++;
      return replacement;
    });
    return { newText, count };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return { newText: text, count: 0, error: msg };
  }
}
