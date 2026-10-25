import Foundation
import AppKit
import SwiftUI

@main
struct StandaloneRunner {
    // ANSI color codes for terminal reporting
    static let cGreen = "\u{001B}[32m"
    static let cRed = "\u{001B}[31m"
    static let cCyan = "\u{001B}[36m"
    static let cBold = "\u{001B}[1m"
    static let cReset = "\u{001B}[0m"

    static var passCount = 0
    static var failCount = 0

    struct TestFailure: Error, CustomStringConvertible {
        let description: String
    }

    static func runTest(_ name: String, _ block: () throws -> Void) {
        let startTime = DispatchTime.now()
        do {
            try block()
            let elapsed = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0
            print("  \(cGreen)[✓ PASS]\(cReset) \(name) \(cCyan)(\(String(format: "%.2f", elapsed))ms)\(cReset)")
            passCount += 1
        } catch {
            print("  \(cRed)[✗ FAIL]\(cReset) \(name): \(error)")
            failCount += 1
        }
    }

    static func assertTrue(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if !condition() {
            throw TestFailure(description: "Assertion failed: \(message.isEmpty ? "expected true" : message) (line \(line))")
        }
    }

    static func assertFalse(_ condition: @autoclosure () -> Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if condition() {
            throw TestFailure(description: "Assertion failed: \(message.isEmpty ? "expected false" : message) (line \(line))")
        }
    }

    static func assertEqual<T: Equatable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        let valA = a()
        let valB = b()
        if valA != valB {
            throw TestFailure(description: "Assertion failed: '\(valA)' != '\(valB)'. \(message) (line \(line))")
        }
    }

    static func assertNotEqual<T: Equatable>(_ a: @autoclosure () -> T, _ b: @autoclosure () -> T, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        let valA = a()
        let valB = b()
        if valA == valB {
            throw TestFailure(description: "Assertion failed: '\(valA)' == '\(valB)'. \(message) (line \(line))")
        }
    }

    static func assertNil(_ a: @autoclosure () -> Any?, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if a() != nil {
            throw TestFailure(description: "Assertion failed: expected nil. \(message) (line \(line))")
        }
    }

    static func assertNotNil(_ a: @autoclosure () -> Any?, _ message: String = "", file: StaticString = #file, line: UInt = #line) throws {
        if a() == nil {
            throw TestFailure(description: "Assertion failed: expected non-nil. \(message) (line \(line))")
        }
    }

    static func main() {
        print("\n==========================================================")
        print("\(cBold) NPad++ macOS Test Suite (Apple Silicon arm64)\(cReset)")
        print(" Native Standalone Test Runner")
        print("==========================================================")

        runTest("testDocumentCreationAndDefaults") {
            let doc = EditorDocument(
                title: "TestFile.java",
                content: "public class TestFile {}",
                language: "Java"
            )
            try assertEqual(doc.title, "TestFile.java")
            try assertEqual(doc.content, "public class TestFile {}")
            try assertEqual(doc.language, "Java")
            try assertEqual(doc.encoding, .utf8)
            try assertEqual(doc.lineEnding, .lf)
            try assertFalse(doc.isModified)
            try assertTrue(doc.bookmarks.isEmpty)
            try assertTrue(doc.marks.isEmpty)
            try assertEqual(doc.selectedRange, NSRange(location: 0, length: 0))
        }

        runTest("testIndependentUndoManagersPerDocument") {
            let doc1 = EditorDocument(title: "Doc1.txt", content: "hello")
            let doc2 = EditorDocument(title: "Doc2.txt", content: "world")

            try assertNotEqual(
                ObjectIdentifier(doc1.undoManager),
                ObjectIdentifier(doc2.undoManager),
                "Each document must have its own isolated UndoManager"
            )
        }

        runTest("testLanguageDetection") {
            try assertEqual(SyntaxEngine.detectLanguage(from: "App.java"), "Java")
            try assertEqual(SyntaxEngine.detectLanguage(from: "index.ts"), "TypeScript")
            try assertEqual(SyntaxEngine.detectLanguage(from: "Component.tsx"), "TypeScript")
            try assertEqual(SyntaxEngine.detectLanguage(from: "server.js"), "JavaScript")
            try assertEqual(SyntaxEngine.detectLanguage(from: "script.py"), "Python")
            try assertEqual(SyntaxEngine.detectLanguage(from: "ContentView.swift"), "Swift")
            try assertEqual(SyntaxEngine.detectLanguage(from: "main.c"), "C")
            try assertEqual(SyntaxEngine.detectLanguage(from: "engine.cpp"), "C++")
            try assertEqual(SyntaxEngine.detectLanguage(from: "Program.cs"), "C#")
            try assertEqual(SyntaxEngine.detectLanguage(from: "server.go"), "Go")
            try assertEqual(SyntaxEngine.detectLanguage(from: "lib.rs"), "Rust")
            try assertEqual(SyntaxEngine.detectLanguage(from: "index.html"), "HTML")
            try assertEqual(SyntaxEngine.detectLanguage(from: "styles.css"), "CSS")
            try assertEqual(SyntaxEngine.detectLanguage(from: "data.json"), "JSON")
            try assertEqual(SyntaxEngine.detectLanguage(from: "config.yaml"), "YAML")
            try assertEqual(SyntaxEngine.detectLanguage(from: "schema.sql"), "SQL")
            try assertEqual(SyntaxEngine.detectLanguage(from: "build.sh"), "Shell")
            try assertEqual(SyntaxEngine.detectLanguage(from: "README.md"), "Markdown")
            try assertEqual(SyntaxEngine.detectLanguage(from: "application.properties"), "Properties")
            try assertEqual(SyntaxEngine.detectLanguage(from: "output.log"), "Log")
            try assertEqual(SyntaxEngine.detectLanguage(from: "pom.xml"), "XML")
            try assertEqual(SyntaxEngine.detectLanguage(from: "build.gradle"), "Gradle")
            try assertEqual(SyntaxEngine.detectLanguage(from: "build.gradle.kts"), "Gradle")
            try assertEqual(SyntaxEngine.detectLanguage(from: "unknown.xyz"), "Plain Text")
        }

        runTest("testFontAdjustments") {
            let manager = AppStateManager()
            let initialSize = manager.fontSize

            manager.increaseFontSize()
            try assertEqual(manager.fontSize, initialSize + 1.0)

            manager.decreaseFontSize()
            try assertEqual(manager.fontSize, initialSize)

            manager.resetFontSize()
            try assertEqual(manager.fontSize, 13.5)

            try assertFalse(manager.availableFontFamilies.isEmpty)
            try assertTrue(manager.availableFontFamilies.contains("SF Mono") || manager.availableFontFamilies.contains("Menlo"))
        }

        runTest("testAuthoritativeFontResolver") {
            let sfMono = SyntaxEngine.resolveFont(family: "SF Mono", size: 14)
            try assertEqual(sfMono.pointSize, 14.0)

            let menloBold = SyntaxEngine.resolveFont(family: "Menlo", size: 16, bold: true)
            try assertEqual(menloBold.pointSize, 16.0)

            // Graceful fallback for non-existent font
            let fallback = SyntaxEngine.resolveFont(family: "NonExistentSpecialFontXYZ", size: 13)
            try assertEqual(fallback.pointSize, 13.0)
        }

        runTest("testAppearanceAndThemeModes") {
            let manager = AppStateManager()
            try assertEqual(AppAppearanceMode.allCases.count, 3)

            manager.appearanceMode = .light
            try assertFalse(manager.isDarkMode)

            manager.appearanceMode = .dark
            try assertTrue(manager.isDarkMode)

            manager.theme = "Monokai"
            try assertEqual(manager.theme, "Monokai")
        }

        runTest("testPersistentTextMarking") {
            let doc = EditorDocument(title: "Code.java", content: "int value = 42;")
            try assertTrue(doc.marks.isEmpty)

            // Mark "value" (location 4, length 5)
            let range1 = NSRange(location: 4, length: 5)
            doc.toggleMark(for: range1, colorName: "Yellow")
            try assertEqual(doc.marks.count, 1)
            try assertEqual(doc.marks[0].colorName, "Yellow")
            try assertEqual(doc.marks[0].range, range1)

            // Mark "42" (location 12, length 2) with Green
            let range2 = NSRange(location: 12, length: 2)
            doc.toggleMark(for: range2, colorName: "Green")
            try assertEqual(doc.marks.count, 2)

            // Toggle off range1 (overlapping)
            doc.toggleMark(for: range1)
            try assertEqual(doc.marks.count, 1)
            try assertEqual(doc.marks[0].range, range2)

            // Clear all marks
            doc.clearAllMarks()
            try assertTrue(doc.marks.isEmpty)

            // Verify document content was untouched
            try assertEqual(doc.content, "int value = 42;")
        }

        runTest("testLanguageModeSwitching") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_lang_\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let manager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            guard let doc = manager.activeDocument else {
                throw TestFailure(description: "Expected active document")
            }

            manager.setLanguageForActiveDocument("Java")
            try assertEqual(doc.language, "Java")
            manager.setLanguageForActiveDocument("Python")
            try assertEqual(doc.language, "Python")
            manager.setLanguageForActiveDocument("Plain Text")
            try assertEqual(doc.language, "Plain Text")
        }

        runTest("testLineEndingSequences") {
            try assertEqual(LineEndingFormat.lf.newlineSequence, "\n")
            try assertEqual(LineEndingFormat.crlf.newlineSequence, "\r\n")
            try assertEqual(LineEndingFormat.cr.newlineSequence, "\r")
        }

        runTest("testAppStateManagerDocumentLifecycle") {
            let manager = AppStateManager()
            try assertFalse(manager.documents.isEmpty)
            let initialCount = manager.documents.count

            // Create new document
            manager.createNewDocument()
            try assertEqual(manager.documents.count, initialCount + 1)
            try assertEqual(manager.activeDocumentId, manager.documents.last?.id)

            // Close created document
            if let lastId = manager.documents.last?.id {
                manager.closeDocument(id: lastId)
                try assertEqual(manager.documents.count, initialCount)
            }
        }

        runTest("testLineOperationsOnDocument") {
            let manager = AppStateManager()
            guard let doc = manager.activeDocument else {
                throw TestFailure(description: "Expected active document")
            }

            doc.content = "line1\nline2\nline3"
            doc.cursorLine = 2

            manager.duplicateCurrentLine()
            try assertEqual(doc.content, "line1\nline2\nline2\nline3")

            manager.deleteCurrentLine()
            try assertEqual(doc.content, "line1\nline2\nline3")

            manager.joinLines()
            try assertEqual(doc.content, "line1\nline2 line3")
        }

        runTest("testBookmarkNavigation") {
            let manager = AppStateManager()
            guard let doc = manager.activeDocument else {
                throw TestFailure(description: "Expected active document")
            }

            doc.bookmarks = [5, 12, 25]
            doc.cursorLine = 1

            manager.nextBookmark()
            try assertEqual(doc.cursorLine, 5)

            manager.nextBookmark()
            try assertEqual(doc.cursorLine, 12)

            manager.prevBookmark()
            try assertEqual(doc.cursorLine, 5)

            // Test toggleBookmark
            doc.toggleBookmark(8)
            try assertTrue(doc.bookmarks.contains(8))
            doc.toggleBookmark(8)
            try assertFalse(doc.bookmarks.contains(8))

            manager.clearBookmarks()
            try assertTrue(doc.bookmarks.isEmpty)
        }

        runTest("testCommentToggling") {
            let manager = AppStateManager()
            guard let doc = manager.activeDocument else {
                throw TestFailure(description: "Expected active document")
            }

            doc.language = "Java"
            doc.content = "System.out.println(\"Hello\");"
            doc.cursorLine = 1

            manager.toggleComment()
            try assertEqual(doc.content, "// System.out.println(\"Hello\");")

            manager.toggleComment()
            try assertEqual(doc.content, "System.out.println(\"Hello\");")
        }

        runTest("testSearchEngineLiteralMatches") {
            let text = "Notepad++ for Mac is fast. Fast editing for everyone."
            let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
            let res = SearchEngine.findAll(in: text, query: "fast", options: opts)

            try assertEqual(res.totalCount, 2)
            try assertEqual(res.matchingRanges.count, 2)
            try assertNil(res.errorMessage)
        }

        runTest("testSearchEngineCaseSensitivity") {
            let text = "Apple apple APPLE"
            let sensitive = SearchOptions(caseSensitive: true, wholeWord: false, isRegex: false)
            let insensitive = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)

            let resSensitive = SearchEngine.findAll(in: text, query: "apple", options: sensitive)
            try assertEqual(resSensitive.totalCount, 1)

            let resInsensitive = SearchEngine.findAll(in: text, query: "apple", options: insensitive)
            try assertEqual(resInsensitive.totalCount, 3)
        }

        runTest("testSearchEngineWholeWord") {
            let text = "cat catch scatter concatenate cat"
            let wholeWordOpts = SearchOptions(caseSensitive: false, wholeWord: true, isRegex: false)
            let res = SearchEngine.findAll(in: text, query: "cat", options: wholeWordOpts)

            try assertEqual(res.totalCount, 2)
        }

        runTest("testSearchEngineRegex") {
            let text = "Item 01, Item 42, Item 999"
            let regexOpts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: true)
            let res = SearchEngine.findAll(in: text, query: "Item \\d{2}\\b", options: regexOpts)

            try assertEqual(res.totalCount, 2)

            let invalid = SearchEngine.findAll(in: text, query: "[unclosed", options: regexOpts)
            try assertNotNil(invalid.errorMessage)
            try assertEqual(invalid.totalCount, 0)
        }

        runTest("testSearchEngineUnicodeAndAccents") {
            let text = "Café au lait, café latte, crème brûlée"
            let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
            let res = SearchEngine.findAll(in: text, query: "café", options: opts)

            try assertEqual(res.totalCount, 2)
        }

        runTest("testSearchEngineNextAndPreviousNavigation") {
            let text = "one two one two one"
            let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
            let res = SearchEngine.findAll(in: text, query: "one", options: opts)
            try assertEqual(res.matchingRanges.count, 3)

            let r0 = res.matchingRanges[0]
            let r1 = res.matchingRanges[1]
            let r2 = res.matchingRanges[2]

            let nextFrom0 = SearchEngine.nextIndex(from: r0, in: res.matchingRanges, wrap: true)
            try assertEqual(nextFrom0, 1)

            let nextFrom2 = SearchEngine.nextIndex(from: r2, in: res.matchingRanges, wrap: true)
            try assertEqual(nextFrom2, 0)

            let prevFrom1 = SearchEngine.previousIndex(from: r1, in: res.matchingRanges, wrap: true)
            try assertEqual(prevFrom1, 0)

            let prevFrom0 = SearchEngine.previousIndex(from: r0, in: res.matchingRanges, wrap: true)
            try assertEqual(prevFrom0, 2)
        }

        runTest("testSearchEngineReplaceSingle") {
            let text = "Hello World, Welcome World"
            let target = NSRange(location: 6, length: 5)
            let res = SearchEngine.replace(in: text, targetRange: target, with: "Universe")

            try assertNotNil(res)
            try assertEqual(res?.newText, "Hello Universe, Welcome World")
            try assertEqual(res?.newRange, NSRange(location: 6, length: 8))
        }

        runTest("testSearchEngineReplaceAll") {
            let text = "foo bar foo baz foo"
            let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
            let res = SearchEngine.replaceAll(in: text, query: "foo", replacement: "qux", options: opts)

            try assertEqual(res.count, 3)
            try assertEqual(res.newText, "qux bar qux baz qux")
        }

        runTest("testTerminalWorkingDirectoryPersistenceAndCd") {
            let manager = AppStateManager()
            try assertFalse(manager.terminalWorkingDirectory.isEmpty)

            // Test changing to /tmp
            let successTmp = manager.changeTerminalDirectory(to: "/tmp")
            try assertTrue(successTmp)
            try assertTrue(manager.terminalWorkingDirectory.contains("tmp"))

            // Test changing to non-existent directory fails and preserves cwd
            let savedCwd = manager.terminalWorkingDirectory
            let fail = manager.changeTerminalDirectory(to: "/invalid_dir_never_exists_12345")
            try assertFalse(fail)
            try assertEqual(manager.terminalWorkingDirectory, savedCwd)

            // Test home expansion
            let successHome = manager.changeTerminalDirectory(to: "~")
            try assertTrue(successHome)
            try assertEqual(manager.terminalWorkingDirectory, NSHomeDirectory())
        }

        runTest("testTerminalCancellation") {
            let manager = AppStateManager()
            manager.isTerminalRunning = true
            manager.cancelTerminalCommand()
            try assertFalse(manager.isTerminalRunning)
            try assertTrue(manager.terminalOutput.contains("[Command cancelled]"))
        }

        // ==============================================================================
        // 8. Session Persistence, Recovery, Undo/Redo, Open Terminal Here & Run File
        // ==============================================================================

        runTest("testScenarioA_UnsavedNewDocumentRecoveryAcrossRestart") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_A_\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let manager1 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            try assertEqual(manager1.documents.count, 1)
            let doc = manager1.documents[0]
            try assertFalse(doc.hasEverBeenSaved)
            doc.applyEdit("Unsaved critical work in new tab\nLine 2")
            try assertTrue(doc.isModified)
            manager1.saveSessionToDisk()

            // Simulate app restart with same storage directory
            let manager2 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: true)
            try assertEqual(manager2.documents.count, 1)
            try assertEqual(manager2.documents[0].id, doc.id)
            try assertEqual(manager2.documents[0].content, "Unsaved critical work in new tab\nLine 2")
            try assertTrue(manager2.documents[0].isModified)
            try assertFalse(manager2.documents[0].hasEverBeenSaved)
        }

        runTest("testScenarioB_UnsavedChangesToExistingDiskFilePreservesOriginal") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_B_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let diskFile = tempDir.appendingPathComponent("Main.java")
            let originalCode = "public class Main {\n    // original\n}\n"
            try originalCode.write(to: diskFile, atomically: true, encoding: .utf8)

            let manager1 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc = EditorDocument(
                title: "Main.java",
                fileURL: diskFile,
                content: originalCode,
                savedContent: originalCode,
                language: "Java",
                hasEverBeenSaved: true,
                isModified: false
            )
            manager1.documents = [doc]
            manager1.selectedDocumentID = doc.id

            // Modify without saving to diskFile
            doc.applyEdit("public class Main {\n    // unsaved modification\n}\n")
            try assertTrue(doc.isModified)
            manager1.saveSessionToDisk()

            // Verify original disk file was NOT overwritten
            let onDiskNow = try String(contentsOf: diskFile, encoding: .utf8)
            try assertEqual(onDiskNow, originalCode)

            // Restart and verify unsaved edits are recovered while file association is preserved
            let manager2 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: true)
            try assertEqual(manager2.documents.count, 1)
            let restored = manager2.documents[0]
            try assertEqual(restored.fileURL?.path, diskFile.path)
            try assertEqual(restored.content, "public class Main {\n    // unsaved modification\n}\n")
            try assertEqual(restored.savedContent, originalCode)
            try assertTrue(restored.isModified)
        }

        runTest("testScenarioC_MultipleTabsAndActiveTabRestoration") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_C_\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let manager1 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let tab1 = EditorDocument(title: "new 1", content: "Draft 1", savedContent: "", language: "Plain Text", hasEverBeenSaved: false, isModified: true)
            let tab2 = EditorDocument(title: "app.py", content: "print(1)", savedContent: "print(1)", language: "Python", hasEverBeenSaved: true, isModified: false)
            let tab3 = EditorDocument(title: "notes.md", content: "# Hi", savedContent: "#", language: "Markdown", hasEverBeenSaved: true, isModified: true)
            manager1.documents = [tab1, tab2, tab3]
            manager1.selectedDocumentID = tab2.id
            manager1.saveSessionToDisk()

            let manager2 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: true)
            try assertEqual(manager2.documents.map { $0.id }, [tab1.id, tab2.id, tab3.id])
            try assertEqual(manager2.selectedDocumentID, tab2.id)
        }

        runTest("testScenarioD_SafeClosingOfModifiedTab") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_D_\(UUID().uuidString)", isDirectory: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let manager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc = manager.documents[0]
            doc.applyEdit("Important unsaved content")
            try assertTrue(doc.isModified)

            // 1. Cancel keeps tab open
            let cancelClosed = manager.closeDocument(id: doc.id, decisionHandler: { _ in .cancel })
            try assertFalse(cancelClosed)
            try assertEqual(manager.documents[0].content, "Important unsaved content")

            // 2. Don't Save discards and replaces last tab with clean untitled
            let dontSaveClosed = manager.closeDocument(id: doc.id, decisionHandler: { _ in .dontSave })
            try assertTrue(dontSaveClosed)
            try assertFalse(manager.documents[0].isModified)
        }

        runTest("testScenarioE_DeletedDiskFileRecovery") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_E_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let diskFile = tempDir.appendingPathComponent("Deleted.swift")
            try "let x = 1".write(to: diskFile, atomically: true, encoding: .utf8)

            let manager1 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc = EditorDocument(
                title: "Deleted.swift",
                fileURL: diskFile,
                content: "let x = 2",
                savedContent: "let x = 1",
                language: "Swift",
                hasEverBeenSaved: true,
                isModified: true
            )
            manager1.documents = [doc]
            manager1.selectedDocumentID = doc.id
            manager1.saveSessionToDisk()

            // Remove original file from disk before restart
            try FileManager.default.removeItem(at: diskFile)

            let manager2 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: true)
            try assertEqual(manager2.documents.count, 1)
            let restored = manager2.documents[0]
            try assertTrue(restored.isOriginalFileMissing)
            try assertTrue(restored.isModified)
            try assertEqual(restored.content, "let x = 2")
        }

        runTest("testPerDocumentUndoAndRedoAcrossTabs") {
            let docA = EditorDocument(title: "A.txt", content: "Base", savedContent: "Base", language: "Plain Text", hasEverBeenSaved: true, isModified: false)
            let docB = EditorDocument(title: "B.txt", content: "Other", savedContent: "Other", language: "Plain Text", hasEverBeenSaved: true, isModified: false)

            docA.applyEdit("Base 1")
            docA.applyEdit("Base 2")
            docB.applyEdit("Other 1")

            try assertTrue(docA.canUndo)
            try assertTrue(docA.undo())
            try assertEqual(docA.content, "Base 1")
            try assertTrue(docA.isModified)

            try assertTrue(docA.undo())
            try assertEqual(docA.content, "Base")
            try assertFalse(docA.isModified)

            try assertTrue(docA.redo())
            try assertEqual(docA.content, "Base 1")
            try assertTrue(docA.isModified)

            // Doc B remains isolated
            try assertEqual(docB.content, "Other 1")
            try assertTrue(docB.undo())
            try assertEqual(docB.content, "Other")
            try assertFalse(docB.isModified)
        }

        runTest("testOpenTerminalHereAndRunPlans") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_run_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let manager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let javaFile = tempDir.appendingPathComponent("Hello.java")
            let javaCode = "package demo;\npublic class Hello {\n  public static void main(String[] args) {}\n}"
            let javaDoc = EditorDocument(title: "Hello.java", fileURL: javaFile, content: javaCode, savedContent: javaCode, language: "Java", hasEverBeenSaved: true, isModified: false)

            manager.openTerminalHere(for: javaDoc)
            try assertTrue(manager.showTerminal)
            try assertEqual(manager.terminalWorkingDirectory, tempDir.path)

            let plan = manager.buildRunPlan(for: javaDoc)
            try assertTrue(plan.supported)
            try assertTrue(plan.command.contains("javac"))
            try assertTrue(plan.command.contains("demo.Hello"))
        }

        runTest("testEditorInputAndModificationCrossCheck") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_crosscheck_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let manager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            guard let doc = manager.activeDocument else {
                throw TestFailure(description: "Expected active document")
            }

            // 1. Initial State
            let initialContent = doc.content
            try assertFalse(doc.isModified)

            // 2. Perform text edit (typing simulation)
            let editedText = "public class EditedCode {\n    // Added text here\n}\n"
            doc.applyEdit(editedText, newSelectedRange: NSRange(location: editedText.count, length: 0), actionName: "Typing")

            // 3. Cross-check content updated and isModified is true
            try assertEqual(doc.content, editedText)
            try assertTrue(doc.isModified)
            try assertTrue(doc.canUndo)

            // 4. Cross-check Undo restores original text
            doc.undo()
            try assertEqual(doc.content, initialContent)
            try assertTrue(doc.canRedo)

            // 5. Cross-check Redo re-applies the edit
            doc.redo()
            try assertEqual(doc.content, editedText)
            try assertTrue(doc.isModified)

            // 6. Cross-check file save writes exact bytes to disk
            let saveTarget = tempDir.appendingPathComponent("EditedCode.java")
            doc.fileURL = saveTarget
            try manager.saveDocument(doc, to: saveTarget)
            try assertFalse(doc.isModified)
            let onDiskText = try String(contentsOf: saveTarget, encoding: .utf8)
            try assertEqual(onDiskText, editedText)
        }

        runTest("testUndoRedoPublishedStateTransitions") {
            let doc = EditorDocument(title: "UndoTest.txt", content: "Initial Line\n")
            try assertFalse(doc.canUndo)
            try assertFalse(doc.canRedo)

            doc.applyEdit("Initial Line\nSecond Line\n", newSelectedRange: NSRange(location: 25, length: 0), actionName: "Typing")
            try assertTrue(doc.canUndo)
            try assertFalse(doc.canRedo)
            try assertTrue(doc.isModified)

            doc.undo()
            try assertFalse(doc.canUndo)
            try assertTrue(doc.canRedo)
            try assertFalse(doc.isModified)
            try assertEqual(doc.content, "Initial Line\n")

            doc.redo()
            try assertTrue(doc.canUndo)
            try assertFalse(doc.canRedo)
            try assertTrue(doc.isModified)
            try assertEqual(doc.content, "Initial Line\nSecond Line\n")
        }

        runTest("testLongLineAndPromptFileHandling") {
            // Emulate Prompt.txt: a single line with tens of thousands of characters
            let longText = String(repeating: "CodePad macOS Editor ", count: 3000) // ~63,000 chars
            let doc = EditorDocument(title: "Prompt.txt", content: longText, language: "Plain Text")
            try assertEqual(doc.content.count, longText.count)
            try assertFalse(doc.isModified)

            // Insert text at beginning
            let prefix = "HEADER: "
            let edited = prefix + longText
            doc.applyEdit(edited, newSelectedRange: NSRange(location: prefix.count, length: 0), actionName: "Insert Prefix")
            try assertTrue(doc.isModified)
            try assertTrue(doc.canUndo)
            try assertEqual(doc.content.count, edited.count)

            // Undo insertion
            doc.undo()
            try assertFalse(doc.isModified)
            try assertEqual(doc.content.count, longText.count)
            try assertTrue(doc.canRedo)

            // Redo insertion
            doc.redo()
            try assertTrue(doc.isModified)
            try assertEqual(doc.content.count, edited.count)
        }

        runTest("testFirstLaunchWelcomeExperienceLifecycle") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_welcome_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // 1. First launch for a fresh user: hasCompletedWelcome is false
            UserDefaults.standard.removeObject(forKey: AppStateManager.kHasCompletedWelcome)
            let freshManager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            try assertFalse(freshManager.hasCompletedWelcome)
            try assertTrue(freshManager.showWelcomeSheet)
            try assertFalse(freshManager.welcomeExploreFeaturesActive)

            // 2. Explore features toggle
            freshManager.welcomeExploreFeaturesActive = true
            try assertTrue(freshManager.welcomeExploreFeaturesActive)
            freshManager.welcomeExploreFeaturesActive = false
            try assertFalse(freshManager.welcomeExploreFeaturesActive)

            // 3. Complete welcome
            freshManager.markWelcomeCompleted()
            try assertTrue(freshManager.hasCompletedWelcome)
            try assertFalse(freshManager.showWelcomeSheet)
            try assertFalse(freshManager.welcomeExploreFeaturesActive)

            // 4. Subsequent launch does NOT display welcome automatically
            let subsequentManager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            try assertTrue(subsequentManager.hasCompletedWelcome)
            try assertFalse(subsequentManager.showWelcomeSheet)

            // 5. Help -> Welcome to NPad++ re-opens welcome on demand
            subsequentManager.showWelcomeSheet = true
            try assertTrue(subsequentManager.showWelcomeSheet)
            subsequentManager.markWelcomeCompleted()
            try assertFalse(subsequentManager.showWelcomeSheet)
        }

        runTest("testWelcomeExperienceSessionRestorationPrecedence") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_session_precedence_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // Create a session file simulating an existing workspace with user documents
            let manager1 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            manager1.createNewDocument()
            manager1.activeDocument?.applyEdit("Session Work", actionName: "Typing")
            manager1.saveSessionToDisk()

            // Fresh launch flag reset to test precedence
            UserDefaults.standard.removeObject(forKey: AppStateManager.kHasCompletedWelcome)

            // When restoring an existing user session, existing documents take priority over the welcome sheet
            let manager2 = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: true)
            try assertFalse(manager2.showWelcomeSheet)
            try assertEqual(manager2.documents.count, 2)
        }

        runTest("testWelcomeActionNewFileAndFolderIntegration") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_welcome_actions_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            UserDefaults.standard.removeObject(forKey: AppStateManager.kHasCompletedWelcome)
            let manager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            try assertTrue(manager.showWelcomeSheet)

            // Action: New File creates an editable document, marks welcome completed, and focuses editor
            manager.markWelcomeCompleted()
            manager.createNewDocument()
            try assertFalse(manager.showWelcomeSheet)
            try assertTrue(manager.hasCompletedWelcome)

            guard let activeDoc = manager.activeDocument else {
                throw TestFailure(description: "Expected active document after New File from Welcome")
            }
            try assertFalse(activeDoc.isModified)
            activeDoc.applyEdit("User Code Added", actionName: "Typing")
            try assertTrue(activeDoc.isModified)
            try assertTrue(activeDoc.canUndo)
            activeDoc.undo()
            try assertFalse(activeDoc.isModified)
            try assertTrue(activeDoc.canRedo)
        }

        runTest("testMacEditorViewNativeTypingAndEventRouting") {
            let appState = AppStateManager(restorePreviousSession: false)
            let doc = EditorDocument(title: "TypingTest.txt", content: "Initial Line\n", language: "Plain Text")
            appState.documents = [doc]
            appState.activeDocumentId = doc.id

            let editorView = MacEditorView(document: doc, appState: appState)
            let hostView = NSHostingView(rootView: editorView)
            hostView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostView
            window.makeKeyAndOrderFront(nil)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

            // Find CodePadTextView recursively
            func findTextView(in view: NSView) -> CodePadTextView? {
                if let tv = view as? CodePadTextView { return tv }
                for sub in view.subviews {
                    if let found = findTextView(in: sub) { return found }
                }
                return nil
            }

            guard let textView = findTextView(in: hostView) else {
                throw TestFailure(description: "Could not locate CodePadTextView in hosted hierarchy")
            }

            // Test first responder
            let becameFirst = window.makeFirstResponder(textView)
            print("    [Diagnostic] makeFirstResponder returned: \(becameFirst), win.firstResponder=\(String(describing: window.firstResponder))")
            try assertTrue(becameFirst, "CodePadTextView must accept first responder")
            try assertTrue(window.firstResponder === textView, "Window first responder must be CodePadTextView")
            try assertTrue(textView.isEditable, "TextView must be editable")
            try assertTrue(textView.isSelectable, "TextView must be selectable")

            // Simulate typing into the NSTextView
            textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))
            textView.insertText("Appended text by user typing", replacementRange: textView.selectedRange())

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

            print("    [Diagnostic] textView.string after insertText: '\(textView.string)'")
            print("    [Diagnostic] doc.content after insertText: '\(doc.content)'")

            try assertEqual(textView.string, "Initial Line\nAppended text by user typing")
            try assertEqual(doc.content, "Initial Line\nAppended text by user typing")
            try assertTrue(doc.isModified, "Document must be modified after typing")
            try assertTrue(doc.canUndo, "Undo must be available after typing")

            // Test undo
            doc.undo()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            print("    [Diagnostic] doc.content after undo: '\(doc.content)'")
            print("    [Diagnostic] textView.string after undo: '\(textView.string)'")
            try assertEqual(doc.content, "Initial Line\n")
        }

        runTest("testOpenedFileEditingTypingAndDiskSaving") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_opened_file_edit_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let sampleFile = tempDir.appendingPathComponent("Prompt.txt")
            let initialText = "This is an existing opened document with long content that needs to be editable."
            try initialText.write(to: sampleFile, atomically: true, encoding: .utf8)

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc = try appState.openFileFromURL(sampleFile)
            try assertFalse(doc.isModified)

            let editorView = MacEditorView(document: doc, appState: appState)
            let hostView = NSHostingView(rootView: editorView)
            hostView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostView
            window.makeKeyAndOrderFront(nil)
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

            func findTextView(in view: NSView) -> CodePadTextView? {
                if let tv = view as? CodePadTextView { return tv }
                for sub in view.subviews {
                    if let found = findTextView(in: sub) { return found }
                }
                return nil
            }

            guard let textView = findTextView(in: hostView) else {
                throw TestFailure(description: "Could not find CodePadTextView in hosted hierarchy")
            }

            // Verify editable properties
            try assertTrue(textView.isEditable)
            try assertTrue(textView.isSelectable)
            let becameFirst = window.makeFirstResponder(textView)
            try assertTrue(becameFirst)

            // Select word 'existing' and replace it with 'modified'
            let nsStr = textView.string as NSString
            let targetRange = nsStr.range(of: "existing")
            try assertTrue(targetRange.location != NSNotFound)
            textView.setSelectedRange(targetRange)
            textView.insertText("modified", replacementRange: targetRange)

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

            try assertTrue(doc.isModified)
            try assertTrue(textView.string.contains("modified opened document"))
            try assertEqual(doc.content, textView.string)

            // Save document to disk
            appState.saveActiveDocument()
            try assertFalse(doc.isModified)

            // Read disk contents to verify persistence
            let diskText = try String(contentsOf: sampleFile, encoding: .utf8)
            try assertEqual(diskText, textView.string)
        }

        runTest("testHtmlExecutionOpensBrowserPlan") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_html_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let htmlDoc = EditorDocument(
                title: "test.html",
                content: "<html><body><pre>Hello Vijay</pre></body></html>",
                language: "HTML"
            )
            appState.documents = [htmlDoc]
            appState.activeDocumentId = htmlDoc.id

            let plan = appState.buildRunPlan(for: htmlDoc)
            try assertTrue(plan.supported, "HTML files must be supported for execution")
            try assertEqual(plan.language, "HTML")
            try assertTrue(plan.command.hasPrefix("open "), "HTML execution command must open via macOS open")
            try assertTrue(plan.stagedFileURL != nil)
            guard let staged = plan.stagedFileURL else { throw TestFailure(description: "Missing staged HTML URL") }
            try assertTrue(FileManager.default.fileExists(atPath: staged.path))
            let stagedText = try String(contentsOf: staged, encoding: .utf8)
            try assertEqual(stagedText, htmlDoc.content)
        }

        runTest("testNewFileSaveUpdatesSidebarTitleAndModel") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_sidebar_title_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            appState.createNewDocument()
            guard let newDoc = appState.activeDocument else {
                throw TestFailure(description: "Active document not found")
            }
            let initialTitle = newDoc.title
            try assertTrue(initialTitle.hasPrefix("new "), "Initial title must start with 'new '")

            // Simulate user adding content and saving to a real named file (e.g. jjis.txt)
            newDoc.applyEdit("hyudud\n", actionName: "Typing")
            try assertTrue(newDoc.isModified)

            let saveTarget = tempDir.appendingPathComponent("jjis.txt")
            var appStateNotified = false
            let cancellable = appState.objectWillChange.sink { _ in
                appStateNotified = true
            }
            _ = cancellable

            try appState.saveDocument(newDoc, to: saveTarget)

            // Assert document title, URL, language, and modified state are updated
            try assertEqual(newDoc.title, "jjis.txt", "Document title must update to saved filename")
            try assertEqual(newDoc.fileURL?.path, saveTarget.path)
            try assertFalse(newDoc.isModified)
            try assertTrue(appStateNotified, "AppStateManager must publish objectWillChange when saving document")

            // Verify sidebar row view model reflects the new title
            let rowView = DocumentSidebarRow(doc: newDoc, appState: appState)
            try assertEqual(rowView.doc.title, "jjis.txt")
        }

        runTest("testBase64EncodeAndDecodeFeature") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_b64_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let originalContent = "Hello, Apple Silicon Developer!"
            let doc = EditorDocument(title: "b64.txt", content: originalContent, language: "Plain Text")
            appState.documents = [doc]
            appState.activeDocumentId = doc.id

            // 1. Full document Base64 Encode
            appState.base64EncodeSelectionOrDocument()
            let expectedEncoded = Data(originalContent.utf8).base64EncodedString()
            try assertEqual(doc.content, expectedEncoded, "Content must match standard Base64 encoding")
            try assertTrue(doc.isModified)
            try assertTrue(doc.canUndo)

            // 2. Full document Base64 Decode
            appState.base64DecodeSelectionOrDocument()
            try assertEqual(doc.content, originalContent, "Decoded content must restore original text")

            // 3. Selection Base64 Encode & Decode
            doc.content = "Prefix [TEST_DATA] Suffix"
            let nsStr = doc.content as NSString
            let targetRange = nsStr.range(of: "[TEST_DATA]")
            doc.selectedRange = targetRange

            appState.base64EncodeSelectionOrDocument()
            let encodedPiece = Data("[TEST_DATA]".utf8).base64EncodedString()
            try assertTrue(doc.content.contains(encodedPiece))

            // Select the encoded piece and decode back
            let currentStr = doc.content as NSString
            let encodedRange = currentStr.range(of: encodedPiece)
            doc.selectedRange = encodedRange

            appState.base64DecodeSelectionOrDocument()
            try assertEqual(doc.content, "Prefix [TEST_DATA] Suffix")
        }

        runTest("testNotepadPlusExtendedSearchModeEscapes") {
            let sample = "Line 1\nLine 2\tTabbed\r\nLine 3"
            let options = SearchOptions(searchMode: .extended)
            let resultNL = SearchEngine.findAll(in: sample, query: "\\n", options: options)
            try assertTrue(resultNL.totalCount >= 2, "Extended mode must find literal newlines from \\n escape")

            let resultTab = SearchEngine.findAll(in: sample, query: "\\t", options: options)
            try assertEqual(resultTab.totalCount, 1, "Extended mode must find tab from \\t escape")

            let (replaced, count, err) = SearchEngine.replaceAll(in: sample, query: "\\t", replacement: "----", options: options)
            try assertEqual(err, nil)
            try assertEqual(count, 1)
            try assertTrue(replaced.contains("Line 2----Tabbed"))
        }

        runTest("testNotepadPlusFindInAllDocumentsAndCount") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_find_all_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc1 = EditorDocument(title: "Doc1.txt", content: "TargetKeyword in doc 1\nAnother line", language: "Plain Text")
            let doc2 = EditorDocument(title: "Doc2.txt", content: "Doc 2 with TargetKeyword\nAnd TargetKeyword again", language: "Plain Text")
            appState.documents = [doc1, doc2]
            appState.activeDocumentId = doc1.id

            appState.searchQuery = "TargetKeyword"
            appState.countMatches()
            try assertEqual(appState.searchStatusMessage, "Count: 1 matches.")

            appState.findInAllDocuments()
            try assertEqual(appState.searchResultsList.count, 3, "Find in all documents must aggregate matches across all open tabs")
            try assertTrue(appState.isBottomPanelVisible)
            try assertEqual(appState.activeBottomTab, "Search Results")
        }

        runTest("testNotepadPlusReplaceInAllDocuments") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_replace_all_docs_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc1 = EditorDocument(title: "Alpha.txt", content: "OLD_VAL here", language: "Plain Text")
            let doc2 = EditorDocument(title: "Beta.txt", content: "OLD_VAL and OLD_VAL", language: "Plain Text")
            appState.documents = [doc1, doc2]
            appState.activeDocumentId = doc1.id

            appState.searchQuery = "OLD_VAL"
            appState.replaceQuery = "NEW_VAL"
            appState.replaceInAllDocuments()

            try assertEqual(doc1.content, "NEW_VAL here")
            try assertEqual(doc2.content, "NEW_VAL and NEW_VAL")
            try assertTrue(doc1.isModified)
            try assertTrue(doc2.isModified)
            try assertTrue(appState.searchStatusMessage.contains("3 occurrences"))
        }

        runTest("testNotepadPlusFindInFilesWithFilters") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_find_files_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let subDir = tempDir.appendingPathComponent("sub", isDirectory: true)
            try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

            let file1 = tempDir.appendingPathComponent("A.swift")
            let file2 = subDir.appendingPathComponent("B.swift")
            let file3 = tempDir.appendingPathComponent("C.log")

            try "let greeting = \"UniqueFinderTest\"".write(to: file1, atomically: true, encoding: .utf8)
            try "// UniqueFinderTest in subfolder".write(to: file2, atomically: true, encoding: .utf8)
            try "UniqueFinderTest in log".write(to: file3, atomically: true, encoding: .utf8)

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            appState.searchDirectory = tempDir.path
            appState.searchFilters = "*.swift"
            appState.searchInSubfolders = true
            appState.searchQuery = "UniqueFinderTest"

            appState.findInFiles()
            try assertEqual(appState.searchResultsList.count, 2, "Only *.swift files should match the filter")
            try assertTrue(appState.searchResultsList.contains(where: { $0.fileTitle == "A.swift" }))
            try assertTrue(appState.searchResultsList.contains(where: { $0.fileTitle == "B.swift" }))
        }

        runTest("testNotepadPlusMarkTabBookmarkingAndCopy") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_mark_\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc = EditorDocument(
                title: "MarkTest.txt",
                content: "First line\nMarkTarget line 2\nThird line\nMarkTarget line 4",
                language: "Plain Text"
            )
            appState.documents = [doc]
            appState.activeDocumentId = doc.id

            appState.searchQuery = "MarkTarget"
            appState.markBookmarkLine = true
            appState.markPurgeForSearch = true
            appState.markAll()

            try assertEqual(doc.marks.count, 2, "Document must have 2 persistent marks")
            try assertTrue(doc.bookmarks.contains(2), "Line 2 must be bookmarked")
            try assertTrue(doc.bookmarks.contains(4), "Line 4 must be bookmarked")

            appState.copyMarkedText()
            let copied = NSPasteboard.general.string(forType: .string) ?? ""
            try assertTrue(copied.contains("MarkTarget"))

            appState.clearAllMarksInActiveDocument()
            try assertEqual(doc.marks.count, 0)
        }

        runTest("testNotepadPlusWordWrapToggle") {
            let appState = AppStateManager(restorePreviousSession: false)
            try assertFalse(appState.wordWrap)
            appState.wordWrap.toggle()
            try assertTrue(appState.wordWrap)
            appState.wordWrap.toggle()
            try assertFalse(appState.wordWrap)
        }

        runTest("testNotepadPlusFindDialogTabsAndTransparency") {
            let appState = AppStateManager(restorePreviousSession: false)
            try assertEqual(appState.findDialogTab, .find)

            appState.openFindDialog(tab: .replace)
            try assertEqual(appState.findDialogTab, .replace)
            try assertTrue(appState.showFindWindow)

            appState.transparencyEnabled = true
            appState.transparencyMode = .always
            appState.transparencyOpacity = 0.75
            NotepadPlusFindWindowController.shared.updateTitleAndOpacity()

            guard let panel = NotepadPlusFindWindowController.shared.window else {
                throw TestFailure(description: "NotepadPlusFindWindowController window was not instantiated")
            }
            try assertEqual(panel.title, "Replace")
            try assertEqual(Double(panel.alphaValue), 0.75)

            appState.closeFindDialog()
            try assertFalse(appState.showFindWindow)
        }

        runTest("testTrailingNewlineLineNumberRulerCalculation") {
            let doc = EditorDocument(title: "new 1", content: "\n")
            // When document is "\n", cursor is on line 2
            let lines = doc.content.components(separatedBy: "\n")
            try assertEqual(lines.count, 2)
            doc.cursorLine = 2
            try assertEqual(doc.cursorLine, 2)

            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
            let textStorage = NSTextStorage(string: doc.content)
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            let textContainer = NSTextContainer(containerSize: NSSize(width: 800, height: CGFloat.greatestFiniteMagnitude))
            layoutManager.addTextContainer(textContainer)
            let textView = CodePadTextView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), textContainer: textContainer)
            textView.document = doc

            let ruler = LineNumberRulerView(scrollView: scrollView, textView: textView, document: doc)
            ruler.needsDisplay = true

            // Verify trailing newline creates extra line fragment
            layoutManager.ensureLayout(for: textContainer)
            try assertTrue(layoutManager.extraLineFragmentTextContainer != nil)
            try assertTrue(layoutManager.extraLineFragmentRect.height > 0)
        }

        runTest("testRedoCommandYShortcut") {
            let appState = AppStateManager(restorePreviousSession: false)
            guard let doc = appState.activeDocument else {
                throw TestFailure(description: "No active document in appState")
            }
            doc.content = "Original"

            // Perform an edit
            doc.applyEdit("Modified with Command+Y test", actionName: "Typing")
            try assertEqual(doc.content, "Modified with Command+Y test")
            try assertTrue(doc.canUndo)

            // Undo
            doc.undo()
            try assertEqual(doc.content, "Original")
            try assertTrue(doc.canRedo)

            // Setup CodePadTextView and perform ⌘Y via performKeyEquivalent
            let textView = CodePadTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 500), textContainer: nil)
            textView.appState = appState
            textView.document = doc

            let event = NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: .command,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                characters: "y",
                charactersIgnoringModifiers: "y",
                isARepeat: false,
                keyCode: 16
            )!
            let handled = textView.performKeyEquivalent(with: event)
            try assertTrue(handled)
            try assertEqual(doc.content, "Modified with Command+Y test")
        }

        runTest("testLanguageAlphabeticalCatalogAndDetection") {
            // 1. Verify A-Z dictionary structure
            try assertTrue(SyntaxEngine.alphabeticalGroups.count >= 20)
            for group in SyntaxEngine.alphabeticalGroups {
                let sorted = group.languages.sorted()
                try assertEqual(group.languages, sorted)
            }

            // 2. Verify extended languages detection
            try assertEqual(SyntaxEngine.detectLanguage(from: "app.dart"), "Dart")
            try assertEqual(SyntaxEngine.detectLanguage(from: "test.rb"), "Ruby")
            try assertEqual(SyntaxEngine.detectLanguage(from: "index.php"), "PHP")
            try assertEqual(SyntaxEngine.detectLanguage(from: "script.lua"), "Lua")
            try assertEqual(SyntaxEngine.detectLanguage(from: "main.zig"), "Zig")
            try assertEqual(SyntaxEngine.detectLanguage(from: "Cargo.toml"), "TOML")
            try assertEqual(SyntaxEngine.detectLanguage(from: "build.bat"), "Batch")
            try assertEqual(SyntaxEngine.detectLanguage(from: "data.r"), "R")
            try assertEqual(SyntaxEngine.detectLanguage(from: "CMakeLists.txt"), "CMake")
            try assertEqual(SyntaxEngine.detectLanguage(from: "model.scala"), "Scala")
            try assertEqual(SyntaxEngine.detectLanguage(from: "schema.graphql"), "GraphQL")

            // 3. Verify language switching in AppStateManager
            let appState = AppStateManager(restorePreviousSession: false)
            guard let doc = appState.activeDocument else {
                throw TestFailure(description: "No active document in appState")
            }
            appState.setLanguageForActiveDocument("Ruby")
            try assertEqual(doc.language, "Ruby")
        }

        runTest("testWordWrapConfigurationAndVisibility") {
            let appState = AppStateManager(restorePreviousSession: false)
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
            let textStorage = NSTextStorage(string: "A very long line that should wrap nicely without losing horizontal offset or hiding data.")
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)
            let textContainer = NSTextContainer(containerSize: NSSize(width: 800, height: CGFloat.greatestFiniteMagnitude))
            layoutManager.addTextContainer(textContainer)
            let textView = CodePadTextView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), textContainer: textContainer)
            scrollView.documentView = textView

            appState.wordWrap = true
            try assertTrue(appState.wordWrap)

            // Simulate wrap configuration
            textContainer.containerSize = NSSize(width: 800, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true
            textView.isHorizontallyResizable = false
            scrollView.contentView.scroll(to: .zero)

            try assertEqual(scrollView.contentView.bounds.origin.x, 0)
            try assertTrue(textContainer.widthTracksTextView)
            try assertFalse(textView.isHorizontallyResizable)
        }

        runTest("testPrintDocumentSupport") {
            let appState = AppStateManager(restorePreviousSession: false)
            guard let doc = appState.activeDocument else {
                throw TestFailure(description: "No active document in appState")
            }
            doc.content = "Printing test content"

            let textView = CodePadTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 500), textContainer: nil)
            textView.appState = appState
            textView.document = doc

            // Check context menu has Print...
            let menu = textView.menu(for: NSEvent())
            guard let m = menu else {
                throw TestFailure(description: "Context menu was nil")
            }
            let hasPrint = m.items.contains { $0.title == "Print..." }
            try assertTrue(hasPrint)
        }

        // ==============================================================================
        // Split View & File Comparison Tests
        // ==============================================================================

        runTest("testMyersDiffIdenticalFiles") {
            let left = "function test() {\n    return 42;\n}\n"
            let right = "function test() {\n    return 42;\n}\n"
            let result = FileComparisonService.compare(leftText: left, rightText: right)
            try assertTrue(result.isIdentical)
            try assertEqual(result.totalDifferences, 0)
            try assertEqual(result.chunks.count, 0)
            try assertEqual(result.addedCount, 0)
            try assertEqual(result.deletedCount, 0)
            try assertEqual(result.modifiedCount, 0)
        }

        runTest("testMyersDiffEmptyFiles") {
            // Both empty
            let resultEmpty = FileComparisonService.compare(leftText: "", rightText: "")
            try assertTrue(resultEmpty.isIdentical)
            try assertEqual(resultEmpty.totalDifferences, 0)

            // Left empty, right has lines
            let resultAddOnly = FileComparisonService.compare(leftText: "", rightText: "line 1\nline 2\n")
            try assertFalse(resultAddOnly.isIdentical)
            try assertEqual(resultAddOnly.addedCount, 2)
            try assertEqual(resultAddOnly.deletedCount, 0)

            // Right empty, left has lines
            let resultDelOnly = FileComparisonService.compare(leftText: "line A\nline B\n", rightText: "")
            try assertFalse(resultDelOnly.isIdentical)
            try assertEqual(resultDelOnly.deletedCount, 2)
            try assertEqual(resultDelOnly.addedCount, 0)
        }

        runTest("testMyersDiffAdditionsAndDeletions") {
            let left = "Apple\nBanana\nCherry\nDate\n"
            let right = "Apple\nBlueberry\nCherry\nDate\nElderberry\n"
            let result = FileComparisonService.compare(leftText: left, rightText: right)
            try assertFalse(result.isIdentical)
            try assertTrue(result.totalDifferences > 0)

            // Verify leftLineMap and rightLineMap are populated
            try assertNotNil(result.leftLineMap[1])
            try assertNotNil(result.rightLineMap[1])
            try assertEqual(result.leftLineMap[1]?.kind, .unchanged)
            try assertEqual(result.rightLineMap[1]?.kind, .unchanged)

            // Verify gutter markers
            try assertEqual(DiffLineKind.added.gutterMarker, "+")
            try assertEqual(DiffLineKind.deleted.gutterMarker, "-")
            try assertEqual(DiffLineKind.modified.gutterMarker, "~")
            try assertEqual(DiffLineKind.unchanged.gutterMarker, " ")
        }

        runTest("testMyersDiffIntraLineRanges") {
            let strA = "const count = 10;"
            let strB = "const count = 42;"
            let (rangesA, rangesB) = FileComparisonService.computeIntraLineRanges(left: strA, right: strB)

            // Both ranges should be non-empty and point to the different substring
            try assertFalse(rangesA.isEmpty)
            try assertFalse(rangesB.isEmpty)

            let diffA = (strA as NSString).substring(with: rangesA[0])
            let diffB = (strB as NSString).substring(with: rangesB[0])
            try assertEqual(diffA, "10")
            try assertEqual(diffB, "42")
        }

        runTest("testMyersDiffPerformanceOnLargeFiles") {
            var leftLines = [String]()
            var rightLines = [String]()
            for i in 1...600 {
                if i % 20 == 0 {
                    leftLines.append("Original line item \(i)")
                    rightLines.append("Modified line item \(i) with extra content")
                } else {
                    leftLines.append("Common line data \(i)")
                    rightLines.append("Common line data \(i)")
                }
            }
            let leftText = leftLines.joined(separator: "\n")
            let rightText = rightLines.joined(separator: "\n")

            let startTime = DispatchTime.now()
            let result = FileComparisonService.compare(leftText: leftText, rightText: rightText)
            let elapsedMs = Double(DispatchTime.now().uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000.0

            try assertFalse(result.isIdentical)
            try assertTrue(result.totalDifferences > 0)
            try assertTrue(elapsedMs < 300.0, "Diff took \(elapsedMs)ms, expected < 300ms")
        }

        runTest("testSplitViewLifecycle") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_split_test_\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)

            // Start with 1 doc
            try assertEqual(appState.documents.count, 1)
            try assertFalse(appState.isSplitViewActive)

            // Split vertically creates/assigns second doc
            appState.splitVertically()
            try assertTrue(appState.isSplitViewActive)
            try assertNotNil(appState.leftDocumentId)
            try assertNotNil(appState.rightDocumentId)
            try assertNotEqual(appState.leftDocumentId, appState.rightDocumentId)
            try assertEqual(appState.documents.count, 2)

            // Test swap panes
            let originalLeft = appState.leftDocumentId
            let originalRight = appState.rightDocumentId
            appState.swapPanes()
            try assertEqual(appState.leftDocumentId, originalRight)
            try assertEqual(appState.rightDocumentId, originalLeft)

            // Test close split view
            appState.closeSplitView()
            try assertFalse(appState.isSplitViewActive)
        }

        runTest("testSplitViewIndependentEditing") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_indep_edit_\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)

            appState.splitVertically()
            guard let leftDoc = appState.leftDocument, let rightDoc = appState.rightDocument else {
                throw TestFailure(description: "Expected left and right documents to exist")
            }

            // Edit left doc
            let initialLeftContent = leftDoc.content
            leftDoc.applyEdit("Left pane exclusive text\n", newSelectedRange: NSRange(location: 25, length: 0), actionName: "Left Edit")
            try assertEqual(leftDoc.content, "Left pane exclusive text\n")
            try assertNotEqual(rightDoc.content, leftDoc.content)

            // Edit right doc
            rightDoc.applyEdit("Right pane unique content\n", newSelectedRange: NSRange(location: 26, length: 0), actionName: "Right Edit")
            try assertEqual(rightDoc.content, "Right pane unique content\n")

            // Undo left doc
            leftDoc.undo()
            try assertEqual(leftDoc.content, initialLeftContent)
            try assertEqual(rightDoc.content, "Right pane unique content\n")
        }

        runTest("testSynchronizedScrollingState") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_sync_scroll_\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)

            try assertTrue(appState.isSynchronizedScrollingEnabled)
            appState.toggleSynchronizedScrolling()
            try assertFalse(appState.isSynchronizedScrollingEnabled)
            appState.toggleSynchronizedScrolling()
            try assertTrue(appState.isSynchronizedScrollingEnabled)
        }

        runTest("testFileComparisonAndNavigation") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_comp_nav_\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)

            appState.splitVertically()
            guard let leftDoc = appState.leftDocument, let rightDoc = appState.rightDocument else {
                throw TestFailure(description: "Expected left and right docs")
            }

            leftDoc.content = "Alpha\nBeta\nGamma\nDelta\n"
            rightDoc.content = "Alpha\nBeta 2.0\nGamma\nDelta modified\n"

            appState.compareDocuments(left: leftDoc, right: rightDoc)
            try assertTrue(appState.isComparing)
            try assertNotNil(appState.comparisonResult)

            guard let diff = appState.comparisonResult else {
                throw TestFailure(description: "Comparison result is nil")
            }
            try assertEqual(diff.chunks.count, 2)

            // Test navigation
            try assertEqual(diff.activeChunkIndex, 0)
            appState.nextDifference()
            try assertEqual(appState.comparisonResult?.activeChunkIndex, 1)

            appState.nextDifference() // wraps to 0
            try assertEqual(appState.comparisonResult?.activeChunkIndex, 0)

            appState.lastDifference()
            try assertEqual(appState.comparisonResult?.activeChunkIndex, 1)

            appState.firstDifference()
            try assertEqual(appState.comparisonResult?.activeChunkIndex, 0)

            appState.previousDifference() // wraps to last
            try assertEqual(appState.comparisonResult?.activeChunkIndex, 1)

            // Test clear comparison
            appState.clearComparison()
            try assertFalse(appState.isComparing)
            try assertNil(appState.comparisonResult)
        }

        runTest("testAutoRecompareOnContentChange") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_auto_recomp_\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)

            appState.splitVertically()
            guard let leftDoc = appState.leftDocument, let rightDoc = appState.rightDocument else {
                throw TestFailure(description: "Expected left and right docs")
            }

            leftDoc.content = "Initial left\n"
            rightDoc.content = "Initial right\n"
            appState.compareDocuments(left: leftDoc, right: rightDoc)
            try assertTrue(appState.isComparing)

            // Change left doc content via applyEdit
            leftDoc.applyEdit("Initial right\n", newSelectedRange: NSRange(location: 14, length: 0), actionName: "Sync Edit")
            // Recompare is triggered automatically
            try assertTrue(appState.isComparing)
            try assertTrue(appState.comparisonResult?.isIdentical ?? false)
        }

        runTest("testProjectExplorerTreeScanAndDepth") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_tree_test_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // Create structure:
            // tempDir/
            //   file1.txt
            //   src/
            //     Main.java
            //     Utils.swift
            //     nested/
            //       data.json
            let srcDir = tempDir.appendingPathComponent("src")
            let nestedDir = srcDir.appendingPathComponent("nested")
            try FileManager.default.createDirectory(at: nestedDir, withIntermediateDirectories: true)

            try "Hello".write(to: tempDir.appendingPathComponent("file1.txt"), atomically: true, encoding: .utf8)
            try "class Main {}".write(to: srcDir.appendingPathComponent("Main.java"), atomically: true, encoding: .utf8)
            try "struct Utils {}".write(to: srcDir.appendingPathComponent("Utils.swift"), atomically: true, encoding: .utf8)
            try "{\"key\": \"val\"}".write(to: nestedDir.appendingPathComponent("data.json"), atomically: true, encoding: .utf8)

            guard let rootItem = ProjectExplorerService.buildTree(for: tempDir) else {
                throw TestFailure(description: "Expected rootItem from buildTree")
            }
            try assertTrue(rootItem.isDirectory)
            try assertEqual(rootItem.name, tempDir.lastPathComponent)
            try assertNotNil(rootItem.children)

            let children = rootItem.children!
            // Directories come first: 'src', then 'file1.txt'
            try assertTrue(children.count >= 2)
            try assertEqual(children[0].name, "src")
            try assertTrue(children[0].isDirectory)
            try assertEqual(children[1].name, "file1.txt")
            try assertFalse(children[1].isDirectory)

            // Inspect 'src' directory
            let srcChildren = children[0].children!
            let hasNested = srcChildren.contains(where: { $0.name == "nested" && $0.isDirectory })
            try assertTrue(hasNested)
            let hasMain = srcChildren.contains(where: { $0.name == "Main.java" && !$0.isDirectory })
            try assertTrue(hasMain)
            let hasUtils = srcChildren.contains(where: { $0.name == "Utils.swift" && !$0.isDirectory })
            try assertTrue(hasUtils)

            // Inspect 'nested' directory
            let nestedItem = srcChildren.first { $0.name == "nested" }!
            let nestedChildren = nestedItem.children!
            let hasDataJson = nestedChildren.contains(where: { $0.name == "data.json" })
            try assertTrue(hasDataJson)
        }

        runTest("testProjectExplorerOperations") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_ops_test_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // 1. Create file
            let newFile = try ProjectExplorerService.createFile(in: tempDir, name: "Created.swift")
            try assertTrue(FileManager.default.fileExists(atPath: newFile.path))

            // 2. Create folder
            let newFolder = try ProjectExplorerService.createFolder(in: tempDir, name: "SubFolder")
            var isDir: ObjCBool = false
            try assertTrue(FileManager.default.fileExists(atPath: newFolder.path, isDirectory: &isDir))
            try assertTrue(isDir.boolValue)

            // 3. Rename file
            let renamedFile = try ProjectExplorerService.rename(at: newFile, newName: "Renamed.swift")
            try assertFalse(FileManager.default.fileExists(atPath: newFile.path))
            try assertTrue(FileManager.default.fileExists(atPath: renamedFile.path))

            // 4. Delete file
            try ProjectExplorerService.delete(at: renamedFile)
            try assertFalse(FileManager.default.fileExists(atPath: renamedFile.path))
        }

        runTest("testAppAppearanceModes") {
            try assertEqual(AppAppearanceMode.auto.rawValue, "Auto")
            try assertEqual(AppAppearanceMode.light.rawValue, "Light")
            try assertEqual(AppAppearanceMode.dark.rawValue, "Dark")

            try assertNil(AppAppearanceMode.auto.colorScheme)
            try assertEqual(AppAppearanceMode.light.colorScheme, .light)
            try assertEqual(AppAppearanceMode.dark.colorScheme, .dark)

            try assertEqual(AppAppearanceMode.allCases.count, 3)
        }

        runTest("testEditorThemesAndManager") {
            let themes = ThemeManager.allThemeNames
            try assertTrue(themes.contains("NPad++ Classic"))
            try assertTrue(themes.contains("Dark Modern"))
            try assertTrue(themes.contains("Monokai"))
            try assertTrue(themes.contains("GitHub"))
            try assertTrue(themes.contains("Solarized Light"))
            try assertTrue(themes.contains("Solarized Dark"))

            for themeName in themes {
                let theme = ThemeManager.theme(named: themeName)
                try assertNotNil(theme.backgroundColor)
                try assertNotNil(theme.textColor)
                try assertNotNil(theme.keywordColor)
                try assertNotNil(theme.commentColor)
                try assertNotNil(theme.stringColor)
                try assertNotNil(theme.gutterBackgroundColor)
                try assertNotNil(theme.gutterTextColor)
            }
        }

        runTest("testPluginRegistryAndOperations") {
            let registry = PluginRegistry.shared
            try assertTrue(registry.plugins.count >= 8)
            try assertFalse(registry.plugins.contains(where: { $0.id == "git_tools" }), "git_tools should be removed from plugins")
            try assertFalse(registry.plugins.contains(where: { $0.id == "todo_tracker" }), "todo_tracker should be removed from plugins")

            // Test enable/disable toggle
            let pluginId = "json_tools"
            let initialEnabled = registry.isPluginEnabled(pluginId)
            registry.togglePlugin(pluginId)
            try assertEqual(registry.isPluginEnabled(pluginId), !initialEnabled)
            registry.togglePlugin(pluginId) // restore
            try assertEqual(registry.isPluginEnabled(pluginId), initialEnabled)

            // Test JSON formatting
            let unformattedJSON = "{\"b\":2,\"a\":1}"
            let (pretty, err) = PluginRegistry.formatJSON(content: unformattedJSON)
            try assertNil(err)
            try assertNotNil(pretty)
            try assertTrue(pretty!.contains("\n"))

            // Test JSON minifying
            let (minified, minErr) = PluginRegistry.minifyJSON(content: pretty!)
            try assertNil(minErr)
            try assertNotNil(minified)
            try assertFalse(minified!.contains("\n"))

            // Test XML formatting
            let rawXML = "<root><child>value</child></root>"
            let formattedXML = PluginRegistry.formatXML(content: rawXML)
            try assertTrue(formattedXML.contains("\n"))
            try assertTrue(formattedXML.contains("    <child>"))

            // Test TODO extraction
            let codeWithTodos = """
            // TODO: implement login
            int x = 10;
            // FIXME: resolve memory leak
            // NOTE: check performance
            """
            let todos = PluginRegistry.extractTodos(content: codeWithTodos)
            try assertEqual(todos.count, 3)
            try assertEqual(todos[0].line, 1)
            try assertEqual(todos[0].tag, "TODO")
            try assertEqual(todos[1].tag, "FIXME")
            try assertEqual(todos[2].tag, "NOTE")
        }

        runTest("testMenuTogglesStateSynchronization") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("npad_toggles_\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: tempDir) }
            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)

            // Sidebar toggle
            let initSidebar = appState.isSidebarVisible
            appState.isSidebarVisible.toggle()
            try assertEqual(appState.isSidebarVisible, !initSidebar)

            // Status bar toggle
            let initStatusBar = appState.isStatusBarVisible
            appState.isStatusBarVisible.toggle()
            try assertEqual(appState.isStatusBarVisible, !initStatusBar)

            // Line numbers toggle
            let initLineNumbers = appState.showLineNumbers
            appState.showLineNumbers.toggle()
            try assertEqual(appState.showLineNumbers, !initLineNumbers)

            // Word wrap toggle
            let initWordWrap = appState.wordWrap
            appState.wordWrap.toggle()
            try assertEqual(appState.wordWrap, !initWordWrap)

            // Syntax highlighting toggle
            let initSyntax = appState.syntaxHighlightingEnabled
            appState.syntaxHighlightingEnabled.toggle()
            try assertEqual(appState.syntaxHighlightingEnabled, !initSyntax)
        }

        runTest("testGitHubRepositoryURLs") {
            try assertEqual(AppStateManager.githubRepositoryURL, "https://github.com/vasi-vijay/npad-plus-plus")
            try assertEqual(AppStateManager.githubIssuesURL, "https://github.com/vasi-vijay/npad-plus-plus/issues")
        }

        runTest("testDualPaneIndependentTabsAndMovement") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc1 = appState.documents[0]
            let doc2 = appState.createNewDocument()
            let doc3 = appState.createNewDocument()
            appState.activeDocumentId = doc1.id

            try assertEqual(appState.documents.count, 3)

            // Split vertically
            appState.splitVertically()
            try assertTrue(appState.isSplitViewActive, "Split view should be active")
            try assertTrue(appState.leftDocumentIds.contains(doc1.id), "doc1 should be in left pane")
            try assertTrue(appState.leftDocumentIds.contains(doc3.id), "doc3 should be in left pane")
            try assertTrue(appState.rightDocumentIds.contains(doc2.id), "doc2 should be in right pane")

            // Move tab from left to right pane
            appState.moveTabToRightPane(docId: doc1.id)
            try assertFalse(appState.leftDocumentIds.contains(doc1.id), "doc1 should be removed from left pane")
            try assertTrue(appState.rightDocumentIds.contains(doc1.id), "doc1 should be added to right pane")
            try assertEqual(appState.activePane, .right)

            // Move tab from right to left pane
            appState.moveTabToLeftPane(docId: doc2.id)
            try assertTrue(appState.leftDocumentIds.contains(doc2.id), "doc2 should be in left pane")
            try assertFalse(appState.rightDocumentIds.contains(doc2.id), "doc2 should be removed from right pane")

            // Swap panes
            appState.swapPanes()
            try assertTrue(appState.rightDocumentIds.contains(doc2.id), "After swap, doc2 should be in right pane")
            try assertTrue(appState.leftDocumentIds.contains(doc1.id), "After swap, doc1 should be in left pane")

            // Reorder tabs within left pane
            let initialCount = appState.leftDocumentIds.count
            appState.moveDocument(id: doc1.id, to: .left, targetIndex: 0)
            try assertEqual(appState.leftDocumentIds.first, doc1.id)
            try assertEqual(appState.leftDocumentIds.count, initialCount)

            // Close right pane: tabs should be merged into left pane without losing documents
            let totalDocsBeforeClose = appState.documents.count
            appState.closeRightPane()
            try assertFalse(appState.isSplitViewActive, "Split view should be deactivated")
            try assertEqual(appState.documents.count, totalDocsBeforeClose, "No documents should be lost on close pane")
        }

        runTest("testDualPaneOpenFileInPane") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let fileURL = tempDir.appendingPathComponent("TestSplitFile.swift")
            try "print(\"Hello Dual Pane\")".write(to: fileURL, atomically: true, encoding: .utf8)

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            appState.splitVertically()

            let openedDoc = appState.openFileInPane(url: fileURL, pane: .right)
            try assertTrue(openedDoc != nil, "File should open in right pane")
            try assertTrue(appState.rightDocumentIds.contains(openedDoc!.id), "Opened file must be in right pane")
            try assertEqual(appState.rightActiveDocumentId, openedDoc!.id)
            try assertEqual(appState.activePane, .right)
        }

        runTest("testNativeWelcomeWindowController") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            NativeWelcomeWindowController.shared.show(appState: appState, showFeatures: false)
            try assertFalse(appState.welcomeExploreFeaturesActive)

            NativeWelcomeWindowController.shared.show(appState: appState, showFeatures: true)
            try assertTrue(appState.welcomeExploreFeaturesActive)

            NativeWelcomeWindowController.shared.close()
            try assertFalse(appState.showWelcomeSheet)
        }

        runTest("testTabReorderingInTabBar") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            // Use existing initial document as a1.txt, then create b2.txt, c4.md, h4.txt
            let a1 = appState.documents.first ?? appState.createNewDocument()
            a1.title = "a1.txt"
            let b2 = appState.createNewDocument()
            b2.title = "b2.txt"
            let c4 = appState.createNewDocument()
            c4.title = "c4.md"
            let h4 = appState.createNewDocument()
            h4.title = "h4.txt"

            try assertEqual(appState.documents.map(\.title), ["a1.txt", "b2.txt", "c4.md", "h4.txt"])

            // Drag c4.md to first position (index 0) -> [c4.md, a1.txt, b2.txt, h4.txt]
            appState.reorderDocument(id: c4.id, toIndex: 0)
            try assertEqual(appState.documents.map(\.title), ["c4.md", "a1.txt", "b2.txt", "h4.txt"])
            try assertEqual(appState.activeDocumentId, c4.id)

            // Drag h4.txt to index 1 -> [c4.md, h4.txt, a1.txt, b2.txt]
            appState.reorderDocument(id: h4.id, toIndex: 1)
            try assertEqual(appState.documents.map(\.title), ["c4.md", "h4.txt", "a1.txt", "b2.txt"])

            // Move c4.md to trailing end
            appState.reorderDocument(id: c4.id, toIndex: appState.documents.count)
            try assertEqual(appState.documents.map(\.title), ["h4.txt", "a1.txt", "b2.txt", "c4.md"])
        }

        runTest("testCloseFolderProjectExplorer") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let projectDir = tempDir.appendingPathComponent("MyProject")
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
            let testFile = projectDir.appendingPathComponent("main.py")
            try "print('hello')".write(to: testFile, atomically: true, encoding: .utf8)

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc1 = appState.createNewDocument()
            doc1.title = "ActiveTab.txt"
            let countBefore = appState.documents.count

            // Open project folder
            appState.openFolder(url: projectDir)
            try assertEqual(appState.workspaceRootURL?.standardizedFileURL, projectDir.standardizedFileURL)
            try assertNotNil(appState.projectRootItem)

            // Close folder
            appState.closeFolder()
            try assertNil(appState.workspaceRootURL)
            try assertNil(appState.projectRootItem)
            try assertNil(appState.selectedProjectItemURL)

            // Verify editor tabs are completely preserved
            try assertEqual(appState.documents.count, countBefore)
            try assertTrue(appState.documents.contains(where: { $0.title == "ActiveTab.txt" }))
        }

        runTest("testVerticalSplitWithDocumentDrop") {
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let appState = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
            let doc1 = appState.createNewDocument()
            doc1.title = "LeftDoc.txt"
            let doc2 = appState.createNewDocument()
            doc2.title = "RightDoc.txt"

            try assertFalse(appState.isSplitViewActive)

            // Drag doc2 to the right side drop zone
            appState.splitWithDocument(id: doc2.id, to: .right)

            try assertTrue(appState.isSplitViewActive, "Split view must be active")
            try assertTrue(appState.leftDocumentIds.contains(doc1.id), "doc1 must be in left pane")
            try assertFalse(appState.leftDocumentIds.contains(doc2.id), "doc2 must not be in left pane")
            try assertTrue(appState.rightDocumentIds.contains(doc2.id), "doc2 must be in right pane")
            try assertFalse(appState.rightDocumentIds.contains(doc1.id), "doc1 must not be in right pane")
            try assertEqual(appState.activePane, .right)
            try assertEqual(appState.activeDocumentId, doc2.id)
        }

        runTest("testAppearanceAndThemeCheckmarks") {
            try assertEqual(AppAppearanceMode.allCases.count, 3)
            try assertTrue(AppAppearanceMode.allCases.contains(.auto))
            try assertTrue(AppAppearanceMode.allCases.contains(.light))
            try assertTrue(AppAppearanceMode.allCases.contains(.dark))

            let allThemes = ThemeManager.allThemeNames
            try assertEqual(allThemes.count, 6)
            try assertTrue(allThemes.contains("NPad++ Classic"))
            try assertTrue(allThemes.contains("Dark Modern"))
            try assertTrue(allThemes.contains("Monokai"))
            try assertTrue(allThemes.contains("GitHub"))
            try assertTrue(allThemes.contains("Solarized Light"))
            try assertTrue(allThemes.contains("Solarized Dark"))
        }

        // ==============================================================================
        // Summary
        // ==============================================================================

        print("==========================================================")
        let total = passCount + failCount
        if failCount == 0 {
            print("\(cGreen)\(cBold) All \(total) of \(total) test cases passed successfully (100%)!\(cReset)")
            print(" All NPad++ editor features verified on Apple Silicon.")
            print("==========================================================\n")
            exit(0)
        } else {
            print("\(cRed)\(cBold) \(failCount) of \(total) test cases failed!\(cReset)")
            print("==========================================================\n")
            exit(1)
        }
    }
}
