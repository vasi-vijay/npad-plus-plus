import express from 'express';
import { createServer as createViteServer } from 'vite';
import { exec, ChildProcess } from 'child_process';
import path from 'path';
import fs from 'fs';
import os from 'os';
import { fileURLToPath } from 'url';
import { buildCodeRunPlan } from './src/lib/codeRunner';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Application-managed support directory for session recovery and code staging
const APP_SUPPORT_DIR = path.join(os.tmpdir(), 'codepad-app-support');
const RECOVERY_DIR = path.join(APP_SUPPORT_DIR, 'recovery');
const SESSION_FILE = path.join(RECOVERY_DIR, 'workspace-session.json');
const RUN_STAGING_DIR = path.join(APP_SUPPORT_DIR, 'run-staging');

fs.mkdirSync(RECOVERY_DIR, { recursive: true });
fs.mkdirSync(RUN_STAGING_DIR, { recursive: true });

let activeRunProcess: ChildProcess | null = null;

async function startServer() {
  const app = express();
  const PORT = parseInt(process.env.PORT || '3000', 10);
  const isProd = process.env.NODE_ENV === 'production';

  app.use(express.json({ limit: '15mb' }));

  // API Route: Load persisted workspace session & recovery snapshots
  app.get('/api/session/load', (_req, res) => {
    try {
      if (!fs.existsSync(SESSION_FILE)) {
        res.json({ hasSession: false, session: null });
        return;
      }
      const raw = fs.readFileSync(SESSION_FILE, 'utf-8');
      const session = JSON.parse(raw);

      // Verify on-disk status for any documents backed by a filesystem path
      if (session && Array.isArray(session.documents)) {
        for (const doc of session.documents) {
          if (doc.path && doc.path.includes('/')) {
            const resolved = path.isAbsolute(doc.path)
              ? doc.path
              : path.resolve(process.cwd(), doc.path);
            if (!fs.existsSync(resolved)) {
              doc.isMissingOnDisk = true;
              doc.isModified = true;
            }
          }
        }
      }

      res.json({ hasSession: true, session });
    } catch (err: any) {
      res.json({ hasSession: false, session: null, error: err?.message });
    }
  });

  // API Route: Save workspace session & recovery snapshots atomically
  app.post('/api/session/save', (req, res) => {
    try {
      const { session } = req.body;
      if (!session || typeof session !== 'object') {
        res.status(400).json({ error: 'Valid session object required' });
        return;
      }
      fs.mkdirSync(RECOVERY_DIR, { recursive: true });
      const tmpFile = `${SESSION_FILE}.tmp`;
      fs.writeFileSync(tmpFile, JSON.stringify(session, null, 2), 'utf-8');
      fs.renameSync(tmpFile, SESSION_FILE);
      res.json({ ok: true, savedAt: Date.now() });
    } catch (err: any) {
      res.status(500).json({ error: err?.message || 'Failed to save session' });
    }
  });

  // API Route: Read a real file from workspace or absolute path
  app.get('/api/files/read', (req, res) => {
    const rawPath = req.query.path ? String(req.query.path) : '';
    if (!rawPath) {
      res.status(400).json({ error: 'File path is required' });
      return;
    }
    const resolved = path.isAbsolute(rawPath) ? rawPath : path.resolve(process.cwd(), rawPath);
    try {
      if (!fs.existsSync(resolved)) {
        res.status(404).json({ exists: false, error: 'File does not exist on disk' });
        return;
      }
      const stat = fs.statSync(resolved);
      if (stat.isDirectory()) {
        res.status(400).json({ exists: true, isDirectory: true, error: 'Path is a directory' });
        return;
      }
      const content = fs.readFileSync(resolved, 'utf-8');
      res.json({
        exists: true,
        path: resolved,
        title: path.basename(resolved),
        content,
        mtimeMs: stat.mtimeMs,
      });
    } catch (err: any) {
      res.status(500).json({ exists: false, error: err?.message || 'Failed to read file' });
    }
  });

  // API Route: Save file to disk
  app.post('/api/files/save', (req, res) => {
    const { filePath, content } = req.body;
    if (!filePath || typeof content !== 'string') {
      res.status(400).json({ error: 'filePath and content are required' });
      return;
    }
    const resolved = path.isAbsolute(filePath)
      ? filePath
      : path.join(APP_SUPPORT_DIR, 'saved-files', filePath);
    try {
      fs.mkdirSync(path.dirname(resolved), { recursive: true });
      const tmp = `${resolved}.codepad-tmp`;
      fs.writeFileSync(tmp, content, 'utf-8');
      fs.renameSync(tmp, resolved);
      const stat = fs.statSync(resolved);
      res.json({
        ok: true,
        path: resolved,
        title: path.basename(resolved),
        mtimeMs: stat.mtimeMs,
      });
    } catch (err: any) {
      res.status(500).json({ error: err?.message || 'Failed to save file' });
    }
  });

  // API Route: Execute active source file (Priority 4)
  app.post('/api/run/execute', (req, res) => {
    const { title, filePath, language, content, isModified, cwd } = req.body;
    if (typeof content !== 'string') {
      res.status(400).json({ error: 'Source content is required' });
      return;
    }

    const baseDir = cwd && fs.existsSync(cwd) ? cwd : process.cwd();
    const plan = buildCodeRunPlan({
      title: title || 'Main.java',
      path: filePath,
      language: language || 'plaintext',
      content,
      isModified: Boolean(isModified),
      workspaceDirectory: baseDir,
    });

    if (!plan.supported) {
      res.json({
        supported: false,
        stdout: '',
        stderr: plan.errorMessage || 'Unsupported language for direct execution.',
        exitCode: 1,
        command: '',
        cwd: baseDir,
        durationMs: 0,
      });
      return;
    }

    // Stage the current editor buffer so stale disk files are never silently run
    const executionDir = plan.requiresStaging
      ? path.join(RUN_STAGING_DIR, `job-${Date.now()}`)
      : plan.workingDirectory;

    try {
      fs.mkdirSync(executionDir, { recursive: true });
      const stagedFileFull = path.join(executionDir, plan.stagedRelativePath);
      fs.mkdirSync(path.dirname(stagedFileFull), { recursive: true });
      fs.writeFileSync(stagedFileFull, content, 'utf-8');
    } catch (err: any) {
      res.status(500).json({ error: `Failed to stage source file: ${err?.message}` });
      return;
    }

    const env = {
      ...process.env,
      PATH: `/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${process.env.PATH || ''}`,
      TERM: 'xterm-256color',
    };

    const startTime = Date.now();
    const child = exec(
      plan.command,
      { cwd: executionDir, shell: '/bin/bash', env, timeout: 30000, maxBuffer: 1024 * 1024 * 10 },
      (error, stdout, stderr) => {
        if (activeRunProcess === child) {
          activeRunProcess = null;
        }
        const durationMs = Date.now() - startTime;
        const exitCode = error ? (typeof error.code === 'number' ? error.code : 1) : 0;
        res.json({
          supported: true,
          language: plan.language,
          command: plan.command,
          cwd: plan.workingDirectory,
          stdout: stdout || '',
          stderr: stderr || (error && !stderr ? error.message : ''),
          exitCode,
          durationMs,
        });
      }
    );

    activeRunProcess = child;
  });

  // API Route: Terminate running code execution process
  app.post('/api/run/kill', (_req, res) => {
    if (activeRunProcess) {
      try {
        activeRunProcess.kill('SIGTERM');
      } catch {}
      activeRunProcess = null;
      res.json({ killed: true });
    } else {
      res.json({ killed: false });
    }
  });

  // API Route: Terminal info
  app.get('/api/terminal/info', (_req, res) => {
    const homeDir = process.env.HOME || process.cwd();
    res.json({
      cwd: process.cwd(),
      home: homeDir,
      platform: process.platform,
      arch: process.arch,
      shell: process.env.SHELL || '/bin/zsh',
    });
  });

  // API Route: Run terminal command with persistent cwd and environment resolution
  app.post('/api/terminal/run', (req, res) => {
    const { command, cwd } = req.body;
    if (!command || typeof command !== 'string') {
      res.status(400).json({ error: 'Command string is required' });
      return;
    }

    const trimmed = command.trim();
    const initialCwd = cwd && fs.existsSync(cwd) ? cwd : process.cwd();

    // Prepare enriched environment with macOS & development paths
    const env = {
      ...process.env,
      PATH: `/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${process.env.PATH || ''}`,
      TERM: 'xterm-256color',
    };

    // Special command: clear
    if (trimmed === 'clear') {
      res.json({ stdout: '', stderr: '', exitCode: 0, cwd: initialCwd, isClear: true });
      return;
    }

    // Wrap command in bash/zsh subshell to capture exit code and final working directory (preserving cd)
    const delimiter = '__NOTEPAD_CWD_DELIM__';
    const wrappedScript = `cd ${JSON.stringify(initialCwd)} && { ${trimmed} \n}; __CMD_EXIT=$?; __FINAL_PWD=$(pwd); printf "\n${delimiter}\n%s\n%s" "$__CMD_EXIT" "$__FINAL_PWD"`;

    exec(wrappedScript, { shell: '/bin/bash', env, timeout: 30000, maxBuffer: 1024 * 1024 * 10 }, (error, rawStdout, stderr) => {
      let stdout = rawStdout || '';
      let exitCode = error ? (error.code || 1) : 0;
      let finalCwd = initialCwd;

      if (stdout.includes(delimiter)) {
        const parts = stdout.split(`\n${delimiter}\n`);
        stdout = parts[0];
        if (parts[1]) {
          const metaLines = parts[1].trim().split('\n');
          const parsedCode = parseInt(metaLines[0], 10);
          if (!isNaN(parsedCode)) exitCode = parsedCode;
          if (metaLines[1] && fs.existsSync(metaLines[1])) {
            finalCwd = metaLines[1];
          }
        }
      }

      res.json({
        stdout,
        stderr: stderr || '',
        exitCode,
        cwd: finalCwd,
      });
    });
  });

  // API Route: Git status
  app.get('/api/git/status', (_req, res) => {
    exec('git status --porcelain -b', { cwd: process.cwd() }, (error, stdout) => {
      if (error) {
        res.json({ branch: 'main', modifiedFiles: [], isClean: true, raw: '' });
        return;
      }
      const lines = stdout.trim().split('\n');
      const branchLine = lines[0] || '## main';
      const branchMatch = branchLine.match(/^##\s+([^\s.]+)/);
      const branch = branchMatch ? branchMatch[1] : 'main';

      const modifiedFiles = lines.slice(1).filter(Boolean).map(l => {
        const status = l.slice(0, 2).trim();
        const file = l.slice(3).trim();
        return { status, file };
      });

      res.json({
        branch,
        modifiedFiles,
        isClean: modifiedFiles.length === 0,
        raw: stdout,
      });
    });
  });

  // API Route: Git diff
  app.get('/api/git/diff', (req, res) => {
    const filePath = req.query.file ? String(req.query.file) : '';
    const cmd = filePath ? `git diff -- "${filePath}"` : 'git diff';

    exec(cmd, { cwd: process.cwd() }, (error, stdout, stderr) => {
      res.json({
        diff: stdout || '',
        error: error ? stderr : null,
      });
    });
  });

  // API Route: Git log
  app.get('/api/git/log', (_req, res) => {
    exec('git log -n 10 --pretty=format:"%h - %an, %ar : %s"', { cwd: process.cwd() }, (error, stdout) => {
      res.json({
        logs: stdout ? stdout.split('\n') : ['Initial commit - Notepad++ for Mac v1.0'],
      });
    });
  });

  // API Route: List files
  app.get('/api/files/tree', (_req, res) => {
    function readDirRecursive(dir: string, baseDir: string = dir): any[] {
      try {
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        return entries
          .filter(e => !['node_modules', '.git', 'dist', '.playwright-cli'].includes(e.name))
          .map(e => {
            const full = path.join(dir, e.name);
            const relative = path.relative(baseDir, full);
            if (e.isDirectory()) {
              return {
                name: e.name,
                path: relative,
                type: 'directory',
                children: readDirRecursive(full, baseDir),
              };
            }
            return {
              name: e.name,
              path: relative,
              type: 'file',
              size: fs.statSync(full).size,
            };
          });
      } catch {
        return [];
      }
    }

    const tree = readDirRecursive(process.cwd());
    res.json({ tree });
  });

  // Mount Vite or static files
  if (!isProd) {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    app.use(express.static(path.resolve(__dirname, 'dist')));
    app.get('*', (_req, res) => {
      res.sendFile(path.resolve(__dirname, 'dist', 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Notepad++ macOS Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
