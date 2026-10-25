import { LanguageDefinition, SUPPORTED_LANGUAGES } from './languageEngine';

export interface Token {
  text: string;
  type: 'keyword' | 'type' | 'string' | 'comment' | 'number' | 'annotation' | 'operator' | 'text';
}

/**
 * Tokenizes a single line of code based on language definitions.
 */
export function tokenizeLine(line: string, langId: string): Token[] {
  const lang = SUPPORTED_LANGUAGES.find(l => l.id === langId) || SUPPORTED_LANGUAGES[0];
  const tokens: Token[] = [];
  let i = 0;

  const keywordsSet = new Set(lang.keywords.map(k => k.toLowerCase()));
  const typesSet = new Set((lang.typeKeywords || []).map(t => t.toLowerCase()));
  const lineComment = lang.lineComment;

  while (i < line.length) {
    // 1. Check for Line Comments
    if (lineComment && line.startsWith(lineComment, i)) {
      tokens.push({ text: line.slice(i), type: 'comment' });
      break;
    }

    // 2. Check for HTML/XML comment or Block comment starts
    if (line.startsWith('<!--', i)) {
      tokens.push({ text: line.slice(i), type: 'comment' });
      break;
    }
    if (line.startsWith('/*', i)) {
      tokens.push({ text: line.slice(i), type: 'comment' });
      break;
    }

    const ch = line[i];

    // 3. String literals (double quote, single quote, backtick)
    if (ch === '"' || ch === "'" || ch === '`') {
      const quote = ch;
      let end = i + 1;
      let escaped = false;
      while (end < line.length) {
        if (line[end] === '\\' && !escaped) {
          escaped = true;
          end++;
          continue;
        }
        if (line[end] === quote && !escaped) {
          end++;
          break;
        }
        escaped = false;
        end++;
      }
      tokens.push({ text: line.slice(i, end), type: 'string' });
      i = end;
      continue;
    }

    // 4. Java/Spring Boot/Swift Annotations (@RestController, @GetMapping, @State, etc.)
    if (ch === '@' && i + 1 < line.length && /[a-zA-Z_]/.test(line[i + 1])) {
      let end = i + 1;
      while (end < line.length && /[a-zA-Z0-9_]/.test(line[end])) {
        end++;
      }
      tokens.push({ text: line.slice(i, end), type: 'annotation' });
      i = end;
      continue;
    }

    // 5. Numbers
    if (/[0-9]/.test(ch) && (i === 0 || /[\s+\-*/%=<>!&|^,;:({\[]/.test(line[i - 1]))) {
      let end = i;
      while (end < line.length && /[0-9a-fA-FxX._]/.test(line[end])) {
        end++;
      }
      tokens.push({ text: line.slice(i, end), type: 'number' });
      i = end;
      continue;
    }

    // 6. Identifiers (Keywords, Types, Functions, Identifiers)
    if (/[a-zA-Z_$]/.test(ch)) {
      let end = i;
      while (end < line.length && /[a-zA-Z0-9_$]/.test(line[end])) {
        end++;
      }
      const word = line.slice(i, end);
      const lower = word.toLowerCase();

      if (keywordsSet.has(lower) || keywordsSet.has(word)) {
        tokens.push({ text: word, type: 'keyword' });
      } else if (typesSet.has(lower) || typesSet.has(word) || /^[A-Z][a-zA-Z0-9_]*$/.test(word)) {
        // PascalCase convention often represents a Type / Class
        tokens.push({ text: word, type: 'type' });
      } else {
        tokens.push({ text: word, type: 'text' });
      }
      i = end;
      continue;
    }

    // 7. Operators and punctuation
    if (/[+\-*/%=<>!&|^~?:;.,()[\]{}]/.test(ch)) {
      tokens.push({ text: ch, type: 'operator' });
      i++;
      continue;
    }

    // 8. Whitespace and other characters
    tokens.push({ text: ch, type: 'text' });
    i++;
  }

  return tokens;
}
