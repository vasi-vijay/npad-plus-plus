import test from 'node:test';
import assert from 'node:assert/strict';
import {
  PluginManager,
  BUILTIN_PLUGINS,
  PluginContext,
} from './pluginSystem';

test('PluginManager initializes with built-in plugins', () => {
  const manager = new PluginManager();
  const plugins = manager.getPlugins();
  assert.equal(plugins.length >= 4, true);

  const jsonPlugin = plugins.find(p => p.id === 'npp-json-tools');
  assert.ok(jsonPlugin);
  assert.equal(jsonPlugin?.enabled, true);
});

test('PluginManager can toggle, install and uninstall plugins', () => {
  const manager = new PluginManager();
  manager.togglePlugin('npp-json-tools', false);
  const jsonPlugin = manager.getPlugins().find(p => p.id === 'npp-json-tools');
  assert.equal(jsonPlugin?.enabled, false);

  const customPlugin = {
    id: 'test-custom',
    name: 'Custom Test Plugin',
    version: '1.0.0',
    author: 'Tester',
    description: 'Unit test plugin',
    minEditorVersion: '1.0.0',
    enabled: true,
    commands: [
      {
        id: 'test.cmd',
        name: 'Test Command',
        execute: () => {},
      },
    ],
  };

  const installRes = manager.installPlugin(customPlugin);
  assert.equal(installRes.success, true);
  assert.ok(manager.getPlugins().find(p => p.id === 'test-custom'));

  const uninstallRes = manager.uninstallPlugin('test-custom');
  assert.equal(uninstallRes, true);
  assert.equal(manager.getPlugins().some(p => p.id === 'test-custom'), false);
});

test('JSON plugin formats text accurately via PluginContext', () => {
  const manager = new PluginManager();
  const jsonPlugin = manager.getPlugins().find(p => p.id === 'npp-json-tools')!;
  const formatCmd = jsonPlugin.commands.find(c => c.id === 'json.format')!;

  let currentText = '{"a":1,"b":2}';
  let message = '';

  const mockCtx: PluginContext = {
    getText: () => currentText,
    setText: (newText: string) => { currentText = newText; },
    getSelection: () => ({ start: 0, end: 0, text: '' }),
    setSelection: () => {},
    getActiveFile: () => ({ name: 'test.json', language: 'json', encoding: 'UTF-8' }),
    showMessage: (msg: string) => { message = msg; },
  };

  formatCmd.execute(mockCtx);
  assert.equal(currentText, '{\n  "a": 1,\n  "b": 2\n}');
  assert.ok(message.includes('formatted'));
});
