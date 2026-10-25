# NPad++ for macOS (Apple Silicon M1 / M2 / M3 / M4)

A fast, lightweight, high-productivity developer source-code editor inspired by the classic Windows editor, natively crafted for macOS Sonoma and Sequoia and optimized for Apple Silicon ARM64 chips.

---

## Key Features

1. **Native Apple Silicon Performance**: Built for ARM64 with instant launch, sub-millisecond tab switching, low memory footprint, and smooth scrolling.
2. **TextKit 1 Stable Editor Core**:
   - Single source-of-truth document synchronization with `NSTextView`
   - Gutter line numbers with flipped coordinates aligned with line heights
   - Independent undo/redo manager per document tab (edits on one tab don't dirty another tab's undo history)
   - Real-time syntax highlighting for 18+ languages (Java, Swift, Python, JS/TS, C/C++, Rust, Go, XML, JSON, YAML, SQL, Shell, Markdown, etc.)
   - Line editing shortcuts: Duplicate Line (`⌘D`), Delete Line (`⇧⌘K`), Join Lines (`⌘J`), Comment/Uncomment (`⌘/`), Redo (`⌘Y` / `⇧⌘Z`)
3. **Multi-Tab Find & Replace**:
   - Floating native search dialog with Find, Replace, Find in Files, and Mark tabs
   - Normal, Extended (`\n`, `\r`, `\t`, `\0`, `\x...`), Regular Expression (`.*`), and Fuzzy search modes
   - Match case and Match whole word options
   - Find in All Opened Documents, Replace in All Opened Documents, and Count
   - Adjustable dialog opacity and transparency behavior
4. **Encoding & Line Ending Precision**:
   - Detection and conversion for UTF-8, UTF-8 with BOM, UTF-16LE, UTF-16BE, ASCII
   - Full support for Unix/macOS (`LF`), Windows (`CRLF`), and Classic Mac (`CR`) line endings
5. **Developer Toolkit & Extensibility**:
   - **Integrated Terminal**: Execute zsh/bash commands directly in your project directory
   - **Right-Click Open Terminal Here**: Launch terminal in current document folder
   - **Java & Spring Boot Toolkit**: Symbol outline, Spring Boot annotations, and quick scaffolding
   - **Modular Plugin System**: JSON prettifier/minifier, Base64 encoder/decoder, line sorter
6. **Native macOS Squircle Icon**:
   - Approved chameleon logo with native continuous squircle corners
   - Multi-resolution iconset (16x16 to 1024x1024) and standalone `AppIcon.icns`

---

## Building from Source on macOS (Apple Silicon)

### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Xcode 15 or later (or Xcode Command Line Tools: `xcode-select --install`)
- Apple Silicon Mac (M1, M2, M3, M4, Pro/Max/Ultra)

### Master 1-Step Runner & Verification Script (Recommended)
```bash
chmod +x run_all.sh build.sh test.sh create_dmg.sh install_to_applications.sh
./run_all.sh
```
This single command:
1. Sets script execution permissions
2. Runs the native test suite (all 53 unit & integration tests)
3. Cross-checks editor input, typing, and modification tracking
4. Compiles the ARM64 release binary and assembles `build/Release/NPad++.app`
5. Packages `NPad++.dmg` for distribution

---

### Individual Step Commands

#### 1. Compile & Build App Bundle
```bash
chmod +x build.sh
./build.sh
```
This compiles the ARM64 binary, embeds the app icon, applies ad-hoc codesigning for Gatekeeper, and generates `build/Release/NPad++.app`.

#### 2. Running the Test Suite
```bash
./test.sh
```

#### 3. Creating the Distributable DMG
```bash
chmod +x create_dmg.sh
./create_dmg.sh
```
This generates `NPad++.dmg` containing the application bundle, ad-hoc codesignature, and `/Applications` drag-and-drop installer.

#### 4. Installing to /Applications
```bash
chmod +x install_to_applications.sh
./install_to_applications.sh
```

---

## License & Notices
NPad++ is distributed under the MIT License.
Independent macOS project; not affiliated with, endorsed by, or sponsored by Don Ho or Notepad++ for Windows.

