#if canImport(XCTest)
import XCTest
@testable import NotepadPlusMac

final class NotepadPlusMacTests: XCTestCase {

    func testDocumentCreationAndDefaults() {
        let doc = EditorDocument(
            title: "TestFile.java",
            content: "public class TestFile {}",
            language: "Java"
        )

        XCTAssertEqual(doc.title, "TestFile.java")
        XCTAssertEqual(doc.content, "public class TestFile {}")
        XCTAssertEqual(doc.language, "Java")
        XCTAssertEqual(doc.encoding, .utf8)
        XCTAssertEqual(doc.lineEnding, .lf)
        XCTAssertFalse(doc.isModified)
        XCTAssertTrue(doc.bookmarks.isEmpty)
        XCTAssertTrue(doc.marks.isEmpty)
        XCTAssertEqual(doc.selectedRange, NSRange(location: 0, length: 0))
    }

    func testIndependentUndoManagersPerDocument() {
        let doc1 = EditorDocument(title: "Doc1.txt", content: "hello")
        let doc2 = EditorDocument(title: "Doc2.txt", content: "world")

        XCTAssertNotEqual(ObjectIdentifier(doc1.undoManager), ObjectIdentifier(doc2.undoManager),
                          "Each document must have its own isolated UndoManager")
    }

    // MARK: - Language Detection Tests
    func testLanguageDetection() {
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "App.java"), "Java")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "index.ts"), "TypeScript")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "Component.tsx"), "TypeScript")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "server.js"), "JavaScript")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "script.py"), "Python")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "ContentView.swift"), "Swift")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "main.c"), "C")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "engine.cpp"), "C++")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "Program.cs"), "C#")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "server.go"), "Go")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "lib.rs"), "Rust")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "index.html"), "HTML")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "styles.css"), "CSS")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "data.json"), "JSON")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "config.yaml"), "YAML")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "schema.sql"), "SQL")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "build.sh"), "Shell")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "README.md"), "Markdown")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "application.properties"), "Properties")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "output.log"), "Log")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "pom.xml"), "XML")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "build.gradle"), "Gradle")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "build.gradle.kts"), "Gradle")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "unknown.xyz"), "Plain Text")
    }

    func testExtendedFileTypeDetection() {
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: ".env"), "Properties")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: ".env.local"), "Properties")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: ".gitignore"), "Ignore")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "Dockerfile"), "Dockerfile")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "App.jsx"), "JavaScript")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "data.csv"), "CSV")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "Cargo.toml"), "TOML")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "run", content: "#!/usr/bin/env python3\n"), "Python")
        XCTAssertEqual(SyntaxEngine.detectLanguage(from: "run", content: "#!/usr/bin/ruby\nputs 'flush'"), "Ruby")
    }

    func testFileCodecRoundTrip() throws {
        var bom = Data([0xEF, 0xBB, 0xBF])
        bom.append("héllo".data(using: .utf8)!)
        let decoded = FileCodec.decode(bom)
        XCTAssertEqual(decoded.text, "héllo")
        XCTAssertEqual(decoded.encoding, .utf8BOM)

        let legacy = Data([0x63, 0x61, 0x66, 0xE9])
        let legacyDecoded = FileCodec.decode(legacy)
        XCTAssertEqual(legacyDecoded.text, "café")
        XCTAssertEqual(try FileCodec.encode(legacyDecoded.text, as: legacyDecoded.encoding), legacy)

        XCTAssertThrowsError(try FileCodec.encode("日本語", as: .ascii))
    }

    func testBinaryDetection() {
        XCTAssertTrue(FileTypeRegistry.looksBinary(Data([0x89, 0x50, 0x4E, 0x47, 0x00, 0x00])))
        XCTAssertFalse(FileTypeRegistry.looksBinary("print('hi')\n".data(using: .utf8)!))
    }

    // MARK: - Font Settings Tests
    func testFontAdjustments() {
        let manager = AppStateManager()
        let initialSize = manager.fontSize

        manager.increaseFontSize()
        XCTAssertEqual(manager.fontSize, initialSize + 1.0)

        manager.decreaseFontSize()
        XCTAssertEqual(manager.fontSize, initialSize)

        manager.resetFontSize()
        XCTAssertEqual(manager.fontSize, 13.5)

        XCTAssertFalse(manager.availableFontFamilies.isEmpty)
        XCTAssertTrue(manager.availableFontFamilies.contains("SF Mono") || manager.availableFontFamilies.contains("Menlo"))
    }

    func testAuthoritativeFontResolver() {
        let sfMono = SyntaxEngine.resolveFont(family: "SF Mono", size: 14)
        XCTAssertEqual(sfMono.pointSize, 14.0)

        let menloBold = SyntaxEngine.resolveFont(family: "Menlo", size: 16, bold: true)
        XCTAssertEqual(menloBold.pointSize, 16.0)

        let fallback = SyntaxEngine.resolveFont(family: "NonExistentSpecialFontXYZ", size: 13)
        XCTAssertEqual(fallback.pointSize, 13.0)
    }

    func testAppearanceAndThemeModes() {
        let manager = AppStateManager()
        XCTAssertEqual(AppAppearanceMode.allCases.count, 3)

        manager.appearanceMode = .light
        XCTAssertFalse(manager.isDarkMode)

        manager.appearanceMode = .dark
        XCTAssertTrue(manager.isDarkMode)

        manager.theme = "Monokai"
        XCTAssertEqual(manager.theme, "Monokai")
    }

    // MARK: - Persistent Text Marking Tests
    func testPersistentTextMarking() {
        let doc = EditorDocument(title: "Code.java", content: "int value = 42;")
        XCTAssertTrue(doc.marks.isEmpty)

        // Mark "value" (location 4, length 5)
        let range1 = NSRange(location: 4, length: 5)
        doc.toggleMark(for: range1, colorName: "Yellow")
        XCTAssertEqual(doc.marks.count, 1)
        XCTAssertEqual(doc.marks[0].colorName, "Yellow")
        XCTAssertEqual(doc.marks[0].range, range1)

        // Mark "42" (location 12, length 2) with Green
        let range2 = NSRange(location: 12, length: 2)
        doc.toggleMark(for: range2, colorName: "Green")
        XCTAssertEqual(doc.marks.count, 2)

        // Toggle off range1 (overlapping)
        doc.toggleMark(for: range1)
        XCTAssertEqual(doc.marks.count, 1)
        XCTAssertEqual(doc.marks[0].range, range2)

        // Clear all marks
        doc.clearAllMarks()
        XCTAssertTrue(doc.marks.isEmpty)

        // Verify document content was untouched
        XCTAssertEqual(doc.content, "int value = 42;")
    }

    // MARK: - Language Mode Switching
    func testLanguageModeSwitching() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("codepad_test_xct_lang_\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let manager = AppStateManager(storageDirectoryURL: tempDir, restorePreviousSession: false)
        guard let doc = manager.activeDocument else {
            XCTFail("Expected active document")
            return
        }

        manager.setLanguageForActiveDocument("Java")
        XCTAssertEqual(doc.language, "Java")
        manager.setLanguageForActiveDocument("Python")
        XCTAssertEqual(doc.language, "Python")
        manager.setLanguageForActiveDocument("Plain Text")
        XCTAssertEqual(doc.language, "Plain Text")
    }

    func testLineEndingSequences() {
        XCTAssertEqual(LineEndingFormat.lf.newlineSequence, "\n")
        XCTAssertEqual(LineEndingFormat.crlf.newlineSequence, "\r\n")
        XCTAssertEqual(LineEndingFormat.cr.newlineSequence, "\r")
    }

    func testAppStateManagerDocumentLifecycle() {
        let manager = AppStateManager()
        XCTAssertFalse(manager.documents.isEmpty)
        let initialCount = manager.documents.count

        // Create new document
        manager.createNewDocument()
        XCTAssertEqual(manager.documents.count, initialCount + 1)
        XCTAssertEqual(manager.activeDocumentId, manager.documents.last?.id)

        // Close created document
        if let lastId = manager.documents.last?.id {
            manager.closeDocument(id: lastId)
            XCTAssertEqual(manager.documents.count, initialCount)
        }
    }

    func testLineOperationsOnDocument() {
        let manager = AppStateManager()
        guard let doc = manager.activeDocument else {
            XCTFail("Expected active document")
            return
        }

        doc.content = "line1\nline2\nline3"
        doc.cursorLine = 2

        manager.duplicateCurrentLine()
        XCTAssertEqual(doc.content, "line1\nline2\nline2\nline3")

        manager.deleteCurrentLine()
        XCTAssertEqual(doc.content, "line1\nline2\nline3")

        manager.joinLines()
        XCTAssertEqual(doc.content, "line1\nline2 line3")
    }

    func testBookmarkNavigation() {
        let manager = AppStateManager()
        guard let doc = manager.activeDocument else {
            XCTFail("Expected active document")
            return
        }

        doc.bookmarks = [5, 12, 25]
        doc.cursorLine = 1

        manager.nextBookmark()
        XCTAssertEqual(doc.cursorLine, 5)

        manager.nextBookmark()
        XCTAssertEqual(doc.cursorLine, 12)

        manager.prevBookmark()
        XCTAssertEqual(doc.cursorLine, 5)

        manager.clearBookmarks()
        XCTAssertTrue(doc.bookmarks.isEmpty)
    }

    func testCommentToggling() {
        let manager = AppStateManager()
        guard let doc = manager.activeDocument else {
            XCTFail("Expected active document")
            return
        }

        doc.language = "Java"
        doc.content = "System.out.println(\"Hello\");"
        doc.cursorLine = 1

        manager.toggleComment()
        XCTAssertEqual(doc.content, "// System.out.println(\"Hello\");")

        manager.toggleComment()
        XCTAssertEqual(doc.content, "System.out.println(\"Hello\");")
    }

    // MARK: - SearchEngine Tests
    func testSearchEngineLiteralMatches() {
        let text = "Notepad++ for Mac is fast. Fast editing for everyone."
        let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
        let res = SearchEngine.findAll(in: text, query: "fast", options: opts)

        XCTAssertEqual(res.totalCount, 2)
        XCTAssertEqual(res.matchingRanges.count, 2)
        XCTAssertNil(res.errorMessage)
    }

    func testSearchEngineCaseSensitivity() {
        let text = "Apple apple APPLE"
        let sensitive = SearchOptions(caseSensitive: true, wholeWord: false, isRegex: false)
        let insensitive = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)

        let resSensitive = SearchEngine.findAll(in: text, query: "apple", options: sensitive)
        XCTAssertEqual(resSensitive.totalCount, 1)

        let resInsensitive = SearchEngine.findAll(in: text, query: "apple", options: insensitive)
        XCTAssertEqual(resInsensitive.totalCount, 3)
    }

    func testSearchEngineWholeWord() {
        let text = "cat catch scatter concatenate cat"
        let wholeWordOpts = SearchOptions(caseSensitive: false, wholeWord: true, isRegex: false)
        let res = SearchEngine.findAll(in: text, query: "cat", options: wholeWordOpts)

        XCTAssertEqual(res.totalCount, 2)
    }

    func testSearchEngineRegex() {
        let text = "Item 01, Item 42, Item 999"
        let regexOpts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: true)
        let res = SearchEngine.findAll(in: text, query: "Item \\d{2}\\b", options: regexOpts)

        XCTAssertEqual(res.totalCount, 2)

        let invalid = SearchEngine.findAll(in: text, query: "[unclosed", options: regexOpts)
        XCTAssertNotNil(invalid.errorMessage)
        XCTAssertEqual(invalid.totalCount, 0)
    }

    func testSearchEngineUnicodeAndAccents() {
        let text = "Café au lait, café latte, crème brûlée"
        let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
        let res = SearchEngine.findAll(in: text, query: "café", options: opts)

        XCTAssertEqual(res.totalCount, 2)
    }

    func testSearchEngineNextAndPreviousNavigation() {
        let text = "one two one two one"
        let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
        let res = SearchEngine.findAll(in: text, query: "one", options: opts)
        XCTAssertEqual(res.matchingRanges.count, 3)

        let r0 = res.matchingRanges[0]
        let r1 = res.matchingRanges[1]
        let r2 = res.matchingRanges[2]

        let nextFrom0 = SearchEngine.nextIndex(from: r0, in: res.matchingRanges, wrap: true)
        XCTAssertEqual(nextFrom0, 1)

        let nextFrom2 = SearchEngine.nextIndex(from: r2, in: res.matchingRanges, wrap: true)
        XCTAssertEqual(nextFrom2, 0)

        let prevFrom1 = SearchEngine.previousIndex(from: r1, in: res.matchingRanges, wrap: true)
        XCTAssertEqual(prevFrom1, 0)

        let prevFrom0 = SearchEngine.previousIndex(from: r0, in: res.matchingRanges, wrap: true)
        XCTAssertEqual(prevFrom0, 2)
    }

    func testSearchEngineReplaceSingle() {
        let text = "Hello World, Welcome World"
        let target = NSRange(location: 6, length: 5)
        let res = SearchEngine.replace(in: text, targetRange: target, with: "Universe")

        XCTAssertNotNil(res)
        XCTAssertEqual(res?.newText, "Hello Universe, Welcome World")
        XCTAssertEqual(res?.newRange, NSRange(location: 6, length: 8))
    }

    func testSearchEngineReplaceAll() {
        let text = "foo bar foo baz foo"
        let opts = SearchOptions(caseSensitive: false, wholeWord: false, isRegex: false)
        let res = SearchEngine.replaceAll(in: text, query: "foo", replacement: "qux", options: opts)

        XCTAssertEqual(res.count, 3)
        XCTAssertEqual(res.newText, "qux bar qux baz qux")
    }
}
#endif

