import test from 'node:test';
import assert from 'node:assert/strict';
import {
  duplicateLineOrSelection,
  deleteCurrentLine,
  moveLineUp,
  moveLineDown,
  joinLines,
  convertTabsToSpaces,
  convertSpacesToTabs,
  toggleLineComment,
  findMatchingBracket,
} from './textOperations';

test('duplicateLineOrSelection duplicates current line when cursor has no selection', () => {
  const orig = 'line1\nline2\nline3';
  const { newText } = duplicateLineOrSelection(orig, { start: 7, end: 7 }); // inside line2
  assert.equal(newText, 'line1\nline2\nline2\nline3');
});

test('deleteCurrentLine removes line cleanly', () => {
  const orig = 'line1\nline2\nline3';
  const res = deleteCurrentLine(orig, { start: 8, end: 8 });
  assert.equal(res.newText, 'line1\nline3');
});

test('moveLineUp and moveLineDown swaps adjacent lines', () => {
  const orig = 'alpha\nbeta\ngamma';
  // Move beta up (cursor at 7)
  const up = moveLineUp(orig, 7);
  assert.equal(up.newText, 'beta\nalpha\ngamma');

  // Move beta down from beta\nalpha\ngamma (cursor at 2)
  const down = moveLineDown(up.newText, 2);
  assert.equal(down.newText, 'alpha\nbeta\ngamma');
});

test('joinLines merges current line with next line', () => {
  const orig = 'function test() {\n    return true;\n}';
  const res = joinLines(orig, 5); // on first line
  assert.equal(res.newText, 'function test() { return true;\n}');
});

test('convertTabsToSpaces and convertSpacesToTabs converts accurately', () => {
  const tabbed = '\t\tlet x = 10;';
  const spaced = convertTabsToSpaces(tabbed, 4);
  assert.equal(spaced, '        let x = 10;');

  const back = convertSpacesToTabs(spaced, 4);
  assert.equal(back, tabbed);
});

test('toggleLineComment comments and uncomments correctly', () => {
  const code = 'const a = 1;\nconst b = 2;';
  const commented = toggleLineComment(code, { start: 0, end: code.length }, '//');
  assert.equal(commented.newText, '// const a = 1;\n// const b = 2;');

  const uncommented = toggleLineComment(commented.newText, { start: 0, end: commented.newText.length }, '//');
  assert.equal(uncommented.newText, code);
});

test('findMatchingBracket locates corresponding braces and parentheses', () => {
  const code = 'function calc(a, [b, c]) { return (a + b); }';
  // Check '(' at index 13: 'calc('
  const matchParen = findMatchingBracket(code, 13);
  assert.equal(matchParen, 23); // ')' after c]

  // Check '{' at index 25
  const matchBrace = findMatchingBracket(code, 25);
  assert.equal(matchBrace, 43); // '}' at end
});
