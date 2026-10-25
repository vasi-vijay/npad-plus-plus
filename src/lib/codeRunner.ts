export interface TerminalDirectoryResolutionInput {
  workspaceRoot?: string;
  activeFilePath?: string;
  selectedExplorerFolder?: string;
  defaultDirectory?: string;
}

export interface JavaSourceAnalysis {
  packageName: string | null;
  className: string;
  hasMainMethod: boolean;
  qualifiedClassName: string;
}

export interface RunPlan {
  supported: boolean;
  language: string;
  command: string;
  workingDirectory: string;
  requiresStaging: boolean;
  stagedRelativePath: string;
  errorMessage?: string;
}

/**
 * Extracts the parent directory of a file path (handling POSIX `/` and Windows `\` separators).
 */
export function getParentDirectory(filePath: string | undefined): string | null {
  if (!filePath || !filePath.trim()) return null;
  const normalized = filePath.trim().replace(/\\/g, '/');
  const lastSlash = normalized.lastIndexOf('/');
  if (lastSlash === -1) {
    return null; // Bare filename with no directory component
  }
  if (lastSlash === 0) {
    return '/';
  }
  return normalized.slice(0, lastSlash);
}

/**
 * Resolves the appropriate working directory when opening the terminal from the editor
 * or toolbar:
 *  - For "Open Terminal Here" (preferActiveFileDir = true):
 *    1. Parent directory of the active file (if saved on disk with a directory path)
 *    2. Current project / workspace root
 *    3. Selected folder in file explorer
 *    4. User's default terminal directory
 *  - For general terminal opening (preferActiveFileDir = false):
 *    1. Current project / workspace root
 *    2. Parent directory of the active file
 *    3. Selected folder in file explorer
 *    4. User's default terminal directory
 */
export function resolveTerminalDirectory(
  input: TerminalDirectoryResolutionInput,
  preferActiveFileDir = true
): string {
  const fileParent = getParentDirectory(input.activeFilePath);
  const workspace = input.workspaceRoot?.trim() || null;
  const explorer = input.selectedExplorerFolder?.trim() || null;
  const fallback = input.defaultDirectory?.trim() || '/tmp';

  if (preferActiveFileDir) {
    return fileParent || workspace || explorer || fallback;
  }
  return workspace || fileParent || explorer || fallback;
}

/**
 * Inspects Java source code to extract `package ...;`, primary class name,
 * and whether a `main` entry point exists.
 */
export function analyzeJavaSource(content: string, fallbackFileName = 'Main.java'): JavaSourceAnalysis {
  // Strip block and line comments for reliable regex parsing
  const stripped = content
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/.*$/gm, '');

  const pkgMatch = stripped.match(/^\s*package\s+([a-zA-Z_][\w.]*)\s*;/m);
  const packageName = pkgMatch ? pkgMatch[1] : null;

  const publicClassMatch = stripped.match(/\bpublic\s+(?:final\s+|abstract\s+)?class\s+([A-Za-z_]\w*)/);
  const anyClassMatch = stripped.match(/\bclass\s+([A-Za-z_]\w*)/);

  const fileStem = fallbackFileName.replace(/\.java$/i, '') || 'Main';
  const className = publicClassMatch?.[1] || anyClassMatch?.[1] || fileStem;

  const hasMainMethod = /\bpublic\s+static\s+void\s+main\s*\(\s*String\s*(?:\[\s*\]|\.\.\.)\s*\w*\s*\)/.test(stripped) ||
    /\bstatic\s+public\s+void\s+main\s*\(/.test(stripped);

  const qualifiedClassName = packageName ? `${packageName}.${className}` : className;

  return {
    packageName,
    className,
    hasMainMethod,
    qualifiedClassName,
  };
}

/**
 * Builds an execution plan for running the active source file from the editor.
 */
export function buildCodeRunPlan(params: {
  title: string;
  path?: string;
  language: string;
  content: string;
  isModified: boolean;
  workspaceDirectory: string;
  projectBuildTool?: 'maven' | 'gradle' | 'none';
}): RunPlan {
  const { title, path, language, content, isModified, workspaceDirectory, projectBuildTool = 'none' } = params;
  const ext = (title.includes('.') ? title.split('.').pop() : '')?.toLowerCase() || '';
  const langLower = language.toLowerCase();

  const fileDir = getParentDirectory(path) || workspaceDirectory || '/tmp';
  const hasRealPath = Boolean(path && path.includes('/'));
  const requiresStaging = !hasRealPath || isModified;

  // 1. Java (.java)
  if (langLower === 'java' || ext === 'java') {
    const javaInfo = analyzeJavaSource(content, title);
    const javaFileName = `${javaInfo.className}.java`;
    const packageRelDir = javaInfo.packageName ? javaInfo.packageName.replace(/\./g, '/') : '';
    const stagedRelativePath = packageRelDir ? `${packageRelDir}/${javaFileName}` : javaFileName;

    // Detect Spring Boot or Maven/Gradle project if applicable
    const isSpringBoot = content.includes('@SpringBootApplication') || content.includes('SpringApplication.run');

    if (projectBuildTool === 'maven' && !requiresStaging) {
      return {
        supported: true,
        language: 'Java',
        command: isSpringBoot
          ? `mvn spring-boot:run`
          : `mvn compile exec:java -Dexec.mainClass="${javaInfo.qualifiedClassName}"`,
        workingDirectory: fileDir,
        requiresStaging: false,
        stagedRelativePath,
      };
    }

    if (projectBuildTool === 'gradle' && !requiresStaging) {
      return {
        supported: true,
        language: 'Java',
        command: isSpringBoot ? `./gradlew bootRun` : `./gradlew run`,
        workingDirectory: fileDir,
        requiresStaging: false,
        stagedRelativePath,
      };
    }

    // Standalone or staged Java compilation + execution
    // javac -d . <stagedRelativePath> && java -cp . <qualifiedClassName>
    return {
      supported: true,
      language: 'Java',
      command: `javac -d . "${stagedRelativePath}" && java -cp . ${javaInfo.qualifiedClassName}`,
      workingDirectory: fileDir,
      requiresStaging: true, // Always stage or sync Java to ensure package structure and latest buffer are compiled
      stagedRelativePath,
    };
  }

  // 2. Python (.py)
  if (langLower === 'python' || ext === 'py') {
    const safeName = title.endsWith('.py') ? title : `${title || 'script'}.py`;
    const targetFile = requiresStaging ? safeName : (path || safeName);
    return {
      supported: true,
      language: 'Python',
      command: `python3 "${targetFile}"`,
      workingDirectory: fileDir,
      requiresStaging,
      stagedRelativePath: safeName,
    };
  }

  // 3. JavaScript (.js, .mjs, .cjs)
  if (langLower === 'javascript' || ext === 'js' || ext === 'mjs' || ext === 'cjs') {
    const safeName = /\.(m|c)?js$/i.test(title) ? title : `${title || 'script'}.js`;
    const targetFile = requiresStaging ? safeName : (path || safeName);
    return {
      supported: true,
      language: 'JavaScript',
      command: `node "${targetFile}"`,
      workingDirectory: fileDir,
      requiresStaging,
      stagedRelativePath: safeName,
    };
  }

  // 4. TypeScript (.ts, .tsx)
  if (langLower === 'typescript' || ext === 'ts' || ext === 'tsx') {
    const safeName = /\.tsx?$/i.test(title) ? title : `${title || 'script'}.ts`;
    const targetFile = requiresStaging ? safeName : (path || safeName);
    return {
      supported: true,
      language: 'TypeScript',
      command: `npx tsx "${targetFile}"`,
      workingDirectory: fileDir,
      requiresStaging,
      stagedRelativePath: safeName,
    };
  }

  // 5. Shell (.sh, .bash, .zsh)
  if (langLower === 'shell' || ext === 'sh' || ext === 'bash' || ext === 'zsh') {
    const safeName = /\.(sh|bash|zsh)$/i.test(title) ? title : `${title || 'script'}.sh`;
    const targetFile = requiresStaging ? safeName : (path || safeName);
    return {
      supported: true,
      language: 'Shell',
      command: `bash "${targetFile}"`,
      workingDirectory: fileDir,
      requiresStaging,
      stagedRelativePath: safeName,
    };
  }

  // 6. C (.c)
  if (langLower === 'c' || ext === 'c') {
    const safeName = title.endsWith('.c') ? title : `${title || 'main'}.c`;
    const binName = safeName.replace(/\.c$/i, '') || 'a.out';
    return {
      supported: true,
      language: 'C',
      command: `cc "${safeName}" -o "${binName}" && "./${binName}"`,
      workingDirectory: fileDir,
      requiresStaging: true,
      stagedRelativePath: safeName,
    };
  }

  // 7. C++ (.cpp, .cc, .cxx)
  if (langLower === 'cpp' || langLower === 'c++' || ext === 'cpp' || ext === 'cc' || ext === 'cxx') {
    const safeName = /\.(cpp|cc|cxx)$/i.test(title) ? title : `${title || 'main'}.cpp`;
    const binName = safeName.replace(/\.(cpp|cc|cxx)$/i, '') || 'a.out';
    return {
      supported: true,
      language: 'C++',
      command: `c++ -std=c++17 "${safeName}" -o "${binName}" && "./${binName}"`,
      workingDirectory: fileDir,
      requiresStaging: true,
      stagedRelativePath: safeName,
    };
  }

  // 8. Go (.go)
  if (langLower === 'go' || ext === 'go') {
    const safeName = title.endsWith('.go') ? title : `${title || 'main'}.go`;
    return {
      supported: true,
      language: 'Go',
      command: `go run "${safeName}"`,
      workingDirectory: fileDir,
      requiresStaging: true,
      stagedRelativePath: safeName,
    };
  }

  // 9. Rust (.rs)
  if (langLower === 'rust' || ext === 'rs') {
    const safeName = title.endsWith('.rs') ? title : `${title || 'main'}.rs`;
    const binName = safeName.replace(/\.rs$/i, '') || 'main_rs';
    return {
      supported: true,
      language: 'Rust',
      command: `rustc "${safeName}" -o "${binName}" && "./${binName}"`,
      workingDirectory: fileDir,
      requiresStaging: true,
      stagedRelativePath: safeName,
    };
  }

  return {
    supported: false,
    language,
    command: '',
    workingDirectory: fileDir,
    requiresStaging: false,
    stagedRelativePath: title,
    errorMessage: `Direct execution is not configured for language "${language}" (${title}). Supported languages: Java, Python, JavaScript, TypeScript, Shell, C, C++, Go, Rust.`,
  };
}
