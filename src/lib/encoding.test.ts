import test from 'node:test';
import assert from 'node:assert/strict';
import {
  detectLineEnding,
  convertLineEnding,
  detectEncodingFromBytes,
  encodeTextWithEncoding,
  decodeTextBytes,
} from './encoding';

test('detectLineEnding correctly identifies LF, CRLF, and CR', () => {
  assert.equal(detectLineEnding('hello\nworld\n'), 'LF');
  assert.equal(detectLineEnding('hello\r\nworld\r\n'), 'CRLF');
  assert.equal(detectLineEnding('hello\rworld\r'), 'CR');
  assert.equal(detectLineEnding('hello single line'), 'LF');
});

test('convertLineEnding converts properly between conventions', () => {
  const sample = 'line1\nline2\r\nline3\rline4';
  const crlf = convertLineEnding(sample, 'CRLF');
  assert.equal(crlf, 'line1\r\nline2\r\nline3\r\nline4');

  const lf = convertLineEnding(crlf, 'LF');
  assert.equal(lf, 'line1\nline2\nline3\nline4');

  const cr = convertLineEnding(lf, 'CR');
  assert.equal(cr, 'line1\rline2\rline3\rline4');
});

test('detectEncodingFromBytes detects UTF-8, UTF-8 BOM, UTF-16LE, and UTF-16BE', () => {
  const utf8 = new TextEncoder().encode('Hello');
  assert.equal(detectEncodingFromBytes(utf8), 'UTF-8');

  const utf8Bom = new Uint8Array([0xef, 0xbb, 0xbf, 0x48, 0x69]);
  assert.equal(detectEncodingFromBytes(utf8Bom), 'UTF-8-BOM');

  const utf16le = new Uint8Array([0xff, 0xfe, 0x48, 0x00]);
  assert.equal(detectEncodingFromBytes(utf16le), 'UTF-16LE');

  const utf16be = new Uint8Array([0xfe, 0xff, 0x00, 0x48]);
  assert.equal(detectEncodingFromBytes(utf16be), 'UTF-16BE');
});

test('encodeTextWithEncoding and decodeTextBytes roundtrips properly', () => {
  const text = 'Hello, Apple Silicon Notepad++! 🚀 123';
  for (const enc of ['UTF-8', 'UTF-8-BOM', 'UTF-16LE', 'UTF-16BE'] as const) {
    const encoded = encodeTextWithEncoding(text, enc);
    const decoded = decodeTextBytes(encoded);
    assert.equal(decoded.text, text);
    assert.equal(decoded.encoding, enc);
  }
});
