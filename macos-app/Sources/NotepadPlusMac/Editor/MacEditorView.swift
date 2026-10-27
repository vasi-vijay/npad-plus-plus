import SwiftUI
import AppKit
import Combine

// MARK: - Editor Diagnostic Logger
public enum EditorDiagnostics {
    public static var isEnabled: Bool = false
    public static func log(_ msg: String) {
        #if DEBUG
        if isEnabled {
            NSLog("[NPad++ Diagnostic] %@", msg)
        }
        #endif
    }
}

// MARK: - CodePadScrollView with Click Forwarding & Text Cursor
public class CodePadScrollView: NSScrollView {
    public weak var editorTextView: NSTextView?

    public override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .iBeam)
    }

    public override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        if hit === verticalScroller || hit === horizontalScroller || hit === verticalRulerView || hit === horizontalRulerView {
            return hit
        }
        if hit === contentView || hit === self {
            return editorTextView ?? hit
        }
        return hit
    }

    public override func mouseDown(with event: NSEvent) {
        if let tv = editorTextView ?? (documentView as? NSTextView) {
            window?.makeFirstResponder(tv)
        }
        super.mouseDown(with: event)
    }
}

// MARK: - MacEditorView (NSViewRepresentable)
public struct MacEditorView: NSViewRepresentable {
    @ObservedObject var document: EditorDocument
    @ObservedObject var appState: AppStateManager
    var fontSize: CGFloat
    var fontFamily: String
    var wordWrap: Bool
    var showWhitespace: Bool
    var paneSide: EditorPaneSide?

    public init(
        document: EditorDocument,
        appState: AppStateManager,
        fontSize: CGFloat = 13.5,
        fontFamily: String = "SF Mono",
        wordWrap: Bool = false,
        showWhitespace: Bool = false,
        paneSide: EditorPaneSide? = nil
    ) {
        self.document = document
        self.appState = appState
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.wordWrap = wordWrap
        self.showWhitespace = showWhitespace
        self.paneSide = paneSide
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        // 1. Create native scroll view with text cursor & responder forwarding
        let scrollView = CodePadScrollView()
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor.textBackgroundColor
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        let baseWidth: CGFloat = max(scrollView.contentSize.width, 1000)
        let baseHeight: CGFloat = max(scrollView.contentSize.height, 800)

        // 2. Configure TextKit 1 components explicitly and retain them strongly in Coordinator
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let initialWidth = wordWrap ? baseWidth : CGFloat.greatestFiniteMagnitude
        let textContainer = NSTextContainer(containerSize: NSSize(width: initialWidth, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = wordWrap
        textContainer.heightTracksTextView = false
        textContainer.lineFragmentPadding = 5
        layoutManager.addTextContainer(textContainer)

        // Coordinator strongly retains textStorage and layoutManager to prevent deallocation
        context.coordinator.textStorage = textStorage
        context.coordinator.layoutManager = layoutManager

        // 3. Initialize CodePadTextView with explicit TextKit 1 textContainer
        let initialFrame = NSRect(x: 0, y: 0, width: baseWidth, height: baseHeight)
        let textView = CodePadTextView(frame: initialFrame, textContainer: textContainer)
        textView.appState = appState
        textView.document = document
        textView.paneSide = paneSide
        textView.minSize = NSSize(width: wordWrap ? baseWidth : 100, height: baseHeight)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = !wordWrap
        textView.autoresizingMask = wordWrap ? [.width] : []

        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView
        scrollView.editorTextView = textView
        context.coordinator.trackedLanguage = document.language

        // 4. Set editor behaviors & visuals
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsImageEditing = false
        textView.drawsBackground = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainerInset = NSSize(width: 8, height: 8)

        let isDark = appState.isDarkMode
        let activeTheme = ThemeManager.theme(named: appState.theme, fallbackDark: isDark)
        textView.backgroundColor = activeTheme.backgroundColor
        textView.textColor = activeTheme.textColor
        textView.insertionPointColor = activeTheme.cursorColor
        textView.selectedTextAttributes = [
            .backgroundColor: activeTheme.selectionColor,
            .foregroundColor: activeTheme.textColor
        ]

        // 5. Configure font and typing attributes using authoritative font resolver
        let font = SyntaxEngine.resolveFont(family: fontFamily, size: fontSize)
        textView.font = font
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: activeTheme.textColor
        ]

        context.coordinator.currentFontFamily = fontFamily
        context.coordinator.currentFontSize = fontSize
        context.coordinator.currentIsDark = isDark
        context.coordinator.currentThemeName = appState.theme
        context.coordinator.currentSyntaxEnabled = appState.syntaxHighlightingEnabled
        context.coordinator.currentShowLineNumbers = appState.showLineNumbers

        // 6. Set initial string & apply syntax highlighting
        textView.string = document.content
        SyntaxEngine.highlight(
            storage: textStorage,
            language: document.language,
            baseFont: font,
            isDark: isDark,
            theme: activeTheme,
            syntaxEnabled: appState.syntaxHighlightingEnabled
        )

        textView.typingAttributes = [
            .font: font,
            .foregroundColor: activeTheme.textColor
        ]

        // Restore document selection if valid
        let nsLen = (document.content as NSString).length
        if document.selectedRange.location + document.selectedRange.length <= nsLen {
            textView.setSelectedRange(document.selectedRange)
        }

        // 7. Mount document view into scroll view
        scrollView.documentView = textView

        // Restore scroll position
        if document.scrollOrigin != .zero {
            DispatchQueue.main.async {
                scrollView.contentView.scroll(to: document.scrollOrigin)
                scrollView.reflectScrolledClipView(scrollView.contentView)
            }
        }

        // 8. Line Number Ruler Gutter
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        let lineRuler = LineNumberRulerView(scrollView: scrollView, textView: textView, document: document, appState: appState, paneSide: paneSide)
        scrollView.verticalRulerView = lineRuler

        // 9. Observer for scroll & edits to redraw line numbers and keep text view filling visible viewport
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            lineRuler,
            selector: #selector(LineNumberRulerView.handleContentBoundsDidChange),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        NotificationCenter.default.addObserver(
            lineRuler,
            selector: #selector(LineNumberRulerView.handleContentBoundsDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )

        // Forward scroll changes when synchronized scrolling is active
        let coordinator = context.coordinator
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak coordinator, weak scrollView] _ in
            guard let coord = coordinator, let sv = scrollView, let docView = sv.documentView else { return }
            if coord.parent.appState.isComparing && coord.parent.appState.isSynchronizedScrollingEnabled && !coord.isSynchronizingScroll {
                if let side = coord.parent.paneSide {
                    let maxOffset = max(1, docView.bounds.height - sv.contentView.bounds.height)
                    let currentOffset = sv.contentView.bounds.origin.y
                    let ratio = max(0, min(1, currentOffset / maxOffset))
                    coord.parent.appState.editorActionSubject.send(.synchronizedScroll(senderPane: side, scrollRatio: ratio))
                }
            }
        }

        // Ensure text view fills entire clip view so clicks below/right of text immediately focus the editor
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { [weak textView, weak scrollView] _ in
            guard let tv = textView, let sv = scrollView else { return }
            let contentSize = sv.contentSize
            tv.minSize = NSSize(width: tv.isHorizontallyResizable ? 100 : contentSize.width, height: contentSize.height)
            if !tv.isHorizontallyResizable && tv.frame.size.width < contentSize.width {
                tv.frame.size.width = contentSize.width
            }
            if tv.frame.size.height < contentSize.height {
                tv.frame.size.height = contentSize.height
            }
        }

        // 10. Subscribe to search and global editor actions
        context.coordinator.subscribeToActions()

        // 11. Initial draw of persistent marks
        context.coordinator.refreshAllVisualLayers()

        // 12. Activate editor focus immediately on appearance
        DispatchQueue.main.async { [weak textView, weak scrollView] in
            guard let tv = textView else { return }
            let targetWin = tv.window ?? scrollView?.window
            targetWin?.makeFirstResponder(tv)
        }

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = nsView.documentView as? NSTextView else { return }

        if let tv = textView as? CodePadTextView {
            tv.paneSide = paneSide
        }
        if let ruler = nsView.verticalRulerView as? LineNumberRulerView {
            ruler.paneSide = paneSide
            ruler.appState = appState
        }

        let font = SyntaxEngine.resolveFont(family: fontFamily, size: fontSize)
        let isDark = appState.isDarkMode

        // A. Update font if family or size changed
        if context.coordinator.currentFontFamily != fontFamily || context.coordinator.currentFontSize != fontSize {
            context.coordinator.currentFontFamily = fontFamily
            context.coordinator.currentFontSize = fontSize
            let sel = textView.selectedRange()
            textView.font = font
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: isDark ? NSColor(calibratedWhite: 0.94, alpha: 1.0) : NSColor.textColor
            ]
            if let storage = textView.textStorage {
                SyntaxEngine.highlight(storage: storage, language: document.language, baseFont: font, isDark: isDark)
            }
            textView.setSelectedRange(sel)
            context.coordinator.refreshAllVisualLayers()
            nsView.verticalRulerView?.needsDisplay = true
        }

        // B. Update appearance or theme if mode or theme changed
        let activeTheme = ThemeManager.theme(named: appState.theme, fallbackDark: isDark)
        if context.coordinator.currentIsDark != isDark || context.coordinator.currentThemeName != appState.theme || context.coordinator.currentSyntaxEnabled != appState.syntaxHighlightingEnabled || context.coordinator.currentShowLineNumbers != appState.showLineNumbers {
            context.coordinator.currentIsDark = isDark
            context.coordinator.currentThemeName = appState.theme
            context.coordinator.currentSyntaxEnabled = appState.syntaxHighlightingEnabled
            context.coordinator.currentShowLineNumbers = appState.showLineNumbers
            let sel = textView.selectedRange()
            textView.backgroundColor = activeTheme.backgroundColor
            textView.textColor = activeTheme.textColor
            textView.insertionPointColor = activeTheme.cursorColor
            textView.selectedTextAttributes = [
                .backgroundColor: activeTheme.selectionColor,
                .foregroundColor: activeTheme.textColor
            ]
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: activeTheme.textColor
            ]
            if let storage = textView.textStorage {
                SyntaxEngine.highlight(
                    storage: storage,
                    language: document.language,
                    baseFont: font,
                    isDark: isDark,
                    theme: activeTheme,
                    syntaxEnabled: appState.syntaxHighlightingEnabled
                )
            }
            textView.setSelectedRange(sel)
            context.coordinator.refreshAllVisualLayers()
            nsView.verticalRulerView?.needsDisplay = true
        }

        // C. Update syntax highlighting if document language changed
        if context.coordinator.trackedLanguage != document.language {
            context.coordinator.trackedLanguage = document.language
            if let storage = textView.textStorage {
                SyntaxEngine.highlight(storage: storage, language: document.language, baseFont: font, isDark: isDark)
            }
            context.coordinator.refreshAllVisualLayers()
        }

        // D. Update word wrap if toggled
        let currentWrap = !textView.isHorizontallyResizable
        if currentWrap != wordWrap {
            configureWordWrap(textView: textView, in: nsView, wordWrap: wordWrap)
        }

        // E. Sync if content was modified externally (file open, tab switch, plugin)
        if !context.coordinator.isUpdating && textView.string != document.content {
            context.coordinator.isUpdating = true
            let prevSelectedRanges = textView.selectedRanges
            textView.string = document.content
            if let storage = textView.textStorage {
                SyntaxEngine.highlight(storage: storage, language: document.language, baseFont: font, isDark: isDark)
            }
            if let first = prevSelectedRanges.first as? NSRange, first.location + first.length <= (textView.string as NSString).length {
                textView.selectedRanges = prevSelectedRanges
            }
            context.coordinator.isUpdating = false
            context.coordinator.refreshAllVisualLayers()
            nsView.verticalRulerView?.needsDisplay = true
        } else {
            // Refresh marks and search highlights
            context.coordinator.refreshAllVisualLayers()
        }

        // Ensure typingAttributes are maintained
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: isDark ? NSColor(calibratedWhite: 0.94, alpha: 1.0) : NSColor.textColor
        ]

        // Ensure text view is first responder if window has no active focus or clip view has focus
        if let win = nsView.window, (win.firstResponder == nil || win.firstResponder === win || win.firstResponder is NSClipView) {
            DispatchQueue.main.async {
                win.makeFirstResponder(textView)
            }
        }
    }

    private func configureWordWrap(textView: NSTextView, in scrollView: NSScrollView, wordWrap: Bool) {
        guard let textContainer = textView.textContainer,
              let layoutManager = textView.layoutManager,
              let textStorage = textView.textStorage else { return }

        let clipView = scrollView.contentView
        let targetWidth = max(clipView.bounds.width, 200)

        if wordWrap {
            // 1. Reset horizontal scroll offset to 0 so text is never hidden off-screen
            var origin = clipView.bounds.origin
            origin.x = 0
            clipView.scroll(to: origin)

            // 2. Lock textContainer and textView to viewport width
            textContainer.containerSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
            textContainer.widthTracksTextView = true

            textView.isHorizontallyResizable = false
            textView.autoresizingMask = [.width]
            textView.minSize = NSSize(width: targetWidth, height: clipView.bounds.height)
            textView.maxSize = NSSize(width: targetWidth, height: CGFloat.greatestFiniteMagnitude)
            textView.frame = NSRect(x: 0, y: 0, width: targetWidth, height: max(textView.frame.height, clipView.bounds.height))

            scrollView.hasHorizontalScroller = false
        } else {
            // 1. Restore horizontal growth and scrolling
            textContainer.widthTracksTextView = false
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

            textView.isHorizontallyResizable = true
            textView.autoresizingMask = []
            textView.minSize = NSSize(width: targetWidth, height: clipView.bounds.height)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

            scrollView.hasHorizontalScroller = true
        }

        layoutManager.invalidateLayout(forCharacterRange: NSRange(location: 0, length: textStorage.length), actualCharacterRange: nil)
        layoutManager.ensureLayout(for: textContainer)
        textView.sizeToFit()
        textView.needsDisplay = true
        scrollView.reflectScrolledClipView(clipView)
        scrollView.verticalRulerView?.needsDisplay = true
    }

    // MARK: - Coordinator
    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MacEditorView
        weak var textView: NSTextView?
        public var textStorage: NSTextStorage?
        public var layoutManager: NSLayoutManager?
        weak var scrollView: NSScrollView?
        public var isUpdating: Bool = false
        public var isSynchronizingScroll: Bool = false
        public var trackedLanguage: String = "Plain Text"
        public var currentFontFamily: String = ""
        public var currentFontSize: CGFloat = 0
        public var currentIsDark: Bool = false
        public var currentThemeName: String = ""
        public var currentSyntaxEnabled: Bool = true
        public var currentShowLineNumbers: Bool = true
        private var syntaxHighlightWorkItem: DispatchWorkItem?
        private var cancellables = Set<AnyCancellable>()

        init(_ parent: MacEditorView) {
            self.parent = parent
            super.init()
        }

        public func subscribeToActions() {
            cancellables.removeAll()

            // Search commands
            parent.appState.findActionSubject
                .receive(on: RunLoop.main)
                .sink { [weak self] command in
                    self?.handleSearchCommand(command)
                }
                .store(in: &cancellables)

            // Global commands (Font, Language, Marks, Theme)
            parent.appState.editorActionSubject
                .receive(on: RunLoop.main)
                .sink { [weak self] command in
                    self?.handleGlobalCommand(command)
                }
                .store(in: &cancellables)
        }

        private func handleGlobalCommand(_ command: AppStateManager.EditorGlobalCommand) {
            guard let textView = self.textView else { return }

            switch command {
            case .fontChanged:
                let font = SyntaxEngine.resolveFont(family: parent.appState.fontFamily, size: parent.appState.fontSize)
                currentFontFamily = parent.appState.fontFamily
                currentFontSize = parent.appState.fontSize
                let sel = textView.selectedRange()
                let isDark = parent.appState.isDarkMode
                textView.font = font
                textView.typingAttributes = [
                    .font: font,
                    .foregroundColor: isDark ? NSColor(calibratedWhite: 0.94, alpha: 1.0) : NSColor.textColor
                ]
                if let storage = textView.textStorage {
                    SyntaxEngine.highlight(storage: storage, language: parent.document.language, baseFont: font, isDark: isDark)
                }
                textView.setSelectedRange(sel)
                refreshAllVisualLayers()
                scrollView?.verticalRulerView?.needsDisplay = true

            case .themeChanged:
                let isDark = parent.appState.isDarkMode
                currentIsDark = isDark
                currentThemeName = parent.appState.theme
                currentSyntaxEnabled = parent.appState.syntaxHighlightingEnabled
                currentShowLineNumbers = parent.appState.showLineNumbers
                let activeTheme = ThemeManager.theme(named: parent.appState.theme, fallbackDark: isDark)
                let font = SyntaxEngine.resolveFont(family: parent.appState.fontFamily, size: parent.appState.fontSize)
                let sel = textView.selectedRange()
                textView.backgroundColor = activeTheme.backgroundColor
                textView.textColor = activeTheme.textColor
                textView.insertionPointColor = activeTheme.cursorColor
                textView.selectedTextAttributes = [
                    .backgroundColor: activeTheme.selectionColor,
                    .foregroundColor: activeTheme.textColor
                ]
                textView.typingAttributes = [
                    .font: font,
                    .foregroundColor: activeTheme.textColor
                ]
                if let storage = textView.textStorage {
                    SyntaxEngine.highlight(
                        storage: storage,
                        language: parent.document.language,
                        baseFont: font,
                        isDark: isDark,
                        theme: activeTheme,
                        syntaxEnabled: parent.appState.syntaxHighlightingEnabled
                    )
                }
                textView.setSelectedRange(sel)
                refreshAllVisualLayers()
                scrollView?.verticalRulerView?.needsDisplay = true

            case .languageChanged:
                trackedLanguage = parent.document.language
                if let storage = textView.textStorage, let font = textView.font {
                    let isDark = parent.appState.isDarkMode
                    SyntaxEngine.highlight(storage: storage, language: parent.document.language, baseFont: font, isDark: isDark)
                }
                refreshAllVisualLayers()

            case .marksChanged:
                refreshAllVisualLayers()

            case .contentReplacedFromUndoRedo:
                isUpdating = true
                textView.string = parent.document.content
                if let storage = textView.textStorage {
                    let font = SyntaxEngine.resolveFont(family: parent.appState.fontFamily, size: parent.appState.fontSize)
                    SyntaxEngine.highlight(storage: storage, language: parent.document.language, baseFont: font, isDark: parent.appState.isDarkMode)
                }
                let nsLen = (textView.string as NSString).length
                if parent.document.selectedRange.location + parent.document.selectedRange.length <= nsLen {
                    textView.setSelectedRange(parent.document.selectedRange)
                }
                isUpdating = false
                refreshAllVisualLayers()
                scrollView?.verticalRulerView?.needsDisplay = true

            case .diffUpdated:
                textView.needsDisplay = true
                scrollView?.verticalRulerView?.needsDisplay = true

            case .scrollToDifference(let chunk):
                let side = parent.paneSide ?? (parent.appState.activeDocumentId == parent.document.id ? parent.appState.activePane : .left)
                let targetLine = (side == .left) ? chunk.leftLineStart : chunk.rightLineStart
                guard targetLine > 0 else { return }

                let str = (textView.string as NSString)
                let charIdx = parent.document.characterIndex(forLine: targetLine, in: textView.string)
                let safeIdx = min(charIdx, str.length)

                if let layoutMgr = textView.layoutManager, let sv = scrollView {
                    let glyphIdx = layoutMgr.glyphIndexForCharacter(at: safeIdx)
                    let rect = layoutMgr.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: nil)
                    let targetY = max(0, rect.origin.y - sv.contentView.bounds.height / 3)
                    sv.contentView.scroll(to: NSPoint(x: sv.contentView.bounds.origin.x, y: targetY))
                    sv.reflectScrolledClipView(sv.contentView)
                } else {
                    textView.scrollRangeToVisible(NSRange(location: safeIdx, length: 0))
                }
                textView.setSelectedRange(NSRange(location: safeIdx, length: 0))
                textView.needsDisplay = true
                scrollView?.verticalRulerView?.needsDisplay = true

            case .synchronizedScroll(let senderPane, let scrollRatio):
                guard let mySide = parent.paneSide, mySide != senderPane, let sv = scrollView, let docView = sv.documentView else {
                    return
                }
                guard !isSynchronizingScroll else { return }
                isSynchronizingScroll = true
                let maxOffset = max(1, docView.bounds.height - sv.contentView.bounds.height)
                let targetY = max(0, min(maxOffset, scrollRatio * maxOffset))
                sv.contentView.scroll(to: NSPoint(x: sv.contentView.bounds.origin.x, y: targetY))
                sv.reflectScrolledClipView(sv.contentView)
                DispatchQueue.main.async { [weak self] in
                    self?.isSynchronizingScroll = false
                }
            }
        }

        private func handleSearchCommand(_ command: AppStateManager.EditorSearchCommand) {
            guard let textView = self.textView else { return }

            switch command {
            case .selectMatch(let range):
                let nsLen = (textView.string as NSString).length
                guard range.location != NSNotFound, range.location + range.length <= nsLen else { return }

                textView.setSelectedRange(range)
                textView.scrollRangeToVisible(range)
                textView.showFindIndicator(for: range)
                refreshAllVisualLayers()

            case .replaceCurrent(let replacement, let range):
                let nsLen = (textView.string as NSString).length
                guard range.location != NSNotFound, range.location + range.length <= nsLen else { return }

                if textView.shouldChangeText(in: range, replacementString: replacement) {
                    textView.replaceCharacters(in: range, with: replacement)
                    textView.didChangeText()
                    parent.appState.updateSearchMatches()
                }

            case .replaceAll(let query, let replacement, let options):
                let result = SearchEngine.replaceAll(
                    in: textView.string,
                    query: query,
                    replacement: replacement,
                    options: options
                )

                if result.count > 0 {
                    let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
                    textView.undoManager?.beginUndoGrouping()
                    if textView.shouldChangeText(in: fullRange, replacementString: result.newText) {
                        textView.replaceCharacters(in: fullRange, with: result.newText)
                        textView.didChangeText()
                    }
                    textView.undoManager?.endUndoGrouping()
                    parent.appState.updateSearchMatches()
                }

            case .clearHighlights:
                refreshAllVisualLayers()

            case .focusEditor:
                textView.window?.makeFirstResponder(textView)

            case .focusSearch:
                break
            }
        }

        /// Redraws persistent marks and search highlights using non-destructive temporary attributes
        public func refreshAllVisualLayers() {
            guard let layoutManager = self.layoutManager,
                  let textView = self.textView else { return }

            let fullLength = (textView.string as NSString).length
            guard fullLength > 0 else { return }
            let fullRange = NSRange(location: 0, length: fullLength)

            // Clear temporary background attributes
            layoutManager.removeTemporaryAttribute(.backgroundColor, forCharacterRange: fullRange)

            // 1. Render Persistent Marks Layer
            for mark in parent.document.marks {
                guard mark.location + mark.length <= fullLength else { continue }
                let color = markColor(for: mark.colorName)
                layoutManager.addTemporaryAttribute(.backgroundColor, value: color, forCharacterRange: mark.range)
            }

            // 2. Render Search Highlights Layer (takes visual priority over marks)
            if parent.appState.isFindBarVisible {
                let matches = parent.appState.searchMatches
                let currentIdx = parent.appState.currentMatchIndex

                for (i, r) in matches.enumerated() {
                    guard r.location + r.length <= fullLength else { continue }
                    if i + 1 == currentIdx {
                        layoutManager.addTemporaryAttribute(
                            .backgroundColor,
                            value: NSColor.systemOrange.withAlphaComponent(0.70),
                            forCharacterRange: r
                        )
                    } else {
                        layoutManager.addTemporaryAttribute(
                            .backgroundColor,
                            value: NSColor.systemYellow.withAlphaComponent(0.40),
                            forCharacterRange: r
                        )
                    }
                }
            }
        }

        private func markColor(for name: String) -> NSColor {
            MarkPalette.highlight(name)
        }

        // Delegate: Provide independent UndoManager per document
        public func undoManager(for view: NSTextView) -> UndoManager? {
            return parent.document.undoManager
        }

        // Intercept Tab key to insert 4 spaces instead of shifting keyboard focus
        public func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertTab(_:)) {
                textView.insertText("    ", replacementRange: textView.selectedRange())
                return true
            }
            return false
        }

        public func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            let currentContent = textView.string
            let currentSelection = textView.selectedRange()
            parent.document.applyEdit(
                currentContent,
                newSelectedRange: currentSelection,
                actionName: "Typing"
            )
            parent.appState.scheduleSessionSave()
            isUpdating = false

            // Trigger ruler redraw
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true

            // Cancel any pending syntax highlighting to avoid thrashing during typing
            syntaxHighlightWorkItem?.cancel()

            let lang = parent.document.language.lowercased()
            if lang == "plain text" {
                // For plain text, no regex highlighting is required; refresh visual layers (marks/search)
                self.refreshAllVisualLayers()
            } else {
                let workItem = DispatchWorkItem { [weak self, weak textView] in
                    guard let self = self, let textView = textView, let storage = textView.textStorage else { return }
                    let font = textView.font ?? SyntaxEngine.resolveFont(family: self.parent.appState.fontFamily, size: self.parent.appState.fontSize)
                    let isDark = self.parent.appState.isDarkMode
                    SyntaxEngine.highlight(storage: storage, language: self.parent.document.language, baseFont: font, isDark: isDark)
                    textView.typingAttributes = [
                        .font: font,
                        .foregroundColor: isDark ? NSColor(calibratedWhite: 0.94, alpha: 1.0) : NSColor.textColor
                    ]
                    self.refreshAllVisualLayers()
                }
                self.syntaxHighlightWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
            }

            // Update search results if find bar is open
            if parent.appState.isFindBarVisible {
                parent.appState.updateSearchMatches()
            }

            // Immediately refresh ruler on text changes (e.g. newlines typed or deleted)
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        public func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let sel = textView.selectedRange()
            let text = textView.string as NSString

            parent.document.selectedRange = sel

            let safeLoc = min(sel.location, text.length)
            let prefix = text.substring(with: NSRange(location: 0, length: safeLoc))
            let lines = prefix.components(separatedBy: "\n")
            let newLine = lines.count
            parent.document.cursorLine = newLine
            parent.document.cursorColumn = (lines.last?.count ?? 0) + 1
            parent.document.selectionLength = sel.length

            if let clipView = textView.enclosingScrollView?.contentView {
                parent.document.scrollOrigin = clipView.bounds.origin
            }

            // Invalidate ruler when cursor position changes to refresh active line highlight
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
    }
}

// MARK: - CodePadTextView with Notepad++ Context Menu (Priority 2, 3, 4)
public class CodePadTextView: NSTextView {
    public weak var appState: AppStateManager?
    public weak var document: EditorDocument?
    public var paneSide: EditorPaneSide? = nil

    public override var acceptsFirstResponder: Bool {
        return true
    }

    public override var canBecomeKeyView: Bool {
        return true
    }

    public override var needsPanelToBecomeKey: Bool {
        return false
    }

    public override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    public override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .iBeam)
    }

    public override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonSetup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }

    private func commonSetup() {
        isEditable = true
        isSelectable = true
        allowsUndo = true
        isRichText = false
        importsGraphics = false
        allowsImageEditing = false
        drawsBackground = true
        focusRingType = .none
    }

    public override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        EditorDiagnostics.log("becomeFirstResponder: \(ok), doc=\(document?.title ?? "")")
        needsDisplay = true
        return ok
    }

    public override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        EditorDiagnostics.log("resignFirstResponder: \(ok), doc=\(document?.title ?? "")")
        needsDisplay = true
        return ok
    }

    public override func mouseDown(with event: NSEvent) {
        EditorDiagnostics.log("mouseDown at \(event.locationInWindow), isEditable=\(isEditable), isKeyWindow=\(window?.isKeyWindow ?? false)")
        if let side = paneSide, let app = appState {
            app.activePane = side
            if let doc = document {
                app.activeDocumentId = doc.id
            }
        }
        if window?.firstResponder !== self {
            window?.makeFirstResponder(self)
        }
        super.mouseDown(with: event)
    }

    public override func drawBackground(in rect: NSRect) {
        super.drawBackground(in: rect)

        guard let app = appState, app.isComparing, let diffResult = app.comparisonResult else {
            return
        }
        let side = paneSide ?? (app.activeDocumentId == document?.id ? app.activePane : .left)
        let lineMap = (side == .left) ? diffResult.leftLineMap : diffResult.rightLineMap
        guard !lineMap.isEmpty, let layoutMgr = layoutManager, let textCont = textContainer else {
            return
        }

        let isDark = app.isDarkMode
        let str = (string as NSString)
        let totalLen = str.length
        guard totalLen > 0 else { return }

        let activeChunk = diffResult.activeChunk

        let glyphRange = layoutMgr.glyphRange(forBoundingRect: rect, in: textCont)
        guard glyphRange.length > 0 else { return }
        let charRange = layoutMgr.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        var lineIndex = 1
        var searchPos = 0

        while searchPos < totalLen {
            str.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: searchPos, length: 0))

            if lineEnd > charRange.location && lineStart < (charRange.location + charRange.length) {
                if let diffInfo = lineMap[lineIndex], diffInfo.kind != .unchanged {
                    let charLen = max(1, contentsEnd - lineStart)
                    let lineGlyphRange = layoutMgr.glyphRange(forCharacterRange: NSRange(location: lineStart, length: min(charLen, totalLen - lineStart)), actualCharacterRange: nil)
                    var lineRect = layoutMgr.lineFragmentUsedRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
                    lineRect.origin.x = 0
                    lineRect.size.width = bounds.width

                    let tintColor: NSColor
                    switch diffInfo.kind {
                    case .added:
                        tintColor = isDark
                            ? NSColor(red: 0.12, green: 0.40, blue: 0.16, alpha: 0.35)
                            : NSColor(red: 0.82, green: 0.96, blue: 0.82, alpha: 0.65)
                    case .deleted:
                        tintColor = isDark
                            ? NSColor(red: 0.48, green: 0.15, blue: 0.15, alpha: 0.35)
                            : NSColor(red: 0.98, green: 0.84, blue: 0.84, alpha: 0.65)
                    case .modified:
                        tintColor = isDark
                            ? NSColor(red: 0.45, green: 0.30, blue: 0.10, alpha: 0.35)
                            : NSColor(red: 1.00, green: 0.93, blue: 0.78, alpha: 0.65)
                    case .unchanged:
                        tintColor = .clear
                    }

                    if tintColor != .clear {
                        tintColor.setFill()
                        lineRect.fill()
                    }

                    // Active difference indicator bar on edge
                    let isActiveLine: Bool
                    if side == .left, let lRange = activeChunk?.leftLineRange {
                        isActiveLine = lRange.contains(lineIndex)
                    } else if side == .right, let rRange = activeChunk?.rightLineRange {
                        isActiveLine = rRange.contains(lineIndex)
                    } else {
                        isActiveLine = false
                    }

                    if isActiveLine {
                        let activeBarRect = NSRect(x: 0, y: lineRect.minY, width: 3.5, height: lineRect.height)
                        let barColor = isDark ? NSColor.systemYellow : NSColor.systemOrange
                        barColor.setFill()
                        activeBarRect.fill()
                    }

                    // Intra-line character changes
                    if diffInfo.kind == .modified && !diffInfo.modifiedCharacterRanges.isEmpty {
                        let intraColor = isDark
                            ? NSColor(red: 0.65, green: 0.45, blue: 0.15, alpha: 0.60)
                            : NSColor(red: 1.00, green: 0.82, blue: 0.50, alpha: 0.85)
                        for subRange in diffInfo.modifiedCharacterRanges {
                            let absLoc = lineStart + subRange.location
                            let absLen = min(subRange.length, totalLen - absLoc)
                            if absLen > 0 {
                                let subGlyphRange = layoutMgr.glyphRange(forCharacterRange: NSRange(location: absLoc, length: absLen), actualCharacterRange: nil)
                                layoutMgr.enumerateEnclosingRects(forGlyphRange: subGlyphRange, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: textCont) { r, _ in
                                    intraColor.setFill()
                                    r.insetBy(dx: 0, dy: -1).fill()
                                }
                            }
                        }
                    }
                }
            }

            if lineEnd >= (charRange.location + charRange.length) {
                break
            }
            searchPos = max(lineEnd, searchPos + 1)
            lineIndex += 1
        }
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let win = window {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                win.makeFirstResponder(self)
            }
        }
    }

    public override func insertText(_ string: Any, replacementRange: NSRange) {
        let strLen = (string as? String)?.count ?? (string as? NSAttributedString)?.string.count ?? 0
        EditorDiagnostics.log("insertText: len=\(strLen), range=\(replacementRange)")
        super.insertText(string, replacementRange: replacementRange)
        needsDisplay = true
    }

    public override func keyDown(with event: NSEvent) {
        EditorDiagnostics.log("keyDown: code=\(event.keyCode), chars='\(event.characters ?? "")', isEditable=\(isEditable)")
        super.keyDown(with: event)
    }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags == .command {
            if let chars = event.charactersIgnoringModifiers?.lowercased(), chars == "y" {
                EditorDiagnostics.log("performKeyEquivalent: Redo via Command+Y")
                appState?.redoActiveDocument()
                return true
            }
        } else if flags == [.command, .shift] {
            if let chars = event.charactersIgnoringModifiers?.lowercased(), chars == "z" {
                EditorDiagnostics.log("performKeyEquivalent: Redo via Shift+Command+Z")
                appState?.redoActiveDocument()
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    public override func paste(_ sender: Any?) {
        EditorDiagnostics.log("paste action triggered, isEditable=\(isEditable)")
        super.paste(sender)
    }

    public override func copy(_ sender: Any?) {
        EditorDiagnostics.log("copy action triggered, selRange=\(selectedRange())")
        super.copy(sender)
    }

    public override func cut(_ sender: Any?) {
        EditorDiagnostics.log("cut action triggered, selRange=\(selectedRange())")
        super.cut(sender)
    }

    public override func selectAll(_ sender: Any?) {
        EditorDiagnostics.log("selectAll action triggered")
        super.selectAll(sender)
    }

    public override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu(title: "Editor Context Menu")
        menu.autoenablesItems = false

        let undoItem = NSMenuItem(title: "Undo", action: #selector(handleContextUndo), keyEquivalent: "z")
        undoItem.target = self
        undoItem.isEnabled = document?.canUndo ?? false
        menu.addItem(undoItem)

        let redoItem = NSMenuItem(title: "Redo", action: #selector(handleContextRedo), keyEquivalent: "Z")
        redoItem.target = self
        redoItem.isEnabled = document?.canRedo ?? false
        menu.addItem(redoItem)

        menu.addItem(NSMenuItem.separator())

        let cutItem = NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        cutItem.isEnabled = selectedRange().length > 0
        menu.addItem(cutItem)

        let copyItem = NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        copyItem.isEnabled = selectedRange().length > 0
        menu.addItem(copyItem)

        let pasteItem = NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        pasteItem.isEnabled = true
        menu.addItem(pasteItem)

        let selectAllItem = NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        selectAllItem.isEnabled = true
        menu.addItem(selectAllItem)

        menu.addItem(NSMenuItem.separator())

        let findItem = NSMenuItem(title: "Find...", action: #selector(handleContextFind), keyEquivalent: "f")
        findItem.target = self
        findItem.isEnabled = true
        menu.addItem(findItem)

        let replaceItem = NSMenuItem(title: "Replace...", action: #selector(handleContextReplace), keyEquivalent: "h")
        replaceItem.target = self
        replaceItem.isEnabled = true
        menu.addItem(replaceItem)

        menu.addItem(NSMenuItem.separator())

        let hasSelection = selectedRange().length > 0
        let highlightItem = NSMenuItem(title: "Highlight", action: nil, keyEquivalent: "")
        let highlightMenu = NSMenu(title: "Highlight")
        highlightMenu.autoenablesItems = false
        for name in MarkPalette.names {
            let item = NSMenuItem(title: name, action: #selector(handleContextHighlight(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = name
            item.image = MarkPalette.swatch(name)
            item.state = (appState?.activeMarkColor == name) ? .on : .off
            item.isEnabled = hasSelection
            highlightMenu.addItem(item)
        }
        highlightMenu.addItem(NSMenuItem.separator())
        let removeHighlightItem = NSMenuItem(title: "Remove Highlight", action: #selector(handleContextRemoveHighlight), keyEquivalent: "")
        removeHighlightItem.target = self
        removeHighlightItem.isEnabled = hasSelection
        highlightMenu.addItem(removeHighlightItem)
        highlightItem.submenu = highlightMenu
        highlightItem.isEnabled = hasSelection
        menu.addItem(highlightItem)

        menu.addItem(NSMenuItem.separator())

        let encodeItem = NSMenuItem(title: "Base64 Encode", action: #selector(handleContextBase64Encode), keyEquivalent: "")
        encodeItem.target = self
        encodeItem.isEnabled = true
        menu.addItem(encodeItem)

        let decodeItem = NSMenuItem(title: "Base64 Decode", action: #selector(handleContextBase64Decode), keyEquivalent: "")
        decodeItem.target = self
        decodeItem.isEnabled = true
        menu.addItem(decodeItem)

        menu.addItem(NSMenuItem.separator())

        let runFileItem = NSMenuItem(title: "Run File", action: #selector(handleContextRunFile), keyEquivalent: "")
        runFileItem.target = self
        runFileItem.isEnabled = true
        menu.addItem(runFileItem)

        let openTermItem = NSMenuItem(title: "Open Terminal Here", action: #selector(handleContextOpenTerminalHere), keyEquivalent: "")
        openTermItem.target = self
        openTermItem.isEnabled = true
        menu.addItem(openTermItem)

        menu.addItem(NSMenuItem.separator())

        let printItem = NSMenuItem(title: "Print...", action: #selector(handleContextPrint), keyEquivalent: "p")
        printItem.target = self
        printItem.isEnabled = true
        menu.addItem(printItem)

        menu.addItem(NSMenuItem.separator())

        let openInOtherItem = NSMenuItem(title: "Open in Other Pane", action: #selector(handleContextOpenInOtherPane), keyEquivalent: "")
        openInOtherItem.target = self
        openInOtherItem.isEnabled = true
        menu.addItem(openInOtherItem)

        let compareOtherItem = NSMenuItem(title: "Compare with Other Pane", action: #selector(handleContextCompareWithOtherPane), keyEquivalent: "")
        compareOtherItem.target = self
        compareOtherItem.isEnabled = (appState?.isSplitViewActive == true) && (appState?.leftDocumentId != appState?.rightDocumentId)
        menu.addItem(compareOtherItem)

        let selectFirstItem = NSMenuItem(title: "Select First to Compare", action: #selector(handleContextSelectFirstToCompare), keyEquivalent: "")
        selectFirstItem.target = self
        selectFirstItem.isEnabled = true
        menu.addItem(selectFirstItem)

        let compareSelectedItem = NSMenuItem(title: "Compare with Selected", action: #selector(handleContextCompareWithSelected), keyEquivalent: "")
        compareSelectedItem.target = self
        compareSelectedItem.isEnabled = (appState?.firstComparisonDocId != nil && appState?.firstComparisonDocId != document?.id)
        menu.addItem(compareSelectedItem)

        return menu
    }

    @objc private func handleContextOpenInOtherPane() {
        guard let doc = document else { return }
        appState?.openInOtherPane(doc: doc)
    }

    @objc private func handleContextCompareWithOtherPane() {
        appState?.compareWithOtherPane()
    }

    @objc private func handleContextSelectFirstToCompare() {
        guard let doc = document else { return }
        appState?.selectFirstToCompare(doc: doc)
    }

    @objc private func handleContextCompareWithSelected() {
        guard let doc = document else { return }
        appState?.compareWithSelected(doc: doc)
    }

    @objc private func handleContextUndo() {
        appState?.undoActiveDocument()
    }

    @objc private func handleContextRedo() {
        appState?.redoActiveDocument()
    }

    @objc private func handleContextFind() {
        appState?.openFindDialog(tab: .find)
    }

    @objc private func handleContextHighlight(_ sender: NSMenuItem) {
        guard let name = sender.representedObject as? String else { return }
        appState?.markSelection(colorName: name)
    }

    @objc private func handleContextRemoveHighlight() {
        appState?.removeMarkFromSelection()
    }

    @objc private func handleContextReplace() {
        appState?.openFindDialog(tab: .replace)
    }

    @objc private func handleContextRunFile() {
        appState?.runActiveDocumentInTerminal()
    }

    @objc private func handleContextBase64Encode() {
        appState?.base64EncodeSelectionOrDocument()
    }

    @objc private func handleContextBase64Decode() {
        appState?.base64DecodeSelectionOrDocument()
    }

    @objc private func handleContextOpenTerminalHere() {
        _ = appState?.openTerminalHere(for: document)
    }

    @objc public func handleContextPrint() {
        printPage()
    }

    public func printPage() {
        EditorDiagnostics.log("printPage triggered for doc: \(document?.title ?? "")")
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.horizontalPagination = .fit
        printInfo.isVerticallyCentered = false
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36

        let printOp = NSPrintOperation(view: self, printInfo: printInfo)
        printOp.showsPrintPanel = true
        printOp.showsProgressPanel = true
        if let win = self.window {
            printOp.runModal(for: win, delegate: nil, didRun: nil, contextInfo: nil)
        } else {
            printOp.run()
        }
    }
}

// MARK: - Line Number Ruler View
public class LineNumberRulerView: NSRulerView {
    public weak var document: EditorDocument?
    public weak var appState: AppStateManager?
    public var paneSide: EditorPaneSide? = nil

    public init(
        scrollView: NSScrollView,
        textView: NSTextView,
        document: EditorDocument? = nil,
        appState: AppStateManager? = nil,
        paneSide: EditorPaneSide? = nil
    ) {
        self.document = document
        self.appState = appState
        self.paneSide = paneSide
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 48.0
    }

    public required init(coder: NSCoder) {
        super.init(coder: coder)
        self.ruleThickness = 48.0
    }

    public override var isFlipped: Bool {
        return true
    }

    public override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: .arrow)
    }

    public override func mouseDown(with event: NSEvent) {
        if let side = paneSide, let app = appState {
            app.activePane = side
            if let doc = document {
                app.activeDocumentId = doc.id
            }
        }
        let pointInRuler = convert(event.locationInWindow, from: nil)
        guard let textView = self.clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              textView.textContainer != nil else {
            super.mouseDown(with: event)
            return
        }

        let text = textView.string as NSString
        let clickY = pointInRuler.y - textView.textContainerInset.height

        var targetLine = 1
        var currentLine = 1
        let fullRange = NSRange(location: 0, length: text.length)

        if text.length > 0 {
            text.enumerateSubstrings(in: fullRange, options: [.byLines, .substringNotRequired]) { _, subRange, _, stop in
                let glyphIndex = layoutManager.glyphIndexForCharacter(at: subRange.location)
                let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
                if clickY >= lineRect.minY && clickY <= lineRect.maxY {
                    targetLine = currentLine
                    stop.pointee = true
                    textView.setSelectedRange(NSRange(location: subRange.location, length: 0))
                }
                currentLine += 1
            }

            // Check if clicked in trailing newline extra line
            let hasTrailingNewline = text.length > 0 && {
                let lastChar = text.character(at: text.length - 1)
                return lastChar == 0x0A || lastChar == 0x0D
            }()
            if hasTrailingNewline {
                let extraRect: NSRect
                if layoutManager.extraLineFragmentTextContainer != nil && layoutManager.extraLineFragmentRect.height > 0 {
                    extraRect = layoutManager.extraLineFragmentRect
                } else {
                    let lastGlyph = max(0, layoutManager.numberOfGlyphs - 1)
                    let lastRect = layoutManager.lineFragmentRect(forGlyphAt: lastGlyph, effectiveRange: nil)
                    extraRect = NSRect(x: lastRect.origin.x, y: lastRect.maxY, width: lastRect.width, height: max(lastRect.height, 18))
                }
                if clickY >= extraRect.minY && clickY <= extraRect.maxY + 5 {
                    targetLine = currentLine
                    textView.setSelectedRange(NSRange(location: text.length, length: 0))
                }
            }
        }

        document?.toggleBookmark(targetLine)
        document?.cursorLine = targetLine
        needsDisplay = true
        window?.makeFirstResponder(textView)
    }

    @objc public func handleContentBoundsDidChange(_ notification: Notification) {
        self.needsDisplay = true
    }

    public override func draw(_ dirtyRect: NSRect) {
        drawGutter(in: dirtyRect)
    }

    public override func drawHashMarksAndLabels(in rect: NSRect) {
        drawGutter(in: rect)
    }

    private func drawGutter(in rect: NSRect) {
        guard let textView = self.clientView as? NSTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return }

        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()

        // 1. Draw ruler gutter background using active theme
        let isDark = appState?.isDarkMode ?? false
        let activeTheme = ThemeManager.theme(named: appState?.theme ?? "", fallbackDark: isDark)
        let gutterBg = activeTheme.gutterBackgroundColor
        gutterBg.setFill()
        bounds.fill()

        // 2. Draw gutter separator line on the right
        NSColor.separatorColor.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: bounds.width - 0.5, y: bounds.minY))
        path.line(to: NSPoint(x: bounds.width - 0.5, y: bounds.maxY))
        path.lineWidth = 1.0
        path.stroke()

        let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let labelFontSize = max(10, font.pointSize - 2)
        let regularLabelFont = NSFont.monospacedDigitSystemFont(ofSize: labelFontSize, weight: .regular)
        let boldLabelFont = NSFont.monospacedDigitSystemFont(ofSize: labelFontSize, weight: .bold)

        let text = textView.string as NSString
        let activeLine = document?.cursorLine ?? 1

        if text.length == 0 {
            if self.appState?.showLineNumbers ?? true {
                let numStr = "1" as NSString
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: boldLabelFont,
                    .foregroundColor: activeTheme.textColor
                ]
                let numSize = numStr.size(withAttributes: attrs)
                let drawPoint = NSPoint(x: bounds.width - numSize.width - 8, y: textView.textContainerInset.height)
                numStr.draw(at: drawPoint, withAttributes: attrs)
            }

            if document?.bookmarks.contains(1) == true {
                let dotRect = NSRect(x: 6, y: textView.textContainerInset.height + 3, width: 7, height: 7)
                NSColor.systemBlue.setFill()
                NSBezierPath(ovalIn: dotRect).fill()
            }
            context?.restoreGState()
            return
        }

        let visibleRect = textView.visibleRect
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let charRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

        // Count lines before the visible range
        var lineNumber = 1
        if charRange.location > 0 && charRange.location <= text.length {
            text.enumerateSubstrings(in: NSRange(location: 0, length: charRange.location), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
                lineNumber += 1
            }
        }

        // Dynamically adjust ruler thickness for large documents
        let totalLinesEstimate = max(lineNumber + 50, 100)
        let neededDigits = "\(totalLinesEstimate)".count
        let minThickness = CGFloat(max(48, neededDigits * 9 + 20))
        if abs(self.ruleThickness - minThickness) > 6 {
            self.ruleThickness = minThickness
        }

        // Draw line numbers and bookmark indicators for visible lines
        text.enumerateSubstrings(in: charRange, options: [.byLines, .substringNotRequired]) { [weak self] _, subRange, _, _ in
            guard let self = self else { return }
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: subRange.location)
            let lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
            let y = lineRect.origin.y + textView.textContainerInset.height

            let isCurrent = (lineNumber == activeLine)
            let isBookmarked = self.document?.bookmarks.contains(lineNumber) == true

            // Draw Bookmark Indicator Dot
            if isBookmarked {
                let dotRect = NSRect(x: 6, y: y + max(0, (lineRect.height - 7) / 2), width: 7, height: 7)
                let bPath = NSBezierPath(ovalIn: dotRect)
                NSColor.systemBlue.setFill()
                bPath.fill()
            }

            // Draw Comparison Marker Indicator in Gutter
            if let app = self.appState, app.isComparing, let diffResult = app.comparisonResult {
                let side = self.paneSide ?? (app.activeDocumentId == self.document?.id ? app.activePane : .left)
                let lineMap = (side == .left) ? diffResult.leftLineMap : diffResult.rightLineMap
                if let diffInfo = lineMap[lineNumber], diffInfo.kind != .unchanged {
                    let markerColor: NSColor
                    let markerSymbol: String
                    switch diffInfo.kind {
                    case .added:
                        markerColor = NSColor.systemGreen
                        markerSymbol = "+"
                    case .deleted:
                        markerColor = NSColor.systemRed
                        markerSymbol = "-"
                    case .modified:
                        markerColor = NSColor.systemOrange
                        markerSymbol = "~"
                    case .unchanged:
                        markerColor = .clear
                        markerSymbol = ""
                    }

                    let rulerStrip = NSRect(x: 0, y: y, width: self.bounds.width, height: lineRect.height)
                    markerColor.withAlphaComponent(0.20).setFill()
                    rulerStrip.fill()

                    let symbolAttrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.boldSystemFont(ofSize: 10),
                        .foregroundColor: markerColor
                    ]
                    let symbolStr = markerSymbol as NSString
                    symbolStr.draw(at: NSPoint(x: 4, y: y + max(0, (lineRect.height - 12) / 2)), withAttributes: symbolAttrs)
                }
            }

            let attrs: [NSAttributedString.Key: Any] = [
                .font: isCurrent ? boldLabelFont : regularLabelFont,
                .foregroundColor: isCurrent ? activeTheme.textColor : activeTheme.gutterTextColor
            ]

            if self.appState?.showLineNumbers ?? true {
                let numStr = "\(lineNumber)" as NSString
                let numSize = numStr.size(withAttributes: attrs)
                let drawPoint = NSPoint(x: self.bounds.width - numSize.width - 8, y: y + max(0, (lineRect.height - numSize.height) / 2))
                numStr.draw(at: drawPoint, withAttributes: attrs)
            }

            lineNumber += 1
        }

        // Draw line number for trailing newline (e.g. empty line at end of file / cursor on new line)
        let hasTrailingNewline = text.length > 0 && {
            let lastChar = text.character(at: text.length - 1)
            return lastChar == 0x0A || lastChar == 0x0D
        }()

        if hasTrailingNewline {
            let extraRect: NSRect
            if layoutManager.extraLineFragmentTextContainer != nil && layoutManager.extraLineFragmentRect.height > 0 {
                extraRect = layoutManager.extraLineFragmentRect
            } else {
                let lastGlyph = max(0, layoutManager.numberOfGlyphs - 1)
                let lastRect = layoutManager.lineFragmentRect(forGlyphAt: lastGlyph, effectiveRange: nil)
                extraRect = NSRect(x: lastRect.origin.x, y: lastRect.maxY, width: lastRect.width, height: max(lastRect.height, 18))
            }

            let y = extraRect.origin.y + textView.textContainerInset.height
            if (y + extraRect.height >= visibleRect.minY && y <= visibleRect.maxY) || visibleRect.intersects(extraRect) || extraRect.minY <= visibleRect.maxY {
                let isCurrent = (lineNumber == activeLine)
                let isBookmarked = self.document?.bookmarks.contains(lineNumber) == true

                if isBookmarked {
                    let dotRect = NSRect(x: 6, y: y + max(0, (extraRect.height - 7) / 2), width: 7, height: 7)
                    let bPath = NSBezierPath(ovalIn: dotRect)
                    NSColor.systemBlue.setFill()
                    bPath.fill()
                }

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: isCurrent ? boldLabelFont : regularLabelFont,
                    .foregroundColor: isCurrent ? activeTheme.textColor : activeTheme.gutterTextColor
                ]

                if self.appState?.showLineNumbers ?? true {
                    let numStr = "\(lineNumber)" as NSString
                    let numSize = numStr.size(withAttributes: attrs)
                    let drawPoint = NSPoint(x: self.bounds.width - numSize.width - 8, y: y + max(0, (extraRect.height - numSize.height) / 2))
                    numStr.draw(at: drawPoint, withAttributes: attrs)
                }
            }
        }

        context?.restoreGState()
    }
}
