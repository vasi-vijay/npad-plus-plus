export interface LanguageDefinition {
  id: string;
  name: string;
  extensions: string[];
  filenames?: string[];
  lineComment?: string;
  blockComment?: [string, string];
  keywords: string[];
  typeKeywords?: string[];
  builtins?: string[];
}

export const SUPPORTED_LANGUAGES: LanguageDefinition[] = [
  {
    id: 'java',
    name: 'Java',
    extensions: ['.java'],
    filenames: [],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'abstract', 'assert', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 'class',
      'const', 'continue', 'default', 'do', 'double', 'else', 'enum', 'extends', 'final',
      'finally', 'float', 'for', 'goto', 'if', 'implements', 'import', 'instanceof', 'int',
      'interface', 'long', 'native', 'new', 'package', 'private', 'protected', 'public',
      'return', 'short', 'static', 'strictfp', 'super', 'switch', 'synchronized', 'this',
      'throw', 'throws', 'transient', 'try', 'void', 'volatile', 'while', 'record', 'sealed',
      'permits', 'var', 'yield'
    ],
    typeKeywords: ['String', 'Integer', 'Long', 'Double', 'Boolean', 'List', 'Map', 'Set', 'Optional', 'ResponseEntity'],
  },
  {
    id: 'swift',
    name: 'Swift',
    extensions: ['.swift'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'associatedtype', 'class', 'deinit', 'enum', 'extension', 'fileprivate', 'func', 'import',
      'init', 'inout', 'internal', 'let', 'open', 'operator', 'private', 'precedencegroup',
      'protocol', 'public', 'rethrows', 'static', 'struct', 'subscript', 'typealias', 'var',
      'break', 'case', 'catch', 'continue', 'default', 'defer', 'do', 'else', 'fallthrough',
      'for', 'guard', 'if', 'in', 'repeat', 'return', 'throw', 'switch', 'where', 'while',
      'as', 'Any', 'false', 'is', 'nil', 'self', 'Self', 'super', 'true', 'try', 'await', 'async'
    ],
    typeKeywords: ['Int', 'Double', 'Float', 'String', 'Bool', 'Array', 'Dictionary', 'Set', 'View', 'App', 'Scene'],
  },
  {
    id: 'typescript',
    name: 'TypeScript',
    extensions: ['.ts', '.tsx', '.mts'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'break', 'case', 'catch', 'class', 'const', 'continue', 'debugger', 'default', 'delete',
      'do', 'else', 'export', 'extends', 'false', 'finally', 'for', 'function', 'if', 'import',
      'in', 'instanceof', 'new', 'null', 'return', 'super', 'switch', 'this', 'throw', 'true',
      'try', 'typeof', 'var', 'void', 'while', 'with', 'let', 'static', 'yield', 'await', 'async',
      'type', 'interface', 'as', 'readonly', 'enum', 'declare', 'implements', 'namespace'
    ],
    typeKeywords: ['string', 'number', 'boolean', 'any', 'void', 'unknown', 'never', 'Promise', 'Record'],
  },
  {
    id: 'javascript',
    name: 'JavaScript',
    extensions: ['.js', '.jsx', '.mjs', '.cjs'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'break', 'case', 'catch', 'class', 'const', 'continue', 'debugger', 'default', 'delete',
      'do', 'else', 'export', 'extends', 'false', 'finally', 'for', 'function', 'if', 'import',
      'in', 'instanceof', 'new', 'null', 'return', 'super', 'switch', 'this', 'throw', 'true',
      'try', 'typeof', 'var', 'void', 'while', 'with', 'let', 'static', 'yield', 'await', 'async'
    ],
  },
  {
    id: 'python',
    name: 'Python',
    extensions: ['.py', '.pyw', '.ipynb'],
    lineComment: '#',
    keywords: [
      'and', 'as', 'assert', 'async', 'await', 'break', 'class', 'continue', 'def', 'del',
      'elif', 'else', 'except', 'False', 'finally', 'for', 'from', 'global', 'if', 'import',
      'in', 'is', 'lambda', 'None', 'nonlocal', 'not', 'or', 'pass', 'raise', 'return',
      'True', 'try', 'while', 'with', 'yield'
    ],
    typeKeywords: ['int', 'float', 'str', 'bool', 'list', 'dict', 'set', 'tuple', 'Optional', 'Union'],
  },
  {
    id: 'cpp',
    name: 'C / C++',
    extensions: ['.cpp', '.c', '.h', '.hpp', '.cc', '.cxx'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do', 'double', 'else',
      'enum', 'extern', 'float', 'for', 'goto', 'if', 'int', 'long', 'register', 'return',
      'short', 'signed', 'sizeof', 'static', 'struct', 'switch', 'typedef', 'union', 'unsigned',
      'void', 'volatile', 'while', 'class', 'namespace', 'template', 'typename', 'using',
      'virtual', 'public', 'protected', 'private', 'override', 'nullptr', 'constexpr'
    ],
  },
  {
    id: 'csharp',
    name: 'C#',
    extensions: ['.cs'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char', 'checked',
      'class', 'const', 'continue', 'decimal', 'default', 'delegate', 'do', 'double', 'else',
      'enum', 'event', 'explicit', 'extern', 'false', 'finally', 'fixed', 'float', 'for',
      'foreach', 'goto', 'if', 'implicit', 'in', 'int', 'interface', 'internal', 'is', 'lock',
      'long', 'namespace', 'new', 'null', 'object', 'operator', 'out', 'override', 'params',
      'private', 'protected', 'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed', 'short',
      'sizeof', 'stackalloc', 'static', 'string', 'struct', 'switch', 'this', 'throw', 'true',
      'try', 'typeof', 'uint', 'ulong', 'unchecked', 'unsafe', 'ushort', 'using', 'virtual',
      'void', 'volatile', 'while', 'async', 'await', 'var'
    ],
  },
  {
    id: 'go',
    name: 'Go',
    extensions: ['.go'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'break', 'default', 'func', 'interface', 'select', 'case', 'defer', 'go', 'map', 'struct',
      'chan', 'else', 'goto', 'package', 'switch', 'const', 'fallthrough', 'if', 'range', 'type',
      'continue', 'for', 'import', 'return', 'var'
    ],
  },
  {
    id: 'rust',
    name: 'Rust',
    extensions: ['.rs'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: [
      'as', 'async', 'await', 'break', 'const', 'continue', 'crate', 'dyn', 'else', 'enum',
      'extern', 'false', 'fn', 'for', 'if', 'impl', 'in', 'let', 'loop', 'match', 'mod',
      'move', 'mut', 'pub', 'ref', 'return', 'self', 'Self', 'static', 'struct', 'super',
      'trait', 'true', 'type', 'unsafe', 'use', 'where', 'while'
    ],
  },
  {
    id: 'html',
    name: 'HTML',
    extensions: ['.html', '.htm'],
    blockComment: ['<!--', '-->'],
    keywords: ['html', 'head', 'body', 'div', 'span', 'p', 'a', 'script', 'style', 'button', 'input', 'form'],
  },
  {
    id: 'css',
    name: 'CSS',
    extensions: ['.css', '.scss', '.sass', '.less'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: ['display', 'margin', 'padding', 'color', 'background', 'font', 'border', 'flex', 'grid'],
  },
  {
    id: 'xml',
    name: 'XML',
    extensions: ['.xml', '.xsd', '.wsdl'],
    filenames: ['pom.xml'],
    blockComment: ['<!--', '-->'],
    keywords: ['xml', 'project', 'modelVersion', 'groupId', 'artifactId', 'version', 'dependencies', 'dependency'],
  },
  {
    id: 'json',
    name: 'JSON',
    extensions: ['.json', '.jsonc'],
    keywords: ['true', 'false', 'null'],
  },
  {
    id: 'yaml',
    name: 'YAML',
    extensions: ['.yml', '.yaml'],
    filenames: ['application.yml', 'application-dev.yml', 'application-prod.yml'],
    lineComment: '#',
    keywords: ['true', 'false', 'null', 'yes', 'no'],
  },
  {
    id: 'sql',
    name: 'SQL',
    extensions: ['.sql'],
    lineComment: '--',
    blockComment: ['/*', '*/'],
    keywords: [
      'SELECT', 'FROM', 'WHERE', 'INSERT', 'INTO', 'UPDATE', 'DELETE', 'JOIN', 'LEFT', 'RIGHT',
      'INNER', 'OUTER', 'GROUP', 'BY', 'ORDER', 'HAVING', 'LIMIT', 'OFFSET', 'CREATE', 'TABLE',
      'ALTER', 'DROP', 'INDEX', 'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'AND', 'OR', 'NOT',
      'NULL', 'IS', 'AS', 'DISTINCT', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'VALUES', 'SET'
    ],
  },
  {
    id: 'shell',
    name: 'Shell / Bash',
    extensions: ['.sh', '.bash', '.zsh'],
    lineComment: '#',
    keywords: ['if', 'then', 'else', 'elif', 'fi', 'case', 'esac', 'for', 'while', 'until', 'do', 'done', 'in', 'function', 'echo', 'exit'],
  },
  {
    id: 'markdown',
    name: 'Markdown',
    extensions: ['.md', '.markdown'],
    keywords: [],
  },
  {
    id: 'properties',
    name: 'Properties',
    extensions: ['.properties', '.env', '.conf', '.ini'],
    filenames: ['application.properties', 'application-dev.properties'],
    lineComment: '#',
    keywords: ['spring', 'server', 'datasource', 'jpa', 'logging', 'management'],
  },
  {
    id: 'gradle',
    name: 'Gradle',
    extensions: ['.gradle'],
    filenames: ['build.gradle', 'settings.gradle', 'build.gradle.kts', 'settings.gradle.kts'],
    lineComment: '//',
    blockComment: ['/*', '*/'],
    keywords: ['plugins', 'repositories', 'dependencies', 'tasks', 'group', 'version', 'implementation', 'testImplementation'],
  },
  {
    id: 'log',
    name: 'Log File',
    extensions: ['.log'],
    keywords: ['INFO', 'WARN', 'ERROR', 'DEBUG', 'TRACE', 'FATAL'],
  },
  {
    id: 'plaintext',
    name: 'Plain Text',
    extensions: ['.txt'],
    keywords: [],
  },
];

/**
 * Detects programming language by filename and extension.
 */
export function detectLanguage(filename: string): LanguageDefinition {
  const lower = filename.toLowerCase();

  // Check exact filename matches first (e.g. pom.xml, build.gradle, application.properties)
  for (const lang of SUPPORTED_LANGUAGES) {
    if (lang.filenames && lang.filenames.some(fn => lower === fn.toLowerCase() || lower.endsWith('/' + fn.toLowerCase()))) {
      return lang;
    }
  }

  // Check extensions
  for (const lang of SUPPORTED_LANGUAGES) {
    for (const ext of lang.extensions) {
      if (lower.endsWith(ext)) {
        return lang;
      }
    }
  }

  // Fallback to plain text
  return SUPPORTED_LANGUAGES.find(l => l.id === 'plaintext')!;
}

export interface JavaSymbol {
  name: string;
  kind: 'class' | 'interface' | 'record' | 'enum' | 'method' | 'field' | 'annotation';
  lineNumber: number;
  annotations: string[];
}

/**
 * Extracts symbols (classes, methods, fields, Spring Boot annotations) from Java source code.
 */
export function extractJavaSymbols(code: string): JavaSymbol[] {
  const symbols: JavaSymbol[] = [];
  const lines = code.split('\n');
  let currentAnnotations: string[] = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    const lineNum = i + 1;

    if (line.startsWith('@')) {
      currentAnnotations.push(line);
      continue;
    }

    // Match class / interface / record / enum
    const typeMatch = line.match(/(?:public|protected|private)?\s*(?:static)?\s*(?:final)?\s*(class|interface|record|enum)\s+([A-Za-z0-9_]+)/);
    if (typeMatch) {
      symbols.push({
        name: typeMatch[2],
        kind: typeMatch[1] as any,
        lineNumber: lineNum,
        annotations: [...currentAnnotations],
      });
      currentAnnotations = [];
      continue;
    }

    // Match methods (e.g. public String getName() { or void run();)
    const methodMatch = line.match(/(?:public|protected|private|static|final|\s)*\s+([A-Za-z0-9_<>,\[\]]+)\s+([A-Za-z0-9_]+)\s*\(([^)]*)\)\s*(?:throws\s+[A-Za-z0-9_,\s]+)?\s*[{;]?/);
    if (methodMatch && !['if', 'for', 'while', 'switch', 'catch', 'new', 'return'].includes(methodMatch[2])) {
      symbols.push({
        name: `${methodMatch[2]}(...) : ${methodMatch[1]}`,
        kind: 'method',
        lineNumber: lineNum,
        annotations: [...currentAnnotations],
      });
      currentAnnotations = [];
      continue;
    }

    // Reset pending annotations if line is empty or doesn't match
    if (line.length === 0 || line.startsWith('//') || line.startsWith('/*')) {
      // keep or clear depending on empty
    } else {
      currentAnnotations = [];
    }
  }

  return symbols;
}

export interface CodeDiagnostic {
  line: number;
  column: number;
  message: string;
  severity: 'error' | 'warning' | 'info';
  rule?: string;
}

/**
 * Validates syntax for structured formats (JSON, XML, Spring properties, unclosed brackets).
 */
export function validateCodeSyntax(code: string, languageId: string): CodeDiagnostic[] {
  const diagnostics: CodeDiagnostic[] = [];

  if (languageId === 'json') {
    try {
      JSON.parse(code);
    } catch (e: any) {
      const match = e.message.match(/position (\d+)/i);
      let line = 1;
      let col = 1;
      if (match) {
        const pos = parseInt(match[1], 10);
        const upToPos = code.slice(0, pos);
        const parts = upToPos.split('\n');
        line = parts.length;
        col = parts[parts.length - 1].length + 1;
      }
      diagnostics.push({
        line,
        column: col,
        message: e.message,
        severity: 'error',
        rule: 'JSON_SYNTAX',
      });
    }
  }

  if (languageId === 'xml') {
    // Quick XML tag balance check
    const tagRegex = /<\/?([a-zA-Z0-9_\-:]+)(?:\s+[^>]*?)?(\/?)>/g;
    const stack: { tag: string; line: number }[] = [];
    const lines = code.split('\n');

    for (let l = 0; l < lines.length; l++) {
      const lineStr = lines[l];
      let match: RegExpExecArray | null;
      while ((match = tagRegex.exec(lineStr)) !== null) {
        const full = match[0];
        const tagName = match[1];
        const isSelfClosing = match[2] === '/' || full.endsWith('/>') || full.startsWith('<?');

        if (isSelfClosing) continue;

        if (full.startsWith('</')) {
          const top = stack.pop();
          if (!top || top.tag !== tagName) {
            diagnostics.push({
              line: l + 1,
              column: match.index + 1,
              message: `Mismatched XML closing tag </${tagName}> (expected </${top?.tag || 'none'}>)`,
              severity: 'error',
              rule: 'XML_TAG_MISMATCH',
            });
          }
        } else {
          stack.push({ tag: tagName, line: l + 1 });
        }
      }
    }

    for (const unclosed of stack) {
      diagnostics.push({
        line: unclosed.line,
        column: 1,
        message: `Unclosed XML tag <${unclosed.tag}>`,
        severity: 'warning',
        rule: 'XML_UNCLOSED_TAG',
      });
    }
  }

  // Bracket balance check for C-style and Java/Swift code
  if (['java', 'swift', 'typescript', 'javascript', 'cpp', 'csharp', 'rust', 'go'].includes(languageId)) {
    const stack: { char: string; line: number; col: number }[] = [];
    const lines = code.split('\n');

    for (let l = 0; l < lines.length; l++) {
      const lineStr = lines[l];
      for (let c = 0; c < lineStr.length; c++) {
        const ch = lineStr[c];
        if (ch === '{' || ch === '(' || ch === '[') {
          stack.push({ char: ch, line: l + 1, col: c + 1 });
        } else if (ch === '}' || ch === ')' || ch === ']') {
          const expected = ch === '}' ? '{' : ch === ')' ? '(' : '[';
          const top = stack.pop();
          if (!top || top.char !== expected) {
            diagnostics.push({
              line: l + 1,
              column: c + 1,
              message: `Unmatched closing bracket '${ch}'`,
              severity: 'error',
              rule: 'BRACKET_MISMATCH',
            });
          }
        }
      }
    }

    for (const unclosed of stack) {
      diagnostics.push({
        line: unclosed.line,
        column: unclosed.col,
        message: `Unclosed bracket '${unclosed.char}'`,
        severity: 'warning',
        rule: 'UNCLOSED_BRACKET',
      });
    }
  }

  return diagnostics;
}
