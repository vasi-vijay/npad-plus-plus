export interface PluginContext {
  getText: () => string;
  setText: (newText: string) => void;
  getSelection: () => { start: number; end: number; text: string };
  setSelection: (start: number, end: number) => void;
  getActiveFile: () => { name: string; language: string; encoding: string };
  showMessage: (msg: string, type?: 'info' | 'success' | 'warning' | 'error') => void;
}

export interface PluginCommand {
  id: string;
  name: string;
  description?: string;
  shortcut?: string;
  execute: (context: PluginContext) => void | Promise<void>;
}

export interface PluginManifest {
  id: string;
  name: string;
  version: string;
  author: string;
  description: string;
  minEditorVersion: string;
  enabled: boolean;
  settings?: Record<string, any>;
  commands: PluginCommand[];
  onDocumentOpen?: (file: { name: string; language: string }, context: PluginContext) => void;
  onBeforeSave?: (context: PluginContext) => void;
}

export const BUILTIN_PLUGINS: PluginManifest[] = [
  {
    id: 'npp-json-tools',
    name: 'JSON Tools & Prettifier',
    version: '1.2.0',
    author: 'Notepad++ Community',
    description: 'Format, minify, and validate JSON data directly within the editor.',
    minEditorVersion: '1.0.0',
    enabled: true,
    commands: [
      {
        id: 'json.format',
        name: 'Format JSON (2 spaces)',
        description: 'Beautify JSON with standard 2-space indentation',
        shortcut: 'Cmd+Shift+F',
        execute: (ctx) => {
          try {
            const sel = ctx.getSelection();
            const target = sel.text || ctx.getText();
            const parsed = JSON.parse(target);
            const formatted = JSON.stringify(parsed, null, 2);
            if (sel.text) {
              const full = ctx.getText();
              ctx.setText(full.slice(0, sel.start) + formatted + full.slice(sel.end));
            } else {
              ctx.setText(formatted);
            }
            ctx.showMessage('JSON successfully formatted!', 'success');
          } catch (e: any) {
            ctx.showMessage(`JSON formatting error: ${e.message}`, 'error');
          }
        },
      },
      {
        id: 'json.minify',
        name: 'Minify JSON (Compact)',
        description: 'Compress JSON by removing all unnecessary whitespace',
        execute: (ctx) => {
          try {
            const sel = ctx.getSelection();
            const target = sel.text || ctx.getText();
            const parsed = JSON.parse(target);
            const minified = JSON.stringify(parsed);
            if (sel.text) {
              const full = ctx.getText();
              ctx.setText(full.slice(0, sel.start) + minified + full.slice(sel.end));
            } else {
              ctx.setText(minified);
            }
            ctx.showMessage('JSON successfully minified!', 'success');
          } catch (e: any) {
            ctx.showMessage(`JSON minify error: ${e.message}`, 'error');
          }
        },
      },
    ],
  },
  {
    id: 'npp-base64-codec',
    name: 'Base64 & URL Codec',
    version: '1.1.0',
    author: 'Notepad++ Community',
    description: 'Encode and decode Base64 and URL-encoded strings.',
    minEditorVersion: '1.0.0',
    enabled: true,
    commands: [
      {
        id: 'codec.base64.encode',
        name: 'Base64 Encode Selection',
        execute: (ctx) => {
          const sel = ctx.getSelection();
          if (!sel.text) {
            ctx.showMessage('Please select text to encode.', 'warning');
            return;
          }
          try {
            const encoded = btoa(unescape(encodeURIComponent(sel.text)));
            const full = ctx.getText();
            ctx.setText(full.slice(0, sel.start) + encoded + full.slice(sel.end));
            ctx.showMessage('Selection encoded to Base64.', 'success');
          } catch (e: any) {
            ctx.showMessage(`Base64 error: ${e.message}`, 'error');
          }
        },
      },
      {
        id: 'codec.base64.decode',
        name: 'Base64 Decode Selection',
        execute: (ctx) => {
          const sel = ctx.getSelection();
          if (!sel.text) {
            ctx.showMessage('Please select text to decode.', 'warning');
            return;
          }
          try {
            const decoded = decodeURIComponent(escape(atob(sel.text.trim())));
            const full = ctx.getText();
            ctx.setText(full.slice(0, sel.start) + decoded + full.slice(sel.end));
            ctx.showMessage('Base64 decoded successfully.', 'success');
          } catch (e: any) {
            ctx.showMessage(`Base64 decode error: ${e.message}`, 'error');
          }
        },
      },
    ],
  },
  {
    id: 'npp-line-sorter',
    name: 'Line Sorter & Deduplicator',
    version: '1.0.4',
    author: 'Notepad++ Community',
    description: 'Sort lines alphabetically, numerically, reverse, and remove duplicates.',
    minEditorVersion: '1.0.0',
    enabled: true,
    commands: [
      {
        id: 'lines.sort.asc',
        name: 'Sort Lines Ascending (A-Z)',
        execute: (ctx) => {
          const sel = ctx.getSelection();
          const target = sel.text || ctx.getText();
          const sorted = target.split('\n').sort((a, b) => a.localeCompare(b)).join('\n');
          if (sel.text) {
            const full = ctx.getText();
            ctx.setText(full.slice(0, sel.start) + sorted + full.slice(sel.end));
          } else {
            ctx.setText(sorted);
          }
          ctx.showMessage('Lines sorted ascending.', 'success');
        },
      },
      {
        id: 'lines.sort.desc',
        name: 'Sort Lines Descending (Z-A)',
        execute: (ctx) => {
          const sel = ctx.getSelection();
          const target = sel.text || ctx.getText();
          const sorted = target.split('\n').sort((a, b) => b.localeCompare(a)).join('\n');
          if (sel.text) {
            const full = ctx.getText();
            ctx.setText(full.slice(0, sel.start) + sorted + full.slice(sel.end));
          } else {
            ctx.setText(sorted);
          }
          ctx.showMessage('Lines sorted descending.', 'success');
        },
      },
      {
        id: 'lines.dedupe',
        name: 'Remove Duplicate Lines',
        execute: (ctx) => {
          const sel = ctx.getSelection();
          const target = sel.text || ctx.getText();
          const lines = target.split('\n');
          const seen = new Set<string>();
          const deduped: string[] = [];
          for (const l of lines) {
            if (!seen.has(l)) {
              seen.add(l);
              deduped.push(l);
            }
          }
          const result = deduped.join('\n');
          const removed = lines.length - deduped.length;
          if (sel.text) {
            const full = ctx.getText();
            ctx.setText(full.slice(0, sel.start) + result + full.slice(sel.end));
          } else {
            ctx.setText(result);
          }
          ctx.showMessage(`Removed ${removed} duplicate line(s).`, 'success');
        },
      },
    ],
  },
  {
    id: 'npp-text-stats',
    name: 'Text Statistics & Word Counter',
    version: '1.0.2',
    author: 'Notepad++ Community',
    description: 'Calculate words, characters, lines, and reading time for the active document.',
    minEditorVersion: '1.0.0',
    enabled: true,
    commands: [
      {
        id: 'stats.count',
        name: 'Show Document Statistics',
        shortcut: 'Cmd+Shift+I',
        execute: (ctx) => {
          const sel = ctx.getSelection();
          const text = sel.text || ctx.getText();
          const lines = text.split('\n').length;
          const chars = text.length;
          const charsNoSpace = text.replace(/\s/g, '').length;
          const words = (text.match(/\b\w+\b/g) || []).length;
          const readingTime = Math.ceil(words / 200);
          ctx.showMessage(
            `Stats: ${words.toLocaleString()} words | ${chars.toLocaleString()} chars (${charsNoSpace} without space) | ${lines.toLocaleString()} lines | ~${readingTime} min read`,
            'info'
          );
        },
      },
    ],
  },
  {
    id: 'npp-spring-generator',
    name: 'Java & Spring Boot Templates',
    version: '2.0.0',
    author: 'Apple Silicon Java Team',
    description: 'Quick boilerplate generator for Spring Boot RestController, Service, Entity, and application.properties.',
    minEditorVersion: '1.0.0',
    enabled: true,
    commands: [
      {
        id: 'spring.controller',
        name: 'Insert Spring Boot @RestController Template',
        execute: (ctx) => {
          const snippet = `package com.example.demo.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/items")
public class ItemController {

    @GetMapping
    public ResponseEntity<List<String>> getAllItems() {
        return ResponseEntity.ok(List.of("Item A", "Item B"));
    }

    @PostMapping
    public ResponseEntity<String> createItem(@RequestBody String item) {
        return ResponseEntity.ok("Created: " + item);
    }
}
`;
          ctx.setText(snippet);
          ctx.showMessage('Spring Boot RestController inserted!', 'success');
        },
      },
      {
        id: 'spring.properties',
        name: 'Insert Spring Boot application.properties Template',
        execute: (ctx) => {
          const snippet = `# Spring Boot Application Configuration (macOS Apple Silicon)
server.port=8080
spring.application.name=notepad-demo-service

# Datasource (PostgreSQL / H2)
spring.datasource.url=jdbc:postgresql://localhost:5432/demodb
spring.datasource.username=postgres
spring.datasource.password=secret
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# Logging
logging.level.org.springframework.web=INFO
logging.level.com.example=DEBUG
`;
          ctx.setText(snippet);
          ctx.showMessage('Spring Boot properties template inserted!', 'success');
        },
      },
    ],
  },
];

export class PluginManager {
  private plugins: PluginManifest[];

  constructor(initialPlugins: PluginManifest[] = BUILTIN_PLUGINS) {
    this.plugins = [...initialPlugins];
  }

  public getPlugins(): PluginManifest[] {
    return this.plugins;
  }

  public getEnabledPlugins(): PluginManifest[] {
    return this.plugins.filter((p) => p.enabled);
  }

  public togglePlugin(id: string, enabled: boolean): boolean {
    const plugin = this.plugins.find((p) => p.id === id);
    if (plugin) {
      plugin.enabled = enabled;
      return true;
    }
    return false;
  }

  public installPlugin(manifest: PluginManifest): { success: boolean; error?: string } {
    if (!manifest.id || !manifest.name || !manifest.version) {
      return { success: false, error: 'Manifest missing required id, name, or version' };
    }
    if (this.plugins.some((p) => p.id === manifest.id)) {
      return { success: false, error: `Plugin with ID '${manifest.id}' is already installed.` };
    }
    this.plugins.push({ ...manifest, enabled: true });
    return { success: true };
  }

  public uninstallPlugin(id: string): boolean {
    const idx = this.plugins.findIndex((p) => p.id === id);
    if (idx !== -1) {
      this.plugins.splice(idx, 1);
      return true;
    }
    return false;
  }

  public getAllCommands(): { pluginId: string; command: PluginCommand }[] {
    const list: { pluginId: string; command: PluginCommand }[] = [];
    for (const p of this.plugins) {
      if (p.enabled) {
        for (const cmd of p.commands) {
          list.push({ pluginId: p.id, command: cmd });
        }
      }
    }
    return list;
  }
}
