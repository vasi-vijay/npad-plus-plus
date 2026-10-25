import test from 'node:test';
import assert from 'node:assert/strict';
import {
  findAllMatches,
  replaceNext,
  replaceAll,
  getMarkedLineNumbers,
} from './search';

const sampleCode = `public class UserService {
    private String name;

    public String getName() {
        return this.name;
    }

    public void setName(String name) {
        this.name = name;
    }
}`;

test('findAllMatches respects case sensitivity', () => {
  const matchesCaseInsensitive = findAllMatches(sampleCode, {
    query: 'name',
    caseSensitive: false,
    wholeWord: false,
    useRegex: false,
  });
  // 'name', 'getName', 'name', 'setName', 'name', 'name', 'name'
  assert.equal(matchesCaseInsensitive.length > 3, true);

  const matchesCaseSensitive = findAllMatches(sampleCode, {
    query: 'name',
    caseSensitive: true,
    wholeWord: false,
    useRegex: false,
  });
  // only lowercase 'name'
  for (const m of matchesCaseSensitive) {
    assert.equal(m.lineText.includes('name'), true);
  }
});

test('findAllMatches respects wholeWord option', () => {
  const allName = findAllMatches(sampleCode, {
    query: 'name',
    caseSensitive: false,
    wholeWord: false,
    useRegex: false,
  });
  const wholeWordName = findAllMatches(sampleCode, {
    query: 'name',
    caseSensitive: false,
    wholeWord: true,
    useRegex: false,
  });

  // 'getName' and 'setName' are matched in allName, but excluded in wholeWordName
  assert.equal(allName.length > wholeWordName.length, true);
  assert.equal(wholeWordName.every(m => sampleCode.slice(m.index, m.index + m.length).toLowerCase() === 'name'), true);
});

test('findAllMatches supports regex', () => {
  const methodMatches = findAllMatches(sampleCode, {
    query: 'public\\s+\\w+\\s+\\w+\\(',
    caseSensitive: true,
    wholeWord: false,
    useRegex: true,
  });
  // public String getName(, public void setName(
  assert.equal(methodMatches.length, 2);
});

test('replaceAll replaces all occurrences accurately', () => {
  const { newText, count } = replaceAll(
    'apple banana apple cherry apple',
    { query: 'apple', caseSensitive: true, wholeWord: true, useRegex: false },
    'orange'
  );
  assert.equal(count, 3);
  assert.equal(newText, 'orange banana orange cherry orange');
});

test('replaceNext replaces sequentially', () => {
  const orig = 'cat dog cat mouse';
  const step1 = replaceNext(
    orig,
    { query: 'cat', caseSensitive: true, wholeWord: true, useRegex: false },
    'kitten',
    0
  );
  assert.equal(step1.replaced, true);
  assert.equal(step1.newText, 'kitten dog cat mouse');

  const step2 = replaceNext(
    step1.newText,
    { query: 'cat', caseSensitive: true, wholeWord: true, useRegex: false },
    'kitten',
    step1.nextIndex
  );
  assert.equal(step2.replaced, true);
  assert.equal(step2.newText, 'kitten dog kitten mouse');
});

test('getMarkedLineNumbers finds distinct line numbers', () => {
  const marked = getMarkedLineNumbers(sampleCode, {
    query: 'String',
    caseSensitive: true,
    wholeWord: true,
    useRegex: false,
  });
  // Lines: 2 (private String name), 4 (public String getName), 8 (public void setName(String name))
  assert.deepEqual(marked, [2, 4, 8]);
});
