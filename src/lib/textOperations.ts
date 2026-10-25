export interface SelectionRange {
  start: number;
  end: number;
}

/**
 * Duplicates the current line or selection.
 */
export function duplicateLineOrSelection(text: string, selection: SelectionRange): {
  newText: string;
  newSelection: SelectionRange;
} {
  const { start, end } = selection;

  if (start !== end) {
    // Duplicate selected text
    const selected = text.slice(start, end);
    const newText = text.slice(0, end) + selected + text.slice(end);
    return {
      newText,
      newSelection: { start: end, end: end + selected.length },
    };
  }

  // Find line start and end
  const lineStart = text.lastIndexOf('\n', start - 1) + 1;
  let lineEnd = text.indexOf('\n', start);
  if (lineEnd === -1) lineEnd = text.length;

  const lineContent = text.slice(lineStart, lineEnd);
  // Duplicate line right after
  const insertion = '\n' + lineContent;
  const newText = text.slice(0, lineEnd) + insertion + text.slice(lineEnd);
  const offset = lineContent.length + 1;

  return {
    newText,
    newSelection: { start: start + offset, end: end + offset },
  };
}

/**
 * Deletes current line(s) spanned by selection.
 */
export function deleteCurrentLine(text: string, selection: SelectionRange): {
  newText: string;
  newCursor: number;
} {
  const lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
  let lineEnd = text.indexOf('\n', selection.end);

  if (lineEnd === -1) {
    // Last line: if there is a previous newline, delete it too
    const cutStart = lineStart > 0 ? lineStart - 1 : 0;
    const newText = text.slice(0, cutStart);
    return { newText, newCursor: Math.min(cutStart, newText.length) };
  } else {
    // Delete up to next line start (including newline)
    const newText = text.slice(0, lineStart) + text.slice(lineEnd + 1);
    return { newText, newCursor: Math.min(lineStart, newText.length) };
  }
}

/**
 * Moves current line or lines up.
 */
export function moveLineUp(text: string, cursor: number): { newText: string; newCursor: number } {
  const lines = text.split('\n');
  let currentLine = 0;
  let charCount = 0;

  for (let i = 0; i < lines.length; i++) {
    const nextCharCount = charCount + lines[i].length + 1;
    if (cursor >= charCount && cursor < nextCharCount) {
      currentLine = i;
      break;
    }
    charCount = nextCharCount;
    if (i === lines.length - 1) currentLine = i;
  }

  if (currentLine <= 0) return { newText: text, newCursor: cursor };

  const lineOffset = cursor - charCount;
  // Swap line with previous
  const temp = lines[currentLine];
  lines[currentLine] = lines[currentLine - 1];
  lines[currentLine - 1] = temp;

  const newText = lines.join('\n');
  // Compute new cursor in previous line
  let newCharCount = 0;
  for (let i = 0; i < currentLine - 1; i++) {
    newCharCount += lines[i].length + 1;
  }
  const newCursor = Math.min(newCharCount + lineOffset, newCharCount + lines[currentLine - 1].length);

  return { newText, newCursor };
}

/**
 * Moves current line down.
 */
export function moveLineDown(text: string, cursor: number): { newText: string; newCursor: number } {
  const lines = text.split('\n');
  let currentLine = 0;
  let charCount = 0;

  for (let i = 0; i < lines.length; i++) {
    const nextCharCount = charCount + lines[i].length + 1;
    if (cursor >= charCount && cursor < nextCharCount) {
      currentLine = i;
      break;
    }
    charCount = nextCharCount;
    if (i === lines.length - 1) currentLine = i;
  }

  if (currentLine >= lines.length - 1) return { newText: text, newCursor: cursor };

  const lineOffset = cursor - charCount;
  const temp = lines[currentLine];
  lines[currentLine] = lines[currentLine + 1];
  lines[currentLine + 1] = temp;

  const newText = lines.join('\n');
  let newCharCount = 0;
  for (let i = 0; i < currentLine + 1; i++) {
    newCharCount += lines[i].length + 1;
  }
  const newCursor = Math.min(newCharCount + lineOffset, newCharCount + lines[currentLine + 1].length);

  return { newText, newCursor };
}

/**
 * Joins current line with the next line, removing extra indentation.
 */
export function joinLines(text: string, cursor: number): { newText: string; newCursor: number } {
  const lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
  const lineEnd = text.indexOf('\n', cursor);
  if (lineEnd === -1) return { newText: text, newCursor: cursor };

  let nextLineEnd = text.indexOf('\n', lineEnd + 1);
  if (nextLineEnd === -1) nextLineEnd = text.length;

  const nextLineRaw = text.slice(lineEnd + 1, nextLineEnd);
  const trimmedNextLine = nextLineRaw.trimStart();

  const joined = text.slice(lineStart, lineEnd) + ' ' + trimmedNextLine;
  const newText = text.slice(0, lineStart) + joined + text.slice(nextLineEnd);

  return { newText, newCursor: lineEnd };
}

/**
 * Converts tabs to spaces based on tabWidth.
 */
export function convertTabsToSpaces(text: string, tabWidth: number = 4): string {
  const spaces = ' '.repeat(tabWidth);
  return text.replace(/\t/g, spaces);
}

/**
 * Converts leading spaces to tabs.
 */
export function convertSpacesToTabs(text: string, tabWidth: number = 4): string {
  const spaces = ' '.repeat(tabWidth);
  const regex = new RegExp(`^((?:${spaces})+)`, 'gm');
  return text.replace(regex, (match) => {
    return '\t'.repeat(match.length / tabWidth);
  });
}

/**
 * Toggles line comments (e.g. // or #) on selected lines.
 */
export function toggleLineComment(
  text: string,
  selection: SelectionRange,
  commentPrefix: string = '//'
): { newText: string; newSelection: SelectionRange } {
  const lineStart = text.lastIndexOf('\n', selection.start - 1) + 1;
  let lineEnd = text.indexOf('\n', selection.end);
  if (lineEnd === -1) lineEnd = text.length;

  const block = text.slice(lineStart, lineEnd);
  const lines = block.split('\n');

  // Check if all non-empty lines are commented
  const allCommented = lines.every(l => {
    const trimmed = l.trim();
    return trimmed.length === 0 || trimmed.startsWith(commentPrefix);
  });

  const modifiedLines = lines.map(l => {
    if (l.trim().length === 0) return l;
    if (allCommented) {
      // Uncomment
      const commentIdx = l.indexOf(commentPrefix);
      if (commentIdx !== -1) {
        const after = l.slice(commentIdx + commentPrefix.length);
        const leading = l.slice(0, commentIdx);
        // also remove single trailing space if present
        const cleanedAfter = after.startsWith(' ') ? after.slice(1) : after;
        return leading + cleanedAfter;
      }
      return l;
    } else {
      // Comment
      const matchLeading = l.match(/^(\s*)/);
      const leading = matchLeading ? matchLeading[1] : '';
      const rest = l.slice(leading.length);
      return `${leading}${commentPrefix} ${rest}`;
    }
  });

  const newBlock = modifiedLines.join('\n');
  const newText = text.slice(0, lineStart) + newBlock + text.slice(lineEnd);
  const diff = newBlock.length - block.length;

  return {
    newText,
    newSelection: {
      start: selection.start,
      end: Math.max(selection.start, selection.end + diff),
    },
  };
}

/**
 * Finds matching pair for bracket at cursor position: (), [], {}, <>.
 */
export function findMatchingBracket(text: string, cursor: number): number | null {
  const pairs: Record<string, { open: boolean; match: string; dir: number }> = {
    '(': { open: true, match: ')', dir: 1 },
    ')': { open: false, match: '(', dir: -1 },
    '[': { open: true, match: ']', dir: 1 },
    ']': { open: false, match: '[', dir: -1 },
    '{': { open: true, match: '}', dir: 1 },
    '}': { open: false, match: '{', dir: -1 },
  };

  const char = text[cursor];
  const charBefore = text[cursor - 1];

  let targetChar = '';
  let searchPos = cursor;

  if (pairs[char]) {
    targetChar = char;
    searchPos = cursor;
  } else if (pairs[charBefore]) {
    targetChar = charBefore;
    searchPos = cursor - 1;
  } else {
    return null;
  }

  const info = pairs[targetChar];
  const dir = info.dir;
  const matchChar = info.match;
  let depth = 0;

  for (let i = searchPos; i >= 0 && i < text.length; i += dir) {
    if (text[i] === targetChar) depth++;
    else if (text[i] === matchChar) {
      depth--;
      if (depth === 0) return i;
    }
  }

  return null;
}
