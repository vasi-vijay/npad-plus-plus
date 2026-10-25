import test from 'node:test';
import assert from 'node:assert/strict';
import { TabItem } from '../types.ts';
import {
  createDocumentId,
  createUntitledDocument,
  getDocumentLifecycleState,
  recordDocumentEdit,
  undoDocument,
  redoDocument,
  canUndoDocument,
  canRedoDocument,
  markDocumentSaved,
  applyTabCloseDecision,
  detectExternalFileConflict,
  handleMissingDiskFile,
  serializeWorkspaceSession,
  deserializeWorkspaceSession,
} from './sessionRecovery.ts';
import {
  getParentDirectory,
  resolveTerminalDirectory,
  analyzeJavaSource,
  buildCodeRunPlan,
} from './codeRunner.ts';
import {
  expandExtendedEscapes,
  findAllMatches,
  replaceAll,
} from './search.ts';

function makeDiskDocument(path: string, content: string, language: string): TabItem {
  const title = path.split('/').pop() || 'file.txt';
  return {
    id: createDocumentId(),
    title,
    path,
    content,
    savedContent: content,
    isModified: false,
    hasEverBeenSaved: true,
    isMissingOnDisk: false,
    language,
    encoding: 'UTF-8',
    lineEnding: 'LF',
    bookmarks: [],
    cursorLine: 1,
    cursorCol: 1,
    selectionStart: 0,
    selectionEnd: 0,
    scrollTop: 0,
    scrollLeft: 0,
    undoStack: [],
    redoStack: [],
  };
}

test('Scenario A — Unsaved New Document Recovery across restart', () => {
  const doc = createUntitledDocument(1);
  assert.equal(getDocumentLifecycleState(doc), 'untitled-clean');
  assert.equal(doc.hasEverBeenSaved, false);
  assert.equal(doc.isModified, false);

  const edited = recordDocumentEdit(doc, 'Unsaved critical notes\nLine 2', {
    cursorLine: 2,
    cursorCol: 7,
    label: 'typing',
  });
  assert.equal(edited.isModified, true);
  assert.equal(getDocumentLifecycleState(edited), 'untitled-modified');

  // Persist & restore session without pressing Save
  const serialized = serializeWorkspaceSession([edited], edited.id);
  const restored = deserializeWorkspaceSession(serialized);
  assert.equal(restored.tabs.length, 1);
  assert.equal(restored.activeTabId, edited.id);
  assert.equal(restored.tabs[0].content, 'Unsaved critical notes\nLine 2');
  assert.equal(restored.tabs[0].isModified, true);
  assert.equal(restored.tabs[0].hasEverBeenSaved, false);
  assert.equal(getDocumentLifecycleState(restored.tabs[0]), 'untitled-modified');
});

test('Scenario B — Unsaved Changes to Existing Disk File Preserves Original Disk Content', () => {
  const originalDiskContent = 'public class App {\n  // original\n}\n';
  const doc = makeDiskDocument('/Users/dev/project/App.java', originalDiskContent, 'java');
  assert.equal(getDocumentLifecycleState(doc), 'disk-clean');
  assert.equal(doc.isModified, false);

  const modified = recordDocumentEdit(
    doc,
    'public class App {\n  // unsaved edit\n}\n',
    { cursorLine: 2, cursorCol: 18, label: 'typing' }
  );
  assert.equal(modified.isModified, true);
  assert.equal(getDocumentLifecycleState(modified), 'disk-modified');
  // Original baseline remains intact so original file on disk is not overwritten prematurely
  assert.equal(modified.savedContent, originalDiskContent);

  const serialized = serializeWorkspaceSession([modified], modified.id);
  const restored = deserializeWorkspaceSession(serialized);
  const restoredTab = restored.tabs[0];
  assert.equal(restoredTab.path, '/Users/dev/project/App.java');
  assert.equal(restoredTab.content, 'public class App {\n  // unsaved edit\n}\n');
  assert.equal(restoredTab.savedContent, originalDiskContent);
  assert.equal(restoredTab.isModified, true);
});

test('Scenario C — Multiple Tabs, Order, and Active Tab Restoration', () => {
  const tab1 = recordDocumentEdit(createUntitledDocument(1), 'Draft 1');
  const tab2 = makeDiskDocument('/workspace/main.py', 'print("ok")\n', 'python');
  const tab3 = recordDocumentEdit(
    makeDiskDocument('/workspace/readme.md', '# Title\n', 'markdown'),
    '# Title\nUpdated\n'
  );

  const serialized = serializeWorkspaceSession([tab1, tab2, tab3], tab2.id);
  const restored = deserializeWorkspaceSession(serialized);
  assert.deepEqual(
    restored.tabs.map((t) => t.id),
    [tab1.id, tab2.id, tab3.id]
  );
  assert.equal(restored.activeTabId, tab2.id);
  assert.equal(restored.tabs[0].isModified, true);
  assert.equal(restored.tabs[1].isModified, false);
  assert.equal(restored.tabs[2].isModified, true);
});

test('Scenario D — Safe Closing of Modified Tab (Save, Dont Save, Cancel)', () => {
  const tab1 = recordDocumentEdit(createUntitledDocument(1), 'Important work');
  const tab2 = makeDiskDocument('/workspace/index.js', 'console.log(1);', 'javascript');
  const tabs = [tab1, tab2];

  // 1. Cancel keeps tab open and active
  const cancelRes = applyTabCloseDecision(tabs, tab1.id, tab1.id, 'cancel');
  assert.equal(cancelRes.closed, false);
  assert.equal(cancelRes.tabs.length, 2);
  assert.equal(cancelRes.tabs[0].content, 'Important work');

  // 2. Save commits baseline via callback and closes tab
  let savedSnapshot: TabItem | null = null;
  const saveRes = applyTabCloseDecision(tabs, tab1.id, tab1.id, 'save', (doc) => {
    savedSnapshot = markDocumentSaved(doc, '/workspace/notes.txt');
  });
  assert.equal(saveRes.closed, true);
  assert.ok(savedSnapshot);
  assert.equal((savedSnapshot as TabItem).isModified, false);
  assert.equal((savedSnapshot as TabItem).savedContent, 'Important work');
  assert.equal((savedSnapshot as TabItem).path, '/workspace/notes.txt');
  assert.equal(saveRes.tabs.length, 1);
  assert.equal(saveRes.activeTabId, tab2.id);

  // 3. Don't Save discards recovery and closes tab
  const dontSaveRes = applyTabCloseDecision(tabs, tab1.id, tab1.id, 'dont-save');
  assert.equal(dontSaveRes.closed, true);
  assert.equal(dontSaveRes.discardedRecoveryId, tab1.id);
  assert.equal(dontSaveRes.tabs.length, 1);
});

test('Scenario E — Deleted or Moved Disk File Handling and External Conflict Detection', () => {
  const doc = makeDiskDocument('/workspace/deleted.py', 'x = 1\n', 'python');
  const modified = recordDocumentEdit(doc, 'x = 2\n');

  const missingDoc = handleMissingDiskFile(modified);
  assert.equal(missingDoc.isMissingOnDisk, true);
  assert.equal(missingDoc.isModified, true);
  assert.equal(missingDoc.content, 'x = 2\n');
  assert.equal(getDocumentLifecycleState(missingDoc), 'disk-missing');

  const conflictDoc = detectExternalFileConflict(modified, 'x = 999\n');
  assert.equal(conflictDoc.diskConflictContent, 'x = 999\n');
  assert.equal(getDocumentLifecycleState(conflictDoc), 'disk-conflict');
  // Unsaved buffer must not be overwritten silently
  assert.equal(conflictDoc.content, 'x = 2\n');
});

test('Priority 2 — Per-Document Undo and Redo across Tab Switches and Operations', () => {
  let docA = makeDiskDocument('/workspace/a.txt', 'Hello', 'plaintext');
  let docB = makeDiskDocument('/workspace/b.txt', 'World', 'plaintext');

  assert.equal(canUndoDocument(docA), false);
  assert.equal(canRedoDocument(docA), false);

  // Typing edit in Doc A
  docA = recordDocumentEdit(docA, 'Hello World', { label: 'typing', coalesce: false });
  // Paste edit in Doc A
  docA = recordDocumentEdit(docA, 'Hello World!!!', { label: 'paste', coalesce: false });
  // Replace edit in Doc A
  docA = recordDocumentEdit(docA, 'Hi World!!!', { label: 'replace', coalesce: false });

  // Edit in Doc B independently
  docB = recordDocumentEdit(docB, 'World 123', { label: 'typing', coalesce: false });

  // Switch back to Doc A and Undo 3 times
  assert.equal(canUndoDocument(docA), true);
  docA = undoDocument(docA);
  assert.equal(docA.content, 'Hello World!!!');
  assert.equal(docA.isModified, true);

  docA = undoDocument(docA);
  assert.equal(docA.content, 'Hello World');
  assert.equal(docA.isModified, true);

  docA = undoDocument(docA);
  assert.equal(docA.content, 'Hello');
  // Returning to savedContent marks document unmodified!
  assert.equal(docA.isModified, false);
  assert.equal(canUndoDocument(docA), false);
  assert.equal(canRedoDocument(docA), true);

  // Redo in Doc A
  docA = redoDocument(docA);
  assert.equal(docA.content, 'Hello World');
  assert.equal(docA.isModified, true);

  // Verify Doc B undo stack was completely unaffected
  assert.equal(docB.content, 'World 123');
  docB = undoDocument(docB);
  assert.equal(docB.content, 'World');
  assert.equal(docB.isModified, false);
});

test('Priority 3 — Open Terminal Here Directory Resolution', () => {
  assert.equal(getParentDirectory('/Users/alex/projects/demo/src/Main.java'), '/Users/alex/projects/demo/src');

  const resolvedSaved = resolveTerminalDirectory(
    {
      activeFilePath: '/Users/alex/projects/demo/src/Main.java',
      workspaceRoot: '/Users/alex/projects/demo',
    },
    true
  );
  assert.equal(resolvedSaved, '/Users/alex/projects/demo/src');

  const resolvedUntitled = resolveTerminalDirectory(
    {
      activeFilePath: undefined,
      workspaceRoot: '/Users/alex/projects/demo',
    },
    true
  );
  assert.equal(resolvedUntitled, '/Users/alex/projects/demo');
});

test('Priority 4 — Run File Command Generation for Java, Python, JS, and Shell', () => {
  // 1. Java with package and main class
  const javaCode = `package com.example.app;\npublic class Runner {\n  public static void main(String[] args) {\n    System.out.println("Hi");\n  }\n}`;
  const javaInfo = analyzeJavaSource(javaCode, 'Runner.java');
  assert.equal(javaInfo.packageName, 'com.example.app');
  assert.equal(javaInfo.className, 'Runner');
  assert.equal(javaInfo.qualifiedClassName, 'com.example.app.Runner');
  assert.equal(javaInfo.hasMainMethod, true);

  const javaPlan = buildCodeRunPlan({
    title: 'Runner.java',
    path: '/workspace/Runner.java',
    language: 'java',
    content: javaCode,
    isModified: false,
    workspaceDirectory: '/workspace',
  });
  assert.equal(javaPlan.supported, true);
  assert.equal(javaPlan.language, 'Java');
  assert.ok(javaPlan.command.includes('javac'));
  assert.ok(javaPlan.command.includes('com.example.app.Runner'));

  // 2. Python
  const pyPlan = buildCodeRunPlan({
    title: 'script.py',
    path: '/workspace/script.py',
    language: 'python',
    content: 'print(42)\n',
    isModified: false,
    workspaceDirectory: '/workspace',
  });
  assert.equal(pyPlan.supported, true);
  assert.ok(pyPlan.command.includes('python3'));

  // 3. JavaScript
  const jsPlan = buildCodeRunPlan({
    title: 'index.js',
    path: '/workspace/index.js',
    language: 'javascript',
    content: 'console.log("ok")\n',
    isModified: false,
    workspaceDirectory: '/workspace',
  });
  assert.equal(jsPlan.supported, true);
  assert.ok(jsPlan.command.includes('node'));

  // 4. Shell
  const shPlan = buildCodeRunPlan({
    title: 'build.sh',
    path: '/workspace/build.sh',
    language: 'shell',
    content: 'echo "done"\n',
    isModified: false,
    workspaceDirectory: '/workspace',
  });
  assert.equal(shPlan.supported, true);
  assert.ok(shPlan.command.includes('bash'));
});

test('Priority 5 — Notepad++ Extended Search Mode (\\n, \\t, \\xHH)', () => {
  assert.equal(expandExtendedEscapes('Line1\\nLine2\\tEnd'), 'Line1\nLine2\tEnd');
  const sample = 'col1\tcol2\nrow1\trow2';
  const matches = findAllMatches(sample, {
    query: 'col2\\nrow1',
    caseSensitive: true,
    wholeWord: false,
    useRegex: false,
    searchMode: 'extended',
  });
  assert.equal(matches.length, 1);

  const replaced = replaceAll(
    sample,
    {
      query: '\\t',
      caseSensitive: false,
      wholeWord: false,
      useRegex: false,
      searchMode: 'extended',
    },
    ','
  );
  assert.equal(replaced.count, 2);
  assert.equal(replaced.newText, 'col1,col2\nrow1,row2');
});

test('Theme Definitions — Verify Scrollbars and Dialog Properties for all Themes', async () => {
  const { THEMES, applyThemeVariables } = await import('./themeConfig.ts');
  const themeKeys = Object.keys(THEMES) as (keyof typeof THEMES)[];
  assert.equal(themeKeys.length >= 6, true);

  for (const key of themeKeys) {
    const t = THEMES[key];
    assert.ok(t.name, `Theme ${key} must have a name`);
    assert.ok(t.styles.background, `Theme ${key} must have background`);
    assert.ok(t.styles.foreground, `Theme ${key} must have foreground`);
    assert.ok(t.styles.scrollbarThumb, `Theme ${key} must have scrollbarThumb`);
    assert.ok(t.styles.scrollbarTrack, `Theme ${key} must have scrollbarTrack`);
    assert.ok(t.styles.dialogBg, `Theme ${key} must have dialogBg`);
    assert.ok(t.styles.dialogHeaderBg, `Theme ${key} must have dialogHeaderBg`);
    assert.ok(t.styles.dialogBorder, `Theme ${key} must have dialogBorder`);
    assert.ok(t.styles.dialogFg, `Theme ${key} must have dialogFg`);
    assert.ok(t.styles.inputBg, `Theme ${key} must have inputBg`);
  }

  // Test applyThemeVariables with a mock document.documentElement
  const setProperties: Record<string, string> = {};
  const classList = new Set<string>();
  const mockRoot = {
    style: {
      setProperty: (prop: string, val: string) => {
        setProperties[prop] = val;
      },
    },
    classList: {
      add: (cls: string) => classList.add(cls),
      remove: (cls: string) => classList.delete(cls),
    },
  };

  (globalThis as any).document = {
    documentElement: mockRoot,
  };

  applyThemeVariables(THEMES['dracula'], "'JetBrains Mono', monospace");

  assert.equal(setProperties['--theme-bg'], '#282a36');
  assert.equal(setProperties['--theme-dialog-bg'], '#2c2e3b');
  assert.equal(setProperties['--theme-scrollbar-thumb'], 'rgba(189, 147, 249, 0.35)');
  assert.equal(setProperties['--editor-font-family'], "'JetBrains Mono', monospace");
  assert.ok(classList.has('dark'));

  // Test light theme switch
  applyThemeVariables(THEMES['npp-classic']);
  assert.equal(setProperties['--theme-bg'], '#ffffff');
  assert.equal(setProperties['--theme-dialog-bg'], '#f8f9fa');
  assert.equal(setProperties['--theme-scrollbar-thumb'], 'rgba(0, 0, 0, 0.22)');
  assert.ok(!classList.has('dark'));

  delete (globalThis as any).document;
});
