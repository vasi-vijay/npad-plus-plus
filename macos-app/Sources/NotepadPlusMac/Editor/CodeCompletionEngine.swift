import Foundation
import AppKit
import SwiftUI
import Combine

// MARK: - Code Completion Engine (In-File Document Auto-Completion)
public enum CodeCompletionEngine {

    /// Extracts all identifiers and chained dotted expressions from document text in a fast single pass.
    /// Excludes any tokens inside `excludingRange` (e.g. the active word being typed at cursor).
    public static func extractTokens(from text: String, excludingRange: NSRange? = nil) -> Set<String> {
        var tokens = Set<String>()
        let ns = text as NSString
        let len = ns.length
        guard len > 0 else { return tokens }

        var i = 0
        while i < len {
            let ch = ns.character(at: i)
            // Starts with identifier character [a-zA-Z_$]
            if (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122) || ch == 95 || ch == 36 {
                let tokenStart = i
                var dotCount = 0

                while i < len {
                    let c = ns.character(at: i)
                    if (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 48 && c <= 57) || c == 95 || c == 36 {
                        i += 1
                    } else if c == 46 { // '.'
                        // Must be followed by another identifier character to form a valid member access chain
                        if i + 1 < len {
                            let nextC = ns.character(at: i + 1)
                            if (nextC >= 65 && nextC <= 90) || (nextC >= 97 && nextC <= 122) || nextC == 95 || nextC == 36 {
                                dotCount += 1
                                i += 1
                                continue
                            }
                        }
                        break
                    } else {
                        break
                    }
                }

                let tokenRange = NSRange(location: tokenStart, length: i - tokenStart)
                if let ex = excludingRange, NSIntersectionRange(tokenRange, ex).length > 0 {
                    continue
                }

                let fullToken = ns.substring(with: tokenRange)
                if fullToken.count >= 2 {
                    tokens.insert(fullToken)
                    // If chained (e.g. System.out.println), extract sub-chains & parts
                    if dotCount > 0 {
                        let parts = fullToken.components(separatedBy: ".")
                        for p in parts where p.count >= 2 {
                            tokens.insert(p)
                        }
                        if parts.count > 2 {
                            for a in 0..<(parts.count - 1) {
                                for b in (a + 1)...parts.count {
                                    if b - a >= 2 && (b - a) < parts.count {
                                        tokens.insert(parts[a..<b].joined(separator: "."))
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                i += 1
            }
        }
        return tokens
    }

    /// Finds the token prefix (and its character range) preceding the insertion point.
    /// Supports dotted chains (e.g. "System.", "System.o", "split.") and plain words ("The", "Sys").
    public static func findPrefix(in text: String, at location: Int) -> (prefix: String, range: NSRange)? {
        let nsText = text as NSString
        guard location > 0 && location <= nsText.length else { return nil }

        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$.").union(CharacterSet.alphanumerics)
        var start = location - 1

        while start >= 0 {
            let ch = nsText.character(at: start)
            guard let scalar = UnicodeScalar(ch), allowed.contains(scalar) else { break }
            if start == 0 {
                start = -1
                break
            }
            start -= 1
        }

        let prefixStart = start + 1
        let prefixLength = location - prefixStart
        guard prefixLength > 0 else { return nil }

        let prefixRange = NSRange(location: prefixStart, length: prefixLength)
        let prefix = nsText.substring(with: prefixRange)

        // Must contain at least one letter or identifier starter
        let letterSet = CharacterSet.letters.union(CharacterSet(charactersIn: "_$"))
        guard prefix.rangeOfCharacter(from: letterSet) != nil else { return nil }

        // Require minimum length of 2 (prevents noisy single-letter popups on 'a', 'I', etc.)
        guard prefix.count >= 2 else { return nil }

        return (prefix, prefixRange)
    }

    /// Searches text for candidates matching the given prefix.
    /// Only returns candidates actually found in the document.
    public static func findMatches(prefix: String, in text: String, excludingRange: NSRange? = nil, maxCount: Int = 12) -> [String] {
        let tokens = extractTokens(from: text, excludingRange: excludingRange)
        guard !tokens.isEmpty else { return [] }

        let lower = prefix.lowercased()
        let filtered = tokens.filter { cand in
            guard cand.lowercased().hasPrefix(lower) else { return false }
            // If user already typed the exact full candidate, do not redundantly suggest it
            if cand == prefix { return false }
            return true
        }

        // Exact case prefix matches come first, then shorter tokens, then alphabetical
        let sorted = filtered.sorted { a, b in
            let aExact = a.hasPrefix(prefix)
            let bExact = b.hasPrefix(prefix)
            if aExact != bExact { return aExact }
            if a.count != b.count { return a.count < b.count }
            return a < b
        }

        return Array(sorted.prefix(maxCount))
    }
}

// MARK: - Completion State
public class CompletionState: ObservableObject {
    @Published public var items: [String] = []
    @Published public var selectedIndex: Int = 0
    @Published public var prefix: String = ""
    @Published public var isDark: Bool = false
    public var currentPrefixRange: NSRange = NSRange(location: NSNotFound, length: 0)
    public var onSelect: ((String, NSRange) -> Void)?

    public init() {}

    public func selectNext() {
        guard !items.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % items.count
    }

    public func selectPrevious() {
        guard !items.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + items.count) % items.count
    }

    public var selectedItem: String? {
        guard selectedIndex >= 0 && selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    public func commitSelected() {
        guard let item = selectedItem else { return }
        onSelect?(item, currentPrefixRange)
    }
}

// MARK: - Completion Popup View
public struct CompletionPopupView: View {
    @ObservedObject var state: CompletionState

    public init(state: CompletionState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(0..<min(state.items.count, 10), id: \.self) { idx in
                let item = state.items[idx]
                let isSelected = idx == state.selectedIndex

                HStack(spacing: 6) {
                    Image(systemName: item.contains(".") ? "cube" : "text.word.spacing")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isSelected ? .white : (item.contains(".") ? .accentColor : .secondary))
                        .frame(width: 14)

                    highlightedLabel(item: item, prefix: state.prefix, isSelected: isSelected)
                        .font(.system(size: 12, design: .monospaced))

                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    state.selectedIndex = idx
                    state.commitSelected()
                }
            }
        }
        .padding(4)
        .frame(minWidth: 180, maxWidth: 360, alignment: .leading)
        .background(
            CompletionVisualEffect(
                material: state.isDark ? .hudWindow : .popover,
                blendingMode: .behindWindow
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(state.isDark ? Color.white.opacity(0.18) : Color.black.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func highlightedLabel(item: String, prefix: String, isSelected: Bool) -> some View {
        if let range = item.range(of: prefix, options: [.caseInsensitive, .anchored]) {
            let matched = String(item[range])
            let remainder = String(item[range.upperBound...])
            HStack(spacing: 0) {
                Text(matched)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : (state.isDark ? Color(red: 0.35, green: 0.75, blue: 1.0) : .accentColor))
                Text(remainder)
                    .foregroundColor(isSelected ? .white : (state.isDark ? Color(white: 0.92) : .primary))
            }
        } else {
            Text(item)
                .foregroundColor(isSelected ? .white : (state.isDark ? Color(white: 0.92) : .primary))
        }
    }
}

// MARK: - Visual Effect Background
public struct CompletionVisualEffect: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Code Completion Controller
public class CodeCompletionController {
    private var panel: NSPanel?
    private let state = CompletionState()
    private weak var currentTextView: NSTextView?

    public init() {}

    public var isVisible: Bool {
        return panel != nil && panel?.isVisible == true
    }

    public func showCompletions(
        candidates: [String],
        prefix: String,
        prefixRange: NSRange,
        for textView: NSTextView,
        isDark: Bool,
        onCommit: @escaping (String, NSRange) -> Void
    ) {
        guard !candidates.isEmpty, let window = textView.window else {
            dismiss()
            return
        }

        self.currentTextView = textView
        state.items = candidates
        state.selectedIndex = 0
        state.prefix = prefix
        state.isDark = isDark
        state.currentPrefixRange = prefixRange
        state.onSelect = onCommit

        if panel == nil {
            let p = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 220, height: 120),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            p.level = .floating
            p.isOpaque = false
            p.backgroundColor = .clear
            p.hasShadow = true
            p.isMovable = false
            p.isReleasedWhenClosed = false

            let hosting = NSHostingView(rootView: CompletionPopupView(state: state))
            p.contentView = hosting
            self.panel = p
        } else {
            if let hosting = panel?.contentView as? NSHostingView<CompletionPopupView> {
                hosting.rootView = CompletionPopupView(state: state)
            }
        }

        guard let p = panel else { return }

        updatePosition(for: textView)

        if p.parent != window {
            if let oldParent = p.parent {
                oldParent.removeChildWindow(p)
            }
            window.addChildWindow(p, ordered: .above)
        }
        p.orderFront(nil)
    }

    public func updatePosition(for textView: NSTextView) {
        guard let p = panel, let window = textView.window else { return }
        let insertionRange = textView.selectedRange()
        var actualRange = NSRange()
        let screenRect = textView.firstRect(forCharacterRange: insertionRange, actualRange: &actualRange)
        guard screenRect.origin.x.isFinite && screenRect.origin.y.isFinite else { return }

        let fittingSize = p.contentView?.fittingSize ?? NSSize(width: 220, height: 120)
        let panelWidth = max(190, min(fittingSize.width, 360))
        let panelHeight = max(30, min(fittingSize.height, 260))

        let screenFrame = window.screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        var posX = screenRect.origin.x
        if posX + panelWidth > screenFrame.maxX - 10 {
            posX = screenFrame.maxX - panelWidth - 10
        }
        if posX < screenFrame.minX + 10 {
            posX = screenFrame.minX + 10
        }

        var posY = screenRect.origin.y - panelHeight - 4
        if posY < screenFrame.minY + 10 {
            posY = screenRect.origin.y + screenRect.size.height + 4
        }

        p.setFrame(NSRect(x: posX, y: posY, width: panelWidth, height: panelHeight), display: true)
    }

    public func selectNext() {
        state.selectNext()
        if let tv = currentTextView {
            updatePosition(for: tv)
        }
    }

    public func selectPrevious() {
        state.selectPrevious()
        if let tv = currentTextView {
            updatePosition(for: tv)
        }
    }

    public func commitSelected() {
        state.commitSelected()
    }

    public func dismiss() {
        if let p = panel {
            if let parent = p.parent {
                parent.removeChildWindow(p)
            }
            p.orderOut(nil)
        }
        panel = nil
        currentTextView = nil
    }
}
