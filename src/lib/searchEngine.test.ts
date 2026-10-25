import test from 'node:test';
import assert from 'node:assert/strict';
import {
  findAllMatches,
  getNextMatchIndex,
  getPreviousMatchIndex,
  replaceAllText,
} from './searchEngine';

test('findAllMatches finds case-insensitive matches', () => {
  const text = 'CodePad on macOS. Fast codePad editor.';
  const res = findAllMatches(text, 'codepad', {
    caseSensitive: false,
    wholeWord: false,
    isRegex: false,
    wrapAround: true,
  });
  assert.equal(res.totalCount, 2);
  assert.equal(res.matches.length, 2);
  assert.equal(res.matches[0].index, 0);
});

test('findAllMatches respects case-sensitivity', () => {
  const text = 'Hello hello HELLO';
  const res = findAllMatches(text, 'hello', {
    caseSensitive: true,
    wholeWord: false,
    isRegex: false,
    wrapAround: true,
  });
  assert.equal(res.totalCount, 1);
  assert.equal(res.matches[0].index, 6);
});

test('findAllMatches respects whole-word boundary', () => {
  const text = 'cat catch scatter concatenate cat';
  const res = findAllMatches(text, 'cat', {
    caseSensitive: false,
    wholeWord: true,
    isRegex: false,
    wrapAround: true,
  });
  assert.equal(res.totalCount, 2);
});

test('findAllMatches handles regular expressions and invalid syntax safely', () => {
  const text = 'func1(), func2(), test3()';
  const res = findAllMatches(text, 'func\\d\\(\\)', {
    caseSensitive: false,
    wholeWord: false,
    isRegex: true,
    wrapAround: true,
  });
  assert.equal(res.totalCount, 2);

  const invalid = findAllMatches(text, '[unclosed', {
    caseSensitive: false,
    wholeWord: false,
    isRegex: true,
    wrapAround: true,
  });
  assert.equal(invalid.totalCount, 0);
  assert.ok(invalid.error);
});

test('findAllMatches handles Unicode and accented characters', () => {
  const text = 'Café crème, café au lait, crème brûlée';
  const res = findAllMatches(text, 'café', {
    caseSensitive: false,
    wholeWord: false,
    isRegex: false,
    wrapAround: true,
  });
  assert.equal(res.totalCount, 2);
});

test('navigation wraps correctly', () => {
  assert.equal(getNextMatchIndex(1, 3, true), 2);
  assert.equal(getNextMatchIndex(3, 3, true), 1);
  assert.equal(getNextMatchIndex(3, 3, false), null);

  assert.equal(getPreviousMatchIndex(2, 3, true), 1);
  assert.equal(getPreviousMatchIndex(1, 3, true), 3);
  assert.equal(getPreviousMatchIndex(1, 3, false), null);
});

test('replaceAllText replaces all occurrences correctly', () => {
  const text = 'alpha beta alpha gamma alpha';
  const res = replaceAllText(text, 'alpha', 'delta', {
    caseSensitive: false,
    wholeWord: false,
    isRegex: false,
    wrapAround: true,
  });
  assert.equal(res.count, 3);
  assert.equal(res.newText, 'delta beta delta gamma delta');
});
