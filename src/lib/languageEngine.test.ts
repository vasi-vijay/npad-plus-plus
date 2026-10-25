import test from 'node:test';
import assert from 'node:assert/strict';
import {
  detectLanguage,
  extractJavaSymbols,
  validateCodeSyntax,
} from './languageEngine';

test('detectLanguage detects languages by file extension and name', () => {
  assert.equal(detectLanguage('App.java').id, 'java');
  assert.equal(detectLanguage('Main.swift').id, 'swift');
  assert.equal(detectLanguage('script.py').id, 'python');
  assert.equal(detectLanguage('server.ts').id, 'typescript');
  assert.equal(detectLanguage('pom.xml').id, 'xml');
  assert.equal(detectLanguage('build.gradle').id, 'gradle');
  assert.equal(detectLanguage('application.properties').id, 'properties');
  assert.equal(detectLanguage('application.yml').id, 'yaml');
  assert.equal(detectLanguage('query.sql').id, 'sql');
  assert.equal(detectLanguage('run.sh').id, 'shell');
  assert.equal(detectLanguage('README.md').id, 'markdown');
  assert.equal(detectLanguage('unknown.xyz').id, 'plaintext');
});

test('extractJavaSymbols extracts classes, methods and Spring annotations', () => {
  const javaCode = `
package com.example.demo;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
public class UserController {

    @GetMapping("/{id}")
    public User getUserById(Long id) {
        return null;
    }

    @PostMapping
    public void createUser(User user) {
    }
}
`;

  const symbols = extractJavaSymbols(javaCode);
  const classSym = symbols.find(s => s.name === 'UserController');
  assert.ok(classSym);
  assert.equal(classSym?.kind, 'class');
  assert.ok(classSym?.annotations.some(a => a.includes('@RestController')));

  const getMethod = symbols.find(s => s.name.startsWith('getUserById'));
  assert.ok(getMethod);
  assert.equal(getMethod?.kind, 'method');
});

test('validateCodeSyntax detects invalid JSON and unclosed brackets', () => {
  const invalidJson = '{"name": "Notepad++", "version": }';
  const jsonErrors = validateCodeSyntax(invalidJson, 'json');
  assert.equal(jsonErrors.length > 0, true);
  assert.equal(jsonErrors[0].rule, 'JSON_SYNTAX');

  const unclosedJava = 'public class Test { void run() { }';
  const bracketErrors = validateCodeSyntax(unclosedJava, 'java');
  assert.equal(bracketErrors.length > 0, true);
  assert.equal(bracketErrors[0].rule, 'UNCLOSED_BRACKET');
});
