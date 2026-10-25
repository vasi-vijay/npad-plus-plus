export type LineEnding = 'LF' | 'CRLF' | 'CR';
export type TextEncoding = 'UTF-8' | 'UTF-8-BOM' | 'UTF-16LE' | 'UTF-16BE' | 'ASCII' | 'ISO-8859-1';

/**
 * Detects the line ending convention used in the text.
 * Defaults to LF if no line breaks are present.
 */
export function detectLineEnding(text: string): LineEnding {
  const crlfCount = (text.match(/\r\n/g) || []).length;
  // Count single CR not followed by LF
  const crCount = (text.match(/\r(?!\n)/g) || []).length;
  // Count single LF not preceded by CR
  const lfCount = (text.match(/(?<!\r)\n/g) || []).length;

  if (crlfCount > lfCount && crlfCount >= crCount) {
    return 'CRLF';
  }
  if (crCount > lfCount && crCount > crlfCount) {
    return 'CR';
  }
  return 'LF';
}

/**
 * Normalizes text to the target line ending convention.
 */
export function convertLineEnding(text: string, target: LineEnding): string {
  // First normalize all line breaks to standard \n
  const normalized = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

  switch (target) {
    case 'CRLF':
      return normalized.replace(/\n/g, '\r\n');
    case 'CR':
      return normalized.replace(/\n/g, '\r');
    case 'LF':
    default:
      return normalized;
  }
}

/**
 * Detects byte order marks (BOM) or encoding markers in a buffer or string.
 */
export function detectEncodingFromBytes(bytes: Uint8Array): TextEncoding {
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) {
    return 'UTF-8-BOM';
  }
  if (bytes.length >= 2 && bytes[0] === 0xff && bytes[1] === 0xfe) {
    return 'UTF-16LE';
  }
  if (bytes.length >= 2 && bytes[0] === 0xfe && bytes[1] === 0xff) {
    return 'UTF-16BE';
  }
  return 'UTF-8';
}

/**
 * Encodes text to a Uint8Array respecting the requested encoding and BOM.
 */
export function encodeTextWithEncoding(text: string, encoding: TextEncoding): Uint8Array {
  const encoder = new TextEncoder();
  if (encoding === 'UTF-8-BOM') {
    const raw = encoder.encode(text);
    const withBom = new Uint8Array(raw.length + 3);
    withBom[0] = 0xef;
    withBom[1] = 0xbb;
    withBom[2] = 0xbf;
    withBom.set(raw, 3);
    return withBom;
  }
  if (encoding === 'UTF-16LE') {
    const buffer = new Uint8Array(text.length * 2 + 2);
    buffer[0] = 0xff;
    buffer[1] = 0xfe;
    for (let i = 0; i < text.length; i++) {
      const code = text.charCodeAt(i);
      buffer[2 + i * 2] = code & 0xff;
      buffer[2 + i * 2 + 1] = (code >> 8) & 0xff;
    }
    return buffer;
  }
  if (encoding === 'UTF-16BE') {
    const buffer = new Uint8Array(text.length * 2 + 2);
    buffer[0] = 0xfe;
    buffer[1] = 0xff;
    for (let i = 0; i < text.length; i++) {
      const code = text.charCodeAt(i);
      buffer[2 + i * 2] = (code >> 8) & 0xff;
      buffer[2 + i * 2 + 1] = code & 0xff;
    }
    return buffer;
  }
  return encoder.encode(text);
}

/**
 * Decodes Uint8Array to string, stripping BOM if present.
 */
export function decodeTextBytes(bytes: Uint8Array): { text: string; encoding: TextEncoding } {
  const encoding = detectEncodingFromBytes(bytes);
  let payload = bytes;

  if (encoding === 'UTF-8-BOM') {
    payload = bytes.slice(3);
    return { text: new TextDecoder('utf-8').decode(payload), encoding };
  }
  if (encoding === 'UTF-16LE') {
    payload = bytes.slice(2);
    return { text: new TextDecoder('utf-16le').decode(payload), encoding };
  }
  if (encoding === 'UTF-16BE') {
    payload = bytes.slice(2);
    return { text: new TextDecoder('utf-16be').decode(payload), encoding };
  }
  return { text: new TextDecoder('utf-8').decode(payload), encoding: 'UTF-8' };
}
