# NPad++ v1.0.0 Release Notes

**Target Platform:** macOS 14.0 (Sonoma) and macOS 15.0+ (Sequoia) on Apple Silicon (arm64: M1 / M2 / M3 / M4).

### Highlights

1. **Native TextKit 1 Editing Core**:
   - Single source of truth with bidirectional `NSTextView` synchronization.
   - Text editing, typing, selection, deletion, and line operations.
   - Gutter line numbers with flipped coordinates aligned with line heights and trailing empty line computation.
   - Independent undo/redo per document tab (`⌘Z`, `⌘Y`, and `⇧⌘Z`).
   - Line shortcuts: Duplicate Line (`⌘D`), Delete Line (`⇧⌘K`), Join Lines (`⌘J`), Comment/Uncomment (`⌘/`).

2. **Advanced Multi-Tab Find & Replace**:
   - Floating native search dialog with Find, Replace, Find in Files, and Mark tabs.
   - Single-click search modes: Normal, Extended (`\n`, `\r`, `\t`, `\0`, `\x...`), Regular Expression (`.*`), and Fuzzy.
   - Instant single-click transparency adjustments (On losing focus, Always) with slider.
   - Count matches, Find in All Opened Documents, Replace in All Opened Documents.

3. **Multi-Language Syntax Engine**:
   - 18+ languages supported (Java, Swift, Python, JS/TS, C/C++, Rust, Go, XML, JSON, YAML, SQL, Shell, Markdown, etc.).
   - A-Z alphabetical language catalog with quick search and format detection.
   - Themes: NPad++ Classic, Dark Modern, Monokai, GitHub, and Solarized.

4. **Document Lifecycle & Data Protection**:
   - Session restoration and crash recovery preserving unsaved modifications across launches.
   - Close tab safety prompt (Save, Don't Save, Cancel) preventing data loss.
   - Safe Unicode UTF-8, UTF-8 BOM, UTF-16LE, and UTF-16BE support.
   - Unix (`LF`), Windows (`CRLF`), and Classic Mac (`CR`) line endings.

5. **Integrated Developer Toolkit**:
   - Built-in Developer Terminal with persistent working directory.
   - Right-click "Open Terminal Here" in current file's folder.
   - Explicit user-triggered Java/Spring code execution with output capture.
   - Base64 encoder/decoder, JSON prettifier/minifier, and line sorting plugins.
   - Web browser preview for HTML documents.
   - Print page support in File menu and context menu.

6. **Native Apple Silicon Distribution**:
   - Tested and verified native ARM64 release binary.
   - Clean drag-and-drop `NPad++.dmg` installer with `/Applications` symlink.
   - Gatekeeper ad-hoc code signature.
   - Master verification pipeline (`run_all.sh`) with 53/53 automated tests passing.
