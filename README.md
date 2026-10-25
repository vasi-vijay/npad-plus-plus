# NPad++

**A lightweight, native macOS code editor for developers.**

NPad++ is a macOS code editor designed to provide a clean, fast, and productive environment for writing and editing source code. Built with a focus on usability and developer productivity, NPad++ aims to bring a familiar Notepad++-inspired editing experience to macOS.

The project focuses on essential code-editing capabilities, a native macOS interface, flexible file management, and tools that help developers work efficiently.

**Repository:** [vasi-vijay/npad-plus-plus](https://github.com/vasi-vijay/npad-plus-plus)

---

## Features

### Code Editing
- Create, open, edit, and save text files.
- Multi-tab document management.
- Syntax highlighting for supported programming languages.
- Line numbers and editor navigation.
- Find and Replace functionality.
- Undo and Redo.
- Unsaved-change tracking and document recovery, where supported.

### Split View and File Comparison
- Side-by-side editing with left and right editor panes.
- Drag-and-drop file movement between panes.
- Resizable editor panels.
- Tab reordering through drag-and-drop.
- File comparison with added, deleted, and modified line highlighting, where implemented.
- Navigation between differences and synchronized scrolling, where supported.

### Project and File Management
- Open individual files or entire folders.
- Navigate nested directories through the project explorer.
- Manage multiple open documents.
- Close an opened project folder without deleting its files.
- Open files directly from the project explorer.

### Customization
- Auto, Light, and Dark application appearance modes.
- Editor color themes.
- Theme selection indicators.
- Configurable editor appearance and preferences, where supported.

### Developer Productivity
- Integrated terminal and code execution for supported languages, where implemented.
- Plugin management and extensions, where available.
- Keyboard shortcuts.
- A welcome screen and in-app feature guide.
- GitHub documentation and issue tracking.

*Note: Feature availability depends on the current implementation. Consult the repository for the latest supported functionality.*

---

## Screenshots

Add screenshots of the latest NPad++ interface here.

```markdown
![NPad++ Editor](docs/images/editor.png)
![NPad++ Split View](docs/images/split-view.png)
![NPad++ Welcome Screen](docs/images/welcome.png)
```

Replace these example paths with screenshots committed to the repository.

---

## Installation

### Download the macOS Application

1. Visit the [NPad++ GitHub repository](https://github.com/vasi-vijay/npad-plus-plus).
2. Open the Releases section, if a release has been published.
3. Download the latest available macOS DMG installer.
4. Open the DMG and install or copy the application as instructed.
5. Launch NPad++ from your Applications folder.

If macOS blocks an application that is not signed or notarized, review the system's security warning and verify the download's origin before deciding whether to open it.

### Build from Source

To build NPad++ locally, you will need a Mac and the development tools required by the project.

Typical prerequisites include:

- macOS compatible with the project's deployment target.
- Xcode and the Swift toolchain.
- Git.
- Any additional dependencies specified by the project.

Clone the repository:

```bash
git clone https://github.com/vasi-vijay/npad-plus-plus.git
cd npad-plus-plus
```

Open the project in Xcode or follow the build instructions provided in the repository.

If the project uses Swift Package Manager, you may be able to build it with:

```bash
swift build
```

Use this command only if the repository is configured for Swift Package Manager. Otherwise, use the project's actual Xcode project, workspace, or build script.

---

## Getting Started

### Open a File
Use **Open File** to select an existing source-code or text file.

### Open a Project
Use **Open Folder** to load a project directory into the project explorer and navigate its files.

### Create a New File
Select **New File** to create a new editable document.

### Use Split View
Enable vertical split view to work with two files side by side. Open or drag files into the desired pane.

### Compare Files
Select two files and use the comparison feature, if available, to inspect changes and navigate between differences.

### Customize the Editor
Choose Auto, Light, or Dark for application appearance and select an available editor theme independently.

---

## Project Goals

NPad++ aims to provide:

- A clean and responsive macOS editing experience.
- Reliable file and folder management.
- Efficient multi-tab and split-pane workflows.
- Accurate text editing and undo/redo behavior.
- Useful developer tools without unnecessary interface complexity.
- Native macOS interactions and accessibility.
- An extensible architecture for future enhancements.

The goal is to make everyday code editing simple, practical, and productive.

---

## Technology Stack

The application is developed for macOS using the technologies and frameworks defined in the project.

The implementation may include:

- **Swift** — application development.
- **SwiftUI and/or AppKit** — macOS user interface.
- **Foundation** — file handling and core utilities.
- **Xcode** — development and packaging.

Refer to the source code and project configuration for the exact frameworks, versions, and dependencies.

---

## Documentation and Support

- **GitHub Repository:** https://github.com/vasi-vijay/npad-plus-plus
- **Report a Bug:** [Open an issue](https://github.com/vasi-vijay/npad-plus-plus/issues)
- **Request a Feature:** [Submit a feature request](https://github.com/vasi-vijay/npad-plus-plus/issues)
- **Source Code:** [Browse the repository](https://github.com/vasi-vijay/npad-plus-plus)

When reporting a bug, include the macOS version, NPad++ version, steps to reproduce the issue, and relevant error messages or screenshots.

---

## Contributing

Contributions, suggestions, and bug reports are welcome.

Before submitting a contribution:

1. Review the existing source code and project structure.
2. Check open issues to avoid duplicating work.
3. Keep changes focused and consistent with the project's architecture.
4. Test changes before submitting them.
5. Document new features and relevant configuration changes.

For substantial changes, consider opening an issue first to discuss the proposed implementation.

---

## Security

Download NPad++ only from the official project repository or another source explicitly linked by the project maintainers.

Do not install untrusted plugins or execute code from unknown sources. Report security concerns through the repository's supported reporting process.

---

## License

The license for NPad++ is determined by the license file included in this repository.

**Before publishing a release, add a `LICENSE` file and update this section to identify the actual license.** Do not assume that NPad++ uses the GNU General Public License simply because the original Notepad++ does.

---

## Acknowledgments

NPad++ is inspired by the broader ecosystem of developer tools that make code editing accessible, efficient, and customizable.

The original [Notepad++ project](https://github.com/notepad-plus-plus/notepad-plus-plus) is an established source-code editor for Windows. NPad++ is a separate macOS project with its own implementation, design, and development roadmap.

---

**NPad++ — A focused workspace for coding on macOS.**
