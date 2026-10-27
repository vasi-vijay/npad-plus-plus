import Foundation
import AppKit

public struct TokenStyle {
    public let foregroundColor: NSColor
    public let isBold: Bool
    public let isItalic: Bool

    public init(foregroundColor: NSColor, isBold: Bool = false, isItalic: Bool = false) {
        self.foregroundColor = foregroundColor
        self.isBold = isBold
        self.isItalic = isItalic
    }
}

public struct LanguageAlphabetGroup: Identifiable {
    public var id: String { letter }
    public let letter: String
    public let languages: [String]

    public init(letter: String, languages: [String]) {
        self.letter = letter
        self.languages = languages.sorted()
    }
}

// MARK: - Editor Color Theme Model
public struct EditorTheme: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let isDark: Bool
    public let backgroundColor: NSColor
    public let textColor: NSColor
    public let cursorColor: NSColor
    public let selectionColor: NSColor
    public let currentLineColor: NSColor
    public let gutterBackgroundColor: NSColor
    public let gutterTextColor: NSColor
    public let keywordColor: NSColor
    public let typeColor: NSColor
    public let stringColor: NSColor
    public let numberColor: NSColor
    public let commentColor: NSColor
    public let annotationColor: NSColor
    public let keyColor: NSColor
    public let tagColor: NSColor
    public let operatorColor: NSColor

    public init(
        id: String,
        name: String,
        isDark: Bool,
        backgroundColor: NSColor,
        textColor: NSColor,
        cursorColor: NSColor,
        selectionColor: NSColor,
        currentLineColor: NSColor,
        gutterBackgroundColor: NSColor,
        gutterTextColor: NSColor,
        keywordColor: NSColor,
        typeColor: NSColor,
        stringColor: NSColor,
        numberColor: NSColor,
        commentColor: NSColor,
        annotationColor: NSColor,
        keyColor: NSColor,
        tagColor: NSColor,
        operatorColor: NSColor
    ) {
        self.id = id
        self.name = name
        self.isDark = isDark
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.cursorColor = cursorColor
        self.selectionColor = selectionColor
        self.currentLineColor = currentLineColor
        self.gutterBackgroundColor = gutterBackgroundColor
        self.gutterTextColor = gutterTextColor
        self.keywordColor = keywordColor
        self.typeColor = typeColor
        self.stringColor = stringColor
        self.numberColor = numberColor
        self.commentColor = commentColor
        self.annotationColor = annotationColor
        self.keyColor = keyColor
        self.tagColor = tagColor
        self.operatorColor = operatorColor
    }
}

// MARK: - Theme Manager
public enum ThemeManager {
    public static let npadClassic = EditorTheme(
        id: "npad_classic",
        name: "NPad++ Classic",
        isDark: false,
        backgroundColor: NSColor(calibratedWhite: 1.0, alpha: 1.0),
        textColor: NSColor(calibratedWhite: 0.10, alpha: 1.0),
        cursorColor: NSColor.black,
        selectionColor: NSColor(calibratedRed: 0.72, green: 0.85, blue: 1.0, alpha: 1.0),
        currentLineColor: NSColor(calibratedRed: 0.94, green: 0.97, blue: 1.0, alpha: 1.0),
        gutterBackgroundColor: NSColor(calibratedWhite: 0.95, alpha: 1.0),
        gutterTextColor: NSColor(calibratedWhite: 0.50, alpha: 1.0),
        keywordColor: NSColor(calibratedRed: 0.0, green: 0.0, blue: 0.90, alpha: 1.0),
        typeColor: NSColor(calibratedRed: 0.50, green: 0.0, blue: 0.50, alpha: 1.0),
        stringColor: NSColor(calibratedRed: 0.55, green: 0.0, blue: 0.0, alpha: 1.0),
        numberColor: NSColor(calibratedRed: 0.85, green: 0.40, blue: 0.0, alpha: 1.0),
        commentColor: NSColor(calibratedRed: 0.0, green: 0.50, blue: 0.0, alpha: 1.0),
        annotationColor: NSColor(calibratedRed: 0.80, green: 0.40, blue: 0.0, alpha: 1.0),
        keyColor: NSColor(calibratedRed: 0.18, green: 0.35, blue: 0.72, alpha: 1.0),
        tagColor: NSColor(calibratedRed: 0.70, green: 0.12, blue: 0.32, alpha: 1.0),
        operatorColor: NSColor(calibratedWhite: 0.25, alpha: 1.0)
    )

    public static let darkModern = EditorTheme(
        id: "dark_modern",
        name: "Dark Modern",
        isDark: true,
        backgroundColor: NSColor(calibratedWhite: 0.12, alpha: 1.0),
        textColor: NSColor(calibratedWhite: 0.92, alpha: 1.0),
        cursorColor: NSColor.white,
        selectionColor: NSColor(calibratedRed: 0.16, green: 0.32, blue: 0.55, alpha: 0.8),
        currentLineColor: NSColor(calibratedWhite: 0.16, alpha: 1.0),
        gutterBackgroundColor: NSColor(calibratedWhite: 0.14, alpha: 1.0),
        gutterTextColor: NSColor(calibratedWhite: 0.50, alpha: 1.0),
        keywordColor: NSColor(calibratedRed: 0.34, green: 0.61, blue: 0.84, alpha: 1.0),
        typeColor: NSColor(calibratedRed: 0.31, green: 0.79, blue: 0.69, alpha: 1.0),
        stringColor: NSColor(calibratedRed: 0.81, green: 0.57, blue: 0.47, alpha: 1.0),
        numberColor: NSColor(calibratedRed: 0.71, green: 0.81, blue: 0.66, alpha: 1.0),
        commentColor: NSColor(calibratedRed: 0.42, green: 0.60, blue: 0.33, alpha: 1.0),
        annotationColor: NSColor(calibratedRed: 0.86, green: 0.86, blue: 0.50, alpha: 1.0),
        keyColor: NSColor(calibratedRed: 0.61, green: 0.86, blue: 1.0, alpha: 1.0),
        tagColor: NSColor(calibratedRed: 0.87, green: 0.45, blue: 0.58, alpha: 1.0),
        operatorColor: NSColor(calibratedWhite: 0.85, alpha: 1.0)
    )

    public static let monokai = EditorTheme(
        id: "monokai",
        name: "Monokai",
        isDark: true,
        backgroundColor: NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.13, alpha: 1.0),
        textColor: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.95, alpha: 1.0),
        cursorColor: NSColor(calibratedRed: 0.97, green: 0.97, blue: 0.95, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.31, green: 0.31, blue: 0.28, alpha: 0.8),
        currentLineColor: NSColor(calibratedRed: 0.20, green: 0.21, blue: 0.18, alpha: 1.0),
        gutterBackgroundColor: NSColor(calibratedRed: 0.15, green: 0.16, blue: 0.13, alpha: 1.0),
        gutterTextColor: NSColor(calibratedRed: 0.55, green: 0.54, blue: 0.48, alpha: 1.0),
        keywordColor: NSColor(calibratedRed: 0.98, green: 0.15, blue: 0.45, alpha: 1.0),
        typeColor: NSColor(calibratedRed: 0.40, green: 0.85, blue: 0.94, alpha: 1.0),
        stringColor: NSColor(calibratedRed: 0.90, green: 0.86, blue: 0.45, alpha: 1.0),
        numberColor: NSColor(calibratedRed: 0.68, green: 0.51, blue: 1.0, alpha: 1.0),
        commentColor: NSColor(calibratedRed: 0.46, green: 0.44, blue: 0.37, alpha: 1.0),
        annotationColor: NSColor(calibratedRed: 0.98, green: 0.59, blue: 0.11, alpha: 1.0),
        keyColor: NSColor(calibratedRed: 0.68, green: 0.51, blue: 1.0, alpha: 1.0),
        tagColor: NSColor(calibratedRed: 0.98, green: 0.15, blue: 0.45, alpha: 1.0),
        operatorColor: NSColor(calibratedRed: 0.98, green: 0.15, blue: 0.45, alpha: 1.0)
    )

    public static let gitHub = EditorTheme(
        id: "github",
        name: "GitHub",
        isDark: false,
        backgroundColor: NSColor(calibratedWhite: 1.0, alpha: 1.0),
        textColor: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.18, alpha: 1.0),
        cursorColor: NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.18, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.79, green: 0.89, blue: 1.0, alpha: 0.7),
        currentLineColor: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
        gutterBackgroundColor: NSColor(calibratedRed: 0.96, green: 0.97, blue: 0.98, alpha: 1.0),
        gutterTextColor: NSColor(calibratedRed: 0.60, green: 0.65, blue: 0.70, alpha: 1.0),
        keywordColor: NSColor(calibratedRed: 0.84, green: 0.23, blue: 0.29, alpha: 1.0),
        typeColor: NSColor(calibratedRed: 0.0, green: 0.36, blue: 0.77, alpha: 1.0),
        stringColor: NSColor(calibratedRed: 0.01, green: 0.18, blue: 0.38, alpha: 1.0),
        numberColor: NSColor(calibratedRed: 0.0, green: 0.36, blue: 0.77, alpha: 1.0),
        commentColor: NSColor(calibratedRed: 0.42, green: 0.45, blue: 0.49, alpha: 1.0),
        annotationColor: NSColor(calibratedRed: 0.44, green: 0.22, blue: 0.78, alpha: 1.0),
        keyColor: NSColor(calibratedRed: 0.14, green: 0.44, blue: 0.85, alpha: 1.0),
        tagColor: NSColor(calibratedRed: 0.14, green: 0.53, blue: 0.33, alpha: 1.0),
        operatorColor: NSColor(calibratedRed: 0.84, green: 0.23, blue: 0.29, alpha: 1.0)
    )

    public static let solarizedLight = EditorTheme(
        id: "solarized_light",
        name: "Solarized Light",
        isDark: false,
        backgroundColor: NSColor(calibratedRed: 0.99, green: 0.96, blue: 0.89, alpha: 1.0),
        textColor: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
        cursorColor: NSColor(calibratedRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.93, green: 0.91, blue: 0.84, alpha: 1.0),
        currentLineColor: NSColor(calibratedRed: 0.95, green: 0.93, blue: 0.85, alpha: 1.0),
        gutterBackgroundColor: NSColor(calibratedRed: 0.93, green: 0.91, blue: 0.84, alpha: 1.0),
        gutterTextColor: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),
        keywordColor: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.0, alpha: 1.0),
        typeColor: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.0, alpha: 1.0),
        stringColor: NSColor(calibratedRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),
        numberColor: NSColor(calibratedRed: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),
        commentColor: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),
        annotationColor: NSColor(calibratedRed: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),
        keyColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
        tagColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
        operatorColor: NSColor(calibratedRed: 0.42, green: 0.44, blue: 0.77, alpha: 1.0)
    )

    public static let solarizedDark = EditorTheme(
        id: "solarized_dark",
        name: "Solarized Dark",
        isDark: true,
        backgroundColor: NSColor(calibratedRed: 0.0, green: 0.17, blue: 0.21, alpha: 1.0),
        textColor: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),
        cursorColor: NSColor(calibratedRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),
        selectionColor: NSColor(calibratedRed: 0.03, green: 0.21, blue: 0.26, alpha: 1.0),
        currentLineColor: NSColor(calibratedRed: 0.03, green: 0.21, blue: 0.26, alpha: 1.0),
        gutterBackgroundColor: NSColor(calibratedRed: 0.03, green: 0.21, blue: 0.26, alpha: 1.0),
        gutterTextColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),
        keywordColor: NSColor(calibratedRed: 0.52, green: 0.60, blue: 0.0, alpha: 1.0),
        typeColor: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.0, alpha: 1.0),
        stringColor: NSColor(calibratedRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),
        numberColor: NSColor(calibratedRed: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),
        commentColor: NSColor(calibratedRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),
        annotationColor: NSColor(calibratedRed: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),
        keyColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
        tagColor: NSColor(calibratedRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
        operatorColor: NSColor(calibratedRed: 0.42, green: 0.44, blue: 0.77, alpha: 1.0)
    )

    public static let allThemes: [EditorTheme] = [
        npadClassic,
        darkModern,
        monokai,
        gitHub,
        solarizedLight,
        solarizedDark
    ]

    public static let allThemeNames: [String] = allThemes.map { $0.name }

    public static func theme(named name: String, fallbackDark: Bool = false) -> EditorTheme {
        if let match = allThemes.first(where: { $0.name.lowercased() == name.lowercased() || $0.id == name.lowercased() }) {
            return match
        }
        return fallbackDark ? darkModern : npadClassic
    }
}

public final class SyntaxEngine {

    // MARK: - Language Groups (A-Z Dictionary Organization)
    public static let alphabeticalGroups: [LanguageAlphabetGroup] = [
        LanguageAlphabetGroup(letter: "A", languages: ["ActionScript", "Ada", "Assembly", "AutoIt"]),
        LanguageAlphabetGroup(letter: "B", languages: ["Bash", "Batch"]),
        LanguageAlphabetGroup(letter: "C", languages: ["C", "C#", "C++", "CMake", "CSS", "CSV", "CoffeeScript"]),
        LanguageAlphabetGroup(letter: "D", languages: ["D", "Dart", "Diff", "Dockerfile"]),
        LanguageAlphabetGroup(letter: "E", languages: ["Elixir", "Erlang"]),
        LanguageAlphabetGroup(letter: "F", languages: ["F#", "Fortran"]),
        LanguageAlphabetGroup(letter: "G", languages: ["Go", "Gradle", "GraphQL", "Groovy"]),
        LanguageAlphabetGroup(letter: "H", languages: ["Haskell", "HTML"]),
        LanguageAlphabetGroup(letter: "I", languages: ["Ignore", "INI"]),
        LanguageAlphabetGroup(letter: "J", languages: ["Java", "JavaScript", "JSON", "Julia"]),
        LanguageAlphabetGroup(letter: "K", languages: ["Kotlin"]),
        LanguageAlphabetGroup(letter: "L", languages: ["LaTeX", "Lisp", "Log", "Lua"]),
        LanguageAlphabetGroup(letter: "M", languages: ["Makefile", "Markdown", "MATLAB"]),
        LanguageAlphabetGroup(letter: "N", languages: ["Nim"]),
        LanguageAlphabetGroup(letter: "O", languages: ["Objective-C", "OCaml"]),
        LanguageAlphabetGroup(letter: "P", languages: ["Pascal", "Perl", "PHP", "PowerShell", "Properties", "Protobuf", "Python"]),
        LanguageAlphabetGroup(letter: "R", languages: ["R", "Ruby", "Rust"]),
        LanguageAlphabetGroup(letter: "S", languages: ["Sass", "Scala", "Shell", "SQL", "Swift"]),
        LanguageAlphabetGroup(letter: "T", languages: ["TCL", "Terraform", "TeX", "TOML", "TypeScript"]),
        LanguageAlphabetGroup(letter: "V", languages: ["Verilog", "VHDL", "Visual Basic"]),
        LanguageAlphabetGroup(letter: "X", languages: ["XML"]),
        LanguageAlphabetGroup(letter: "Y", languages: ["YAML"]),
        LanguageAlphabetGroup(letter: "Z", languages: ["Zig"])
    ]

    // MARK: - Supported Languages List
    public static let supportedLanguages: [String] = {
        var all = alphabeticalGroups.flatMap { $0.languages }
        if !all.contains("Plain Text") {
            all.append("Plain Text")
        }
        return all
    }()

    // MARK: - Language Detection
    public static func detectLanguage(from filename: String, content: String = "") -> String {
        FileTypeRegistry.language(forFilename: filename, content: content)
    }

    /// Comment syntax used by Toggle Comment. `close` is nil for languages with line comments.
    public static func commentDelimiters(for language: String) -> (open: String, close: String?) {
        switch canonicalLanguage(language) {
        case "python", "shell", "properties", "yaml", "toml", "ruby", "perl", "powershell", "r", "julia",
             "elixir", "dockerfile", "makefile", "cmake", "ignore", "terraform", "nim", "coffeescript", "csv":
            return ("# ", nil)
        case "ini", "lisp", "assembly", "autoit":
            return ("; ", nil)
        case "sql", "lua", "haskell", "ada", "vhdl":
            return ("-- ", nil)
        case "latex", "erlang", "matlab":
            return ("% ", nil)
        case "batch":
            return ("REM ", nil)
        case "visual basic":
            return ("' ", nil)
        case "html", "xml":
            return ("<!-- ", " -->")
        case "css":
            return ("/* ", " */")
        default:
            return ("// ", nil)
        }
    }

    /// Normalises user-facing language names (menu entries, aliases) to the key the highlighter uses.
    static func canonicalLanguage(_ language: String) -> String {
        let lang = language.lowercased()
        switch lang {
        case "bash": return "shell"
        case "tex": return "latex"
        case "yml": return "yaml"
        case "vb": return "visual basic"
        default: return lang
        }
    }

    // MARK: - Authoritative Font Resolver
    public static func resolveFont(family: String, size: CGFloat, bold: Bool = false) -> NSFont {
        let fontManager = NSFontManager.shared
        let traits: NSFontTraitMask = bold ? .boldFontMask : .unboldFontMask

        // 1. First attempt: NSFontManager with family and traits
        if let font = fontManager.font(withFamily: family, traits: traits, weight: bold ? 9 : 5, size: size) {
            return font
        }

        // 2. Second attempt: Check available members of the font family
        if let members = fontManager.availableMembers(ofFontFamily: family) {
            for member in members {
                if let psName = member[0] as? String {
                    if bold && (psName.localizedCaseInsensitiveContains("bold") || psName.localizedCaseInsensitiveContains("semibold")) {
                        if let f = NSFont(name: psName, size: size) { return f }
                    } else if !bold && (psName.localizedCaseInsensitiveContains("regular") || psName.localizedCaseInsensitiveContains("roman")) {
                        if let f = NSFont(name: psName, size: size) { return f }
                    }
                }
            }
            if let first = members.first, let psName = first[0] as? String, let f = NSFont(name: psName, size: size) {
                return bold ? (fontManager.convert(f, toHaveTrait: .boldFontMask)) : f
            }
        }

        // 3. Third attempt: Common PostScript name mappings
        let postScriptMap: [String: String] = [
            "SF Mono": bold ? "SFMono-Bold" : "SFMono-Regular",
            "Menlo": bold ? "Menlo-Bold" : "Menlo-Regular",
            "Courier New": bold ? "CourierNewPS-BoldMT" : "CourierNewPSMT",
            "Courier": bold ? "Courier-Bold" : "Courier",
            "Monaco": "Monaco",
            "JetBrains Mono": bold ? "JetBrainsMono-Bold" : "JetBrainsMono-Regular",
            "Fira Code": bold ? "FiraCode-Bold" : "FiraCode-Regular",
            "Source Code Pro": bold ? "SourceCodePro-Bold" : "SourceCodePro-Regular",
            "PT Mono": bold ? "PTMono-Bold" : "PTMono-Regular",
            "Andale Mono": "AndaleMono"
        ]
        if let ps = postScriptMap[family], let f = NSFont(name: ps, size: size) {
            return f
        }

        // 4. Fourth attempt: Direct name lookup
        if let direct = NSFont(name: family, size: size) {
            return bold ? fontManager.convert(direct, toHaveTrait: .boldFontMask) : direct
        }

        // 5. System Monospaced fallback (never fails on macOS)
        return NSFont.monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    // MARK: - Syntax Highlighting Application
    public static func highlight(
        storage: NSTextStorage,
        language: String,
        baseFont: NSFont,
        isDark: Bool = false,
        theme: EditorTheme? = nil,
        syntaxEnabled: Bool = true
    ) {
        let length = storage.length
        guard length > 0 else { return }

        let fullRange = NSRange(location: 0, length: length)
        let text = storage.string

        let activeTheme = theme ?? (isDark ? ThemeManager.darkModern : ThemeManager.npadClassic)
        let defaultTextColor = activeTheme.textColor

        storage.beginEditing()

        // 1. Reset base font and base foreground color across entire document
        storage.setAttributes([
            .font: baseFont,
            .foregroundColor: defaultTextColor
        ], range: fullRange)

        let lang = canonicalLanguage(language)
        if lang == "plain text" || length > 150_000 || !syntaxEnabled {
            storage.endEditing()
            return
        }

        // Active Theme Color Palette
        let keywordColor = activeTheme.keywordColor
        let typeColor = activeTheme.typeColor
        let stringColor = activeTheme.stringColor
        let numberColor = activeTheme.numberColor
        let commentColor = activeTheme.commentColor
        let annotationColor = activeTheme.annotationColor
        let keyColor = activeTheme.keyColor
        let tagColor = activeTheme.tagColor

        let boldFont = resolveFont(family: baseFont.familyName ?? baseFont.fontName, size: baseFont.pointSize, bold: true)

        // Helper regex applier
        func applyRegex(_ pattern: String, options: NSRegularExpression.Options = [], color: NSColor, font: NSFont? = nil) {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for m in matches {
                storage.addAttribute(.foregroundColor, value: color, range: m.range)
                if let f = font {
                    storage.addAttribute(.font, value: f, range: m.range)
                }
            }
        }

        // Single left-to-right pass over strings and comments so that a comment marker inside a string
        // (e.g. "http://host") or a quote inside a comment is never mis-coloured.
        // Patterns passed in must use non-capturing groups: each alternative is exactly one capture group.
        func applyLiteralsAndComments(
            lineComment: String?,
            block: Bool = false,
            triple: Bool = false,
            singleQuote: SingleQuoteMode = .string,
            backtick: Bool = false,
            colorStrings: Bool = true
        ) {
            var alternatives: [(pattern: String, isComment: Bool)] = []
            if block { alternatives.append(("/\\*[\\s\\S]*?(?:\\*/|\\z)", true)) }
            if triple { alternatives.append(("\"\"\"[\\s\\S]*?(?:\"\"\"|\\z)|'''[\\s\\S]*?(?:'''|\\z)", false)) }
            if let line = lineComment { alternatives.append((line, true)) }
            alternatives.append(("\"(?:\\\\.|[^\"\\\\\\n])*\"", false))
            switch singleQuote {
            case .string: alternatives.append(("'(?:\\\\.|[^'\\\\\\n])*'", false))
            case .charOnly: alternatives.append(("'(?:\\\\.[^'\\n]*|[^'\\\\\\n])'", false))
            case .none: break
            }
            if backtick { alternatives.append(("`(?:\\\\.|[^`\\\\])*`", false)) }

            let combined = alternatives.map { "(" + $0.pattern + ")" }.joined(separator: "|")
            guard let regex = try? NSRegularExpression(pattern: combined, options: [.anchorsMatchLines]) else { return }
            for m in regex.matches(in: text, options: [], range: fullRange) {
                for (index, alt) in alternatives.enumerated() {
                    let r = m.range(at: index + 1)
                    guard r.location != NSNotFound else { continue }
                    if alt.isComment || colorStrings {
                        storage.addAttribute(.foregroundColor, value: alt.isComment ? commentColor : stringColor, range: r)
                        storage.addAttribute(.font, value: baseFont, range: r)
                    }
                    break
                }
            }
        }

        let hashComment = "#[^\\n]*"
        let lineStartComment = "^[ \\t]*[#;][^\\n]*"

        // Language-specific rules
        switch lang {
        case "json":
            // JSON property keys: "key":
            applyRegex("\"(\\\\.|[^\"])*\"(?=\\s*:)", color: keyColor, font: boldFont)
            // JSON string values
            applyRegex("(?<=:\\s*)\"(\\\\.|[^\"])*\"", color: stringColor)
            // Numbers
            applyRegex("\\b-?\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", color: numberColor)
            // Booleans & null
            applyRegex("\\b(true|false|null)\\b", color: keywordColor, font: boldFont)
            // JSONC comments (strings are skipped over, not recolored)
            applyLiteralsAndComments(lineComment: "//[^\\n]*", block: true, singleQuote: .none, colorStrings: false)

        case "xml", "html":
            // Tags: <tag ... >
            applyRegex("</?[A-Za-z0-9_:-]+", color: tagColor, font: boldFont)
            applyRegex("/?>", color: tagColor, font: boldFont)
            // Attribute names: attr=
            applyRegex("\\b[A-Za-z0-9_:@.-]+(?=\\=)", color: keyColor)
            // Attribute values: "value"
            applyRegex("\"(\\\\.|[^\"])*\"|'(\\\\.|[^'])*'", color: stringColor)
            // Entities: &amp;
            applyRegex("&[A-Za-z0-9#]+;", color: annotationColor)
            // XML/HTML comments: <!-- ... -->
            applyRegex("<!--[\\s\\S]*?(?:-->|\\z)", color: commentColor)

        case "css":
            // Selectors / classes / ids
            applyRegex("(^|\\n)\\s*([.#]?[A-Za-z0-9_:-]+)+", color: tagColor, font: boldFont)
            // Properties: prop:
            applyRegex("[A-Za-z0-9_-]+(?=\\s*:)", color: keyColor)
            // Colors: #fff
            applyRegex("#[A-Fa-f0-9]{3,8}\\b", color: annotationColor)
            // Numbers & units: 12px, 1.5em
            applyRegex("\\b\\d+(\\.\\d+)?(px|em|rem|%|vh|vw|pt|s|ms)?\\b", color: numberColor)
            applyLiteralsAndComments(lineComment: nil, block: true)

        case "sql":
            let sqlKeywords = [
                "SELECT", "FROM", "WHERE", "INSERT", "INTO", "VALUES", "UPDATE", "SET",
                "DELETE", "CREATE", "TABLE", "ALTER", "DROP", "INDEX", "VIEW", "JOIN",
                "INNER", "LEFT", "RIGHT", "FULL", "OUTER", "CROSS", "ON", "GROUP", "BY",
                "ORDER", "ASC", "DESC", "HAVING", "LIMIT", "OFFSET", "UNION", "ALL",
                "DISTINCT", "AS", "AND", "OR", "NOT", "IN", "BETWEEN", "LIKE", "IS",
                "NULL", "TRUE", "FALSE", "CASE", "WHEN", "THEN", "ELSE", "END",
                "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "CONSTRAINT", "CHECK", "DEFAULT",
                "BEGIN", "COMMIT", "ROLLBACK", "TRANSACTION", "COUNT", "SUM", "AVG", "MIN", "MAX"
            ]
            let sqlPattern = "\\b(" + sqlKeywords.joined(separator: "|") + ")\\b"
            applyRegex(sqlPattern, options: [.caseInsensitive], color: keywordColor, font: boldFont)

            let sqlTypes = ["INT", "INTEGER", "BIGINT", "SMALLINT", "VARCHAR", "CHAR", "TEXT", "BOOLEAN", "DATE", "TIMESTAMP", "DECIMAL", "NUMERIC", "FLOAT", "DOUBLE", "UUID", "JSON", "JSONB", "BLOB"]
            applyRegex("\\b(" + sqlTypes.joined(separator: "|") + ")\\b", options: [.caseInsensitive], color: typeColor)

            applyRegex("\\b\\d+(\\.\\d+)?\\b", color: numberColor)
            applyLiteralsAndComments(lineComment: "--[^\\n]*", block: true)

        case "markdown":
            // Headers: # Header
            applyRegex("^#{1,6}\\s.*$", options: [.anchorsMatchLines], color: tagColor, font: boldFont)
            // Bold: **text**
            applyRegex("\\*\\*[^*\\n]+\\*\\*", color: keywordColor, font: boldFont)
            // List markers
            applyRegex("^\\s*([-*+]|\\d+\\.)\\s", options: [.anchorsMatchLines], color: numberColor)
            // Code block: ```
            applyRegex("```[\\s\\S]*?(?:```|\\z)", color: stringColor)
            // Inline code: `code`
            applyRegex("`[^`\n]+`", color: annotationColor)
            // Links: [text](url)
            applyRegex("\\[[^\\]]+\\]\\([^\\)]+\\)", color: keywordColor)
            // Blockquotes: > quote
            applyRegex("^>\\s.*$", options: [.anchorsMatchLines], color: commentColor)

        case "log":
            applyRegex("\\[?(ERROR|FATAL|SEVERE)\\]?", options: [.caseInsensitive], color: NSColor.systemRed, font: boldFont)
            applyRegex("\\[?(WARN|WARNING)\\]?", options: [.caseInsensitive], color: NSColor.systemOrange, font: boldFont)
            applyRegex("\\[?(INFO|NOTICE)\\]?", options: [.caseInsensitive], color: NSColor.systemGreen, font: boldFont)
            applyRegex("\\[?(DEBUG|TRACE)\\]?", options: [.caseInsensitive], color: NSColor.systemBlue)
            applyRegex("\\d{4}-\\d{2}-\\d{2}[T ]\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?", color: commentColor)

        case "yaml":
            applyRegex("^(---|\\.\\.\\.)[ \\t]*$", options: [.anchorsMatchLines], color: tagColor, font: boldFont)
            applyRegex("^[ \\t]*(?:-[ \\t]+)*(?:\"[^\"\\n]*\"|'[^'\\n]*'|[A-Za-z0-9_.\\-/$]+)(?=[ \\t]*:(?:[ \\t]|$))", options: [.anchorsMatchLines], color: keyColor, font: boldFont)
            applyRegex("[&*][A-Za-z0-9_-]+|!![A-Za-z]+", color: annotationColor)
            applyRegex("\\b(true|false|null|yes|no|on|off|True|False|Null)\\b", color: keywordColor)
            applyRegex("(?<![\\w.])-?\\d+(\\.\\d+)?([eE][+-]?\\d+)?(?![\\w.])", color: numberColor)
            applyLiteralsAndComments(lineComment: "(?:^|(?<=[ \\t]))#[^\\n]*")

        case "toml":
            applyRegex("^[ \\t]*\\[\\[?[^\\]\\n]+\\]\\]?", options: [.anchorsMatchLines], color: tagColor, font: boldFont)
            applyRegex("^[ \\t]*(?:\"[^\"\\n]*\"|'[^'\\n]*'|[A-Za-z0-9_.\\-]+)(?=[ \\t]*=)", options: [.anchorsMatchLines], color: keyColor)
            applyRegex("\\b(true|false)\\b", color: keywordColor, font: boldFont)
            applyRegex("\\b\\d{4}-\\d{2}-\\d{2}([T ]\\d{2}:\\d{2}:\\d{2}(\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})?)?\\b", color: annotationColor)
            applyRegex("(?<![\\w.])[+-]?(0x[0-9a-fA-F_]+|\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?)(?![\\w.])", color: numberColor)
            applyLiteralsAndComments(lineComment: hashComment, triple: true)

        case "ini":
            applyRegex("^[ \\t]*\\[[^\\]\\n]+\\]", options: [.anchorsMatchLines], color: tagColor, font: boldFont)
            applyRegex("^[ \\t]*[A-Za-z0-9_.\\- ]+?(?=[ \\t]*[=:])", options: [.anchorsMatchLines], color: keyColor)
            applyRegex("\\b(true|false|yes|no|on|off)\\b", options: [.caseInsensitive], color: keywordColor)
            applyRegex("(?<![\\w.])-?\\d+(\\.\\d+)?(?![\\w.])", color: numberColor)
            applyLiteralsAndComments(lineComment: lineStartComment)

        case "properties":
            // KEY=value, .env files, `export KEY=value`
            applyRegex("^[ \\t]*(?:export[ \\t]+)?[A-Za-z0-9_.\\-\\[\\]]+(?=[ \\t]*[=:])", options: [.anchorsMatchLines], color: keyColor, font: boldFont)
            applyRegex("\\$\\{?[A-Za-z_][A-Za-z0-9_.]*\\}?", color: annotationColor)
            applyRegex("\\b(true|false)\\b", color: keywordColor)
            applyRegex("(?<![\\w.])-?\\d+(\\.\\d+)?(?![\\w.])", color: numberColor)
            applyLiteralsAndComments(lineComment: "(?:^|(?<=[ \\t]))[#!][^\\n]*")

        case "ignore":
            applyRegex("^!", options: [.anchorsMatchLines], color: keywordColor, font: boldFont)
            applyRegex("\\*+|\\?", color: annotationColor)
            applyRegex("/$", options: [.anchorsMatchLines], color: tagColor)
            applyLiteralsAndComments(lineComment: "^[ \\t]*#[^\\n]*", singleQuote: .none)

        case "csv":
            highlightDelimitedText(
                storage: storage, text: text,
                palette: [keywordColor, stringColor, numberColor, typeColor, annotationColor, tagColor],
                headerFont: boldFont
            )

        case "diff":
            applyRegex("^(diff |index |\\+\\+\\+ |--- ).*$", options: [.anchorsMatchLines], color: keywordColor, font: boldFont)
            applyRegex("^\\+(?!\\+\\+).*$", options: [.anchorsMatchLines], color: NSColor.systemGreen)
            applyRegex("^-(?!--).*$", options: [.anchorsMatchLines], color: NSColor.systemRed)
            applyRegex("^@@.*@@", options: [.anchorsMatchLines], color: tagColor, font: boldFont)

        case "dockerfile":
            let instructions = ["FROM", "RUN", "CMD", "LABEL", "EXPOSE", "ENV", "ADD", "COPY", "ENTRYPOINT", "VOLUME", "USER", "WORKDIR", "ARG", "ONBUILD", "STOPSIGNAL", "HEALTHCHECK", "SHELL", "MAINTAINER"]
            applyRegex("^[ \\t]*(" + instructions.joined(separator: "|") + ")\\b", options: [.anchorsMatchLines, .caseInsensitive], color: keywordColor, font: boldFont)
            applyRegex("\\bAS\\b", color: keywordColor)
            applyRegex("\\$\\{?[A-Za-z_][A-Za-z0-9_]*\\}?", color: annotationColor)
            applyRegex("\\b\\d+\\b", color: numberColor)
            applyLiteralsAndComments(lineComment: "^[ \\t]*#[^\\n]*")

        case "makefile":
            applyRegex("^[ \\t]*(ifeq|ifneq|ifdef|ifndef|else|endif|include|-include|sinclude|define|endef|export|unexport|override|vpath)\\b", options: [.anchorsMatchLines], color: keywordColor, font: boldFont)
            applyRegex("^[A-Za-z0-9_.%/\\-$()\\[\\] ]+(?=[ \\t]*::?(?!=))", options: [.anchorsMatchLines], color: tagColor, font: boldFont)
            applyRegex("^[ \\t]*[A-Za-z0-9_.]+(?=[ \\t]*[:+?!]?=)", options: [.anchorsMatchLines], color: keyColor)
            applyRegex("\\$[({][^)}\\n]+[)}]|\\$[@<^?*%+|]", color: annotationColor)
            applyLiteralsAndComments(lineComment: hashComment)

        case "batch":
            let batchKeywords = ["echo", "set", "if", "else", "goto", "call", "exit", "for", "in", "do", "rem", "setlocal", "endlocal", "pause", "cd", "dir", "copy", "move", "del", "mkdir", "rmdir", "start", "not", "exist", "errorlevel", "defined", "equ", "neq", "lss", "leq", "gtr", "geq", "shift", "title", "cls"]
            applyRegex("\\b(" + batchKeywords.joined(separator: "|") + ")\\b", options: [.caseInsensitive], color: keywordColor, font: boldFont)
            applyRegex("^[ \\t]*:[A-Za-z0-9_]+", options: [.anchorsMatchLines], color: tagColor, font: boldFont)
            applyRegex("%[A-Za-z0-9_~:*]+%?|%%[A-Za-z]|![A-Za-z0-9_]+!", color: annotationColor)
            applyRegex("\\b\\d+\\b", color: numberColor)
            applyLiteralsAndComments(lineComment: "(?i:^[ \\t]*(?:rem\\b|::))[^\\n]*", singleQuote: .none)

        default:
            // Keyword-driven languages: Java, Swift, Python, Go, Rust, Kotlin, C-family, scripting languages
            let caseInsensitiveLanguages: Set<String> = ["pascal", "ada", "vhdl", "fortran", "visual basic", "cmake"]
            let keywordOptions: NSRegularExpression.Options = caseInsensitiveLanguages.contains(lang) ? [.caseInsensitive] : []

            let keywords = getKeywords(for: lang)
            if !keywords.isEmpty {
                let kwPattern = "(?<![\\w$])(" + keywords.map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "|") + ")(?![\\w$])"
                applyRegex(kwPattern, options: keywordOptions, color: keywordColor, font: boldFont)
            }

            let types = getCommonTypes(for: lang)
            if !types.isEmpty {
                let typePattern = "\\b(" + types.joined(separator: "|") + ")\\b"
                applyRegex(typePattern, color: typeColor, font: boldFont)
            }

            // Preprocessor directives: #include, #define, #region
            if ["c", "c++", "objective-c", "c#"].contains(lang) {
                applyRegex("^[ \\t]*#[ \\t]*[a-z]+", options: [.anchorsMatchLines], color: annotationColor, font: boldFont)
            }

            // Variables: $name / ${name}
            if ["shell", "powershell", "php", "perl", "terraform", "cmake"].contains(lang) {
                applyRegex("\\$\\{?[A-Za-z_][A-Za-z0-9_:]*\\}?|\\$[0-9@#?*!$-]", color: annotationColor)
            }

            // Annotations / Decorators: @Annotation
            if !["shell", "powershell", "php", "perl", "r", "lisp", "latex", "matlab", "assembly"].contains(lang) {
                applyRegex("@[A-Za-z_][A-Za-z0-9_.]*", color: annotationColor, font: boldFont)
            }

            // Numbers: hex, binary, float, integer
            applyRegex("\\b(0x[0-9a-fA-F_]+|0b[01_]+|\\d[\\d_]*(\\.\\d+)?([eE][+-]?\\d+)?)[fFlLuU]*\\b", color: numberColor)

            // Strings and comments (applied last so they win over keywords/numbers inside them)
            let slashComment = "//[^\\n]*"
            let lineComment: String
            switch lang {
            case "python", "shell", "ruby", "perl", "powershell", "r", "julia", "elixir", "nim", "coffeescript", "cmake", "graphql":
                lineComment = hashComment
            case "terraform":
                lineComment = "(?:#|//)[^\\n]*"
            case "php":
                lineComment = "(?://|#(?!\\[))[^\\n]*"
            case "lua", "haskell", "ada", "vhdl":
                lineComment = "--[^\\n]*"
            case "lisp", "assembly", "autoit":
                lineComment = ";[^\\n]*"
            case "latex", "erlang", "matlab":
                lineComment = "%[^\\n]*"
            case "visual basic":
                lineComment = "(?i:'|\\brem\\b)[^\\n]*"
            case "fortran":
                lineComment = "![^\\n]*"
            default:
                lineComment = slashComment
            }

            let singleQuote: SingleQuoteMode
            switch lang {
            case "rust", "ocaml", "haskell", "f#": singleQuote = .charOnly
            case "lisp", "ada", "visual basic", "latex", "matlab", "erlang", "vhdl": singleQuote = .none
            default: singleQuote = .string
            }

            let tripleQuoteLanguages: Set<String> = ["python", "java", "kotlin", "swift", "scala", "groovy", "c#", "julia", "dart", "coffeescript"]
            let backtickLanguages: Set<String> = ["javascript", "typescript", "go", "shell", "coffeescript", "dart"]

            applyLiteralsAndComments(
                lineComment: lineComment,
                block: lineComment == slashComment || lang == "php" || lang == "terraform",
                triple: tripleQuoteLanguages.contains(lang),
                singleQuote: singleQuote,
                backtick: backtickLanguages.contains(lang)
            )
        }

        storage.endEditing()
    }

    private enum SingleQuoteMode {
        case string
        case charOnly
        case none
    }

    /// Rainbow-column highlighting for CSV/TSV with a bold header row. Quote-aware, single pass.
    private static func highlightDelimitedText(storage: NSTextStorage, text: String, palette: [NSColor], headerFont: NSFont) {
        let ns = text as NSString
        let length = ns.length
        guard length > 0, !palette.isEmpty else { return }

        let firstNewline = ns.range(of: "\n").location
        let headEnd = min(firstNewline == NSNotFound ? length : firstNewline, 4096)
        let head = ns.substring(to: headEnd)
        let candidates: [(Character, unichar)] = [(",", 44), (";", 59), ("\t", 9), ("|", 124)]
        let delimiter = candidates.max(by: { lhs, rhs in
            head.filter({ $0 == lhs.0 }).count < head.filter({ $0 == rhs.0 }).count
        })?.1 ?? 44

        var column = 0
        var fieldStart = 0
        var inQuotes = false
        var inHeader = true

        func flush(_ end: Int) {
            guard end > fieldStart else { return }
            let range = NSRange(location: fieldStart, length: end - fieldStart)
            storage.addAttribute(.foregroundColor, value: palette[column % palette.count], range: range)
            if inHeader { storage.addAttribute(.font, value: headerFont, range: range) }
        }

        for i in 0..<length {
            let c = ns.character(at: i)
            if c == 34 {
                inQuotes.toggle()
            } else if !inQuotes {
                if c == delimiter {
                    flush(i)
                    column += 1
                    fieldStart = i + 1
                } else if c == 10 || c == 13 {
                    flush(i)
                    column = 0
                    fieldStart = i + 1
                    inHeader = false
                }
            }
        }
        flush(length)
    }

    private static func getKeywords(for lang: String) -> [String] {
        switch lang {
        case "ruby":
            return ["def", "class", "module", "end", "if", "elsif", "else", "unless", "while", "until", "for", "in", "do", "begin", "rescue", "ensure", "raise", "return", "yield", "self", "nil", "true", "false", "require", "require_relative", "include", "extend", "attr_accessor", "attr_reader", "attr_writer"]
        case "php":
            return ["function", "class", "interface", "extends", "implements", "public", "private", "protected", "static", "return", "if", "else", "elseif", "while", "do", "for", "foreach", "as", "try", "catch", "finally", "throw", "new", "echo", "print", "null", "true", "false", "namespace", "use", "final", "const"]
        case "dart":
            return ["void", "int", "double", "String", "bool", "var", "final", "const", "class", "extends", "implements", "with", "abstract", "import", "export", "as", "show", "hide", "return", "if", "else", "for", "while", "do", "switch", "case", "break", "continue", "try", "catch", "finally", "throw", "rethrow", "async", "await", "yield"]
        case "lua":
            return ["function", "end", "if", "then", "elseif", "else", "while", "do", "repeat", "until", "for", "in", "return", "break", "local", "nil", "true", "false", "and", "or", "not"]
        case "perl":
            return ["sub", "my", "our", "local", "if", "unless", "elsif", "else", "while", "until", "for", "foreach", "do", "return", "package", "use", "require", "strict", "warnings", "print", "die", "warn"]
        case "powershell":
            return ["function", "filter", "param", "if", "else", "elseif", "switch", "foreach", "for", "while", "do", "until", "break", "continue", "return", "exit", "throw", "try", "catch", "finally", "trap", "data"]
        case "r":
            return ["function", "if", "else", "repeat", "while", "for", "in", "next", "break", "TRUE", "FALSE", "NULL", "Inf", "NaN", "NA", "return"]
        case "julia":
            return ["function", "end", "macro", "module", "using", "import", "export", "if", "elseif", "else", "for", "while", "break", "continue", "return", "try", "catch", "finally", "struct", "mutable", "const", "true", "false"]
        case "zig":
            return ["fn", "const", "var", "pub", "return", "if", "else", "while", "for", "switch", "break", "continue", "defer", "errdefer", "try", "catch", "unreachable", "struct", "enum", "union", "error", "test", "import"]
        case "scala":
            return ["def", "val", "var", "class", "object", "trait", "extends", "with", "package", "import", "return", "if", "else", "match", "case", "for", "while", "do", "try", "catch", "finally", "throw", "new", "this", "super", "null", "true", "false", "type", "implicit", "lazy", "sealed", "override", "final"]
        case "objective-c":
            return ["@interface", "@implementation", "@end", "@property", "@synthesize", "@dynamic", "@protocol", "@optional", "@required", "@class", "@public", "@protected", "@private", "self", "super", "id", "instancetype", "SEL", "BOOL", "YES", "NO", "nil", "Nil", "NULL"]
        case "java":
            return [
                "public", "private", "protected", "static", "final", "class", "interface",
                "record", "enum", "extends", "implements", "return", "void", "new", "import",
                "package", "if", "else", "for", "while", "do", "try", "catch", "finally",
                "throw", "throws", "this", "super", "null", "true", "false", "boolean",
                "int", "long", "double", "float", "char", "byte", "short", "var", "switch", "case",
                "break", "continue", "default", "instanceof", "synchronized", "transient", "volatile",
                "abstract", "native", "strictfp", "assert", "yield", "sealed", "permits", "non-sealed"
            ]
        case "kotlin":
            return [
                "package", "import", "class", "interface", "fun", "val", "var", "is", "in",
                "return", "if", "else", "when", "for", "while", "do", "try", "catch", "finally",
                "throw", "this", "super", "null", "true", "false", "object", "companion", "data",
                "sealed", "override", "open", "private", "protected", "public", "internal",
                "suspend", "inline", "by", "lazy", "init", "typealias"
            ]
        case "swift":
            return [
                "import", "struct", "class", "enum", "protocol", "extension", "func", "var",
                "let", "public", "private", "fileprivate", "internal", "open", "static",
                "return", "some", "any", "guard", "if", "else", "for", "in", "while", "switch",
                "case", "default", "self", "Self", "init", "deinit", "mutating", "async", "await",
                "throws", "rethrows", "try", "catch", "throw", "defer", "break", "continue", "fallthrough",
                "typealias", "associatedtype", "where", "dynamic", "weak", "unowned", "actor"
            ]
        case "typescript", "javascript":
            return [
                "function", "const", "let", "var", "import", "export", "from", "default", "class",
                "interface", "type", "return", "if", "else", "for", "while", "do", "switch", "case",
                "new", "this", "async", "await", "try", "catch", "finally", "throw", "null", "undefined",
                "true", "false", "typeof", "instanceof", "in", "of", "break", "continue", "debugger",
                "extends", "implements", "super", "static", "public", "private", "protected", "readonly",
                "as", "is", "keyof", "enum", "void", "yield"
            ]
        case "python":
            return [
                "def", "class", "import", "from", "as", "return", "if", "elif", "else",
                "for", "while", "try", "except", "finally", "raise", "with", "self", "None",
                "True", "False", "lambda", "yield", "pass", "break", "continue", "global",
                "nonlocal", "assert", "del", "async", "await", "match", "case"
            ]
        case "c", "c++":
            return [
                "auto", "break", "case", "char", "const", "continue", "default", "do",
                "double", "else", "enum", "extern", "float", "for", "goto", "if",
                "int", "long", "register", "return", "short", "signed", "sizeof", "static",
                "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while",
                "class", "namespace", "public", "private", "protected", "template", "typename",
                "this", "friend", "virtual", "inline", "explicit", "export", "bool", "true", "false",
                "new", "delete", "operator", "try", "catch", "throw", "nullptr", "constexpr",
                "override", "final", "decltype", "noexcept", "static_assert"
            ]
        case "c#":
            return [
                "abstract", "as", "base", "bool", "break", "byte", "case", "catch", "char",
                "checked", "class", "const", "continue", "decimal", "default", "delegate", "do",
                "double", "else", "enum", "event", "explicit", "extern", "false", "finally",
                "fixed", "float", "for", "foreach", "goto", "if", "implicit", "in", "int",
                "interface", "internal", "is", "lock", "long", "namespace", "new", "null",
                "object", "operator", "out", "override", "params", "private", "protected",
                "public", "readonly", "ref", "return", "sbyte", "sealed", "short", "sizeof",
                "stackalloc", "static", "string", "struct", "switch", "this", "throw", "true",
                "try", "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using",
                "virtual", "void", "volatile", "while", "async", "await", "var", "record"
            ]
        case "go":
            return [
                "break", "default", "func", "interface", "select", "case", "defer", "go",
                "map", "struct", "chan", "else", "goto", "package", "switch", "const",
                "fallthrough", "if", "range", "type", "continue", "for", "import", "return", "var",
                "nil", "true", "false", "iota"
            ]
        case "rust":
            return [
                "as", "break", "const", "continue", "crate", "else", "enum", "extern", "false",
                "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut",
                "pub", "ref", "return", "self", "Self", "static", "struct", "super", "trait",
                "true", "type", "unsafe", "use", "where", "while", "async", "await", "dyn"
            ]
        case "shell":
            return [
                "if", "then", "else", "elif", "fi", "case", "esac", "for", "while", "until",
                "do", "done", "in", "function", "select", "time", "return", "exit", "echo",
                "export", "local", "set", "unset", "source", "alias"
            ]
        case "gradle":
            return [
                "plugins", "id", "version", "apply", "dependencies", "implementation",
                "testImplementation", "runtimeOnly", "compileOnly", "repositories",
                "mavenCentral", "google", "gradlePluginPortal", "group", "task", "def"
            ]
        case "terraform":
            return ["resource", "data", "variable", "output", "module", "provider", "locals", "terraform", "for_each", "count", "dynamic", "depends_on", "lifecycle", "provisioner", "backend", "true", "false", "null", "for", "in", "if"]
        case "protobuf":
            return ["syntax", "package", "import", "option", "message", "enum", "service", "rpc", "returns", "repeated", "optional", "required", "oneof", "map", "reserved", "extend", "extensions", "stream", "public", "weak", "true", "false"]
        case "graphql":
            return ["query", "mutation", "subscription", "fragment", "on", "type", "interface", "union", "enum", "input", "scalar", "schema", "extend", "implements", "directive", "repeatable", "true", "false", "null"]
        case "cmake":
            return ["cmake_minimum_required", "project", "add_executable", "add_library", "add_subdirectory", "target_link_libraries", "target_include_directories", "target_compile_definitions", "target_compile_options", "set", "unset", "if", "elseif", "else", "endif", "foreach", "endforeach", "while", "endwhile", "function", "endfunction", "macro", "endmacro", "include", "find_package", "option", "message", "install", "file", "list", "string", "return", "configure_file", "add_custom_command", "add_custom_target", "add_definitions", "include_directories", "link_directories"]
        case "groovy":
            return ["def", "class", "interface", "trait", "enum", "extends", "implements", "import", "package", "return", "if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "try", "catch", "finally", "throw", "new", "this", "super", "null", "true", "false", "static", "final", "public", "private", "protected", "in", "as", "instanceof", "pipeline", "stage", "steps", "node", "agent"]
        case "haskell":
            return ["module", "import", "qualified", "as", "hiding", "where", "let", "in", "if", "then", "else", "case", "of", "do", "data", "type", "newtype", "class", "instance", "deriving", "infixl", "infixr", "infix", "default", "foreign"]
        case "elixir":
            return ["def", "defp", "defmodule", "defmacro", "defstruct", "defprotocol", "defimpl", "do", "end", "fn", "if", "else", "unless", "cond", "case", "with", "when", "for", "in", "import", "alias", "require", "use", "quote", "unquote", "receive", "try", "rescue", "catch", "after", "raise", "nil", "true", "false", "and", "or", "not"]
        case "erlang":
            return ["module", "export", "import", "include", "define", "record", "spec", "case", "of", "end", "if", "when", "receive", "after", "try", "catch", "fun", "begin", "andalso", "orelse", "not", "and", "or", "div", "rem", "true", "false"]
        case "ocaml", "f#":
            return ["let", "rec", "in", "and", "fun", "function", "match", "with", "if", "then", "else", "begin", "end", "type", "module", "open", "struct", "sig", "val", "of", "when", "try", "exception", "mutable", "true", "false", "for", "while", "do", "done", "to", "namespace", "member", "new", "yield", "use", "inherit", "interface", "abstract", "override", "private", "public", "internal"]
        case "lisp":
            return ["defun", "defmacro", "defvar", "defparameter", "defconstant", "defstruct", "defclass", "defmethod", "defgeneric", "define", "lambda", "let", "let*", "letrec", "if", "cond", "case", "when", "unless", "do", "loop", "progn", "setq", "setf", "quote", "require", "provide", "ns", "def", "defn", "fn", "nil", "t"]
        case "matlab":
            return ["function", "end", "if", "elseif", "else", "for", "while", "switch", "case", "otherwise", "break", "continue", "return", "try", "catch", "global", "persistent", "classdef", "properties", "methods", "events", "true", "false"]
        case "coffeescript":
            return ["class", "extends", "constructor", "super", "new", "if", "else", "unless", "then", "for", "in", "of", "while", "until", "loop", "switch", "when", "return", "break", "continue", "try", "catch", "finally", "throw", "and", "or", "not", "is", "isnt", "yes", "no", "on", "off", "true", "false", "null", "undefined", "this", "import", "export", "default", "await", "async"]
        case "d", "actionscript":
            return ["class", "interface", "struct", "enum", "module", "import", "public", "private", "protected", "static", "final", "override", "abstract", "function", "var", "const", "void", "return", "if", "else", "for", "foreach", "while", "do", "switch", "case", "default", "break", "continue", "try", "catch", "finally", "throw", "new", "this", "super", "null", "true", "false", "auto", "alias", "template", "mixin", "package", "extends", "implements", "is", "in", "out", "ref", "lazy", "pure", "nothrow", "unittest"]
        case "pascal":
            return ["program", "unit", "uses", "interface", "implementation", "begin", "end", "var", "const", "type", "procedure", "function", "if", "then", "else", "for", "to", "downto", "do", "while", "repeat", "until", "case", "of", "record", "class", "object", "private", "public", "protected", "try", "except", "finally", "raise", "nil", "true", "false", "and", "or", "not", "div", "mod", "inherited", "constructor", "destructor", "override", "virtual"]
        case "ada":
            return ["package", "body", "is", "begin", "end", "procedure", "function", "return", "if", "then", "elsif", "else", "case", "when", "for", "while", "loop", "exit", "declare", "type", "subtype", "record", "array", "of", "with", "use", "null", "and", "or", "not", "xor", "in", "out", "access", "private", "generic", "raise", "exception", "others", "task", "protected"]
        case "vhdl":
            return ["library", "use", "entity", "architecture", "of", "is", "begin", "end", "port", "generic", "map", "signal", "variable", "constant", "process", "if", "then", "elsif", "else", "case", "when", "for", "while", "loop", "in", "out", "inout", "buffer", "component", "package", "body", "function", "procedure", "return", "wait", "until", "after", "others", "and", "or", "not", "xor", "nand", "nor", "downto", "to", "type", "subtype", "std_logic", "std_logic_vector"]
        case "verilog":
            return ["module", "endmodule", "input", "output", "inout", "wire", "reg", "logic", "integer", "parameter", "localparam", "assign", "always", "always_ff", "always_comb", "initial", "begin", "end", "if", "else", "case", "endcase", "default", "for", "while", "posedge", "negedge", "function", "endfunction", "task", "endtask", "generate", "endgenerate", "genvar", "typedef", "enum", "struct", "interface", "endinterface", "class", "endclass"]
        case "fortran":
            return ["program", "end", "subroutine", "function", "module", "use", "implicit", "none", "integer", "real", "double", "precision", "complex", "logical", "character", "dimension", "allocatable", "allocate", "deallocate", "parameter", "intent", "in", "out", "inout", "if", "then", "else", "elseif", "do", "while", "select", "case", "call", "return", "contains", "stop", "print", "write", "read", "type", "interface"]
        case "visual basic":
            return ["Dim", "As", "Sub", "Function", "End", "If", "Then", "Else", "ElseIf", "For", "Each", "Next", "While", "Wend", "Do", "Loop", "Select", "Case", "Class", "Module", "Public", "Private", "Protected", "Friend", "Shared", "Static", "Const", "Return", "Exit", "Imports", "Namespace", "New", "Nothing", "True", "False", "And", "Or", "Not", "Is", "ByVal", "ByRef", "Try", "Catch", "Finally", "Throw", "With", "Set", "Let", "Option", "Explicit", "On", "Error", "Resume", "Call", "To", "Step", "In", "Of", "Integer", "String", "Boolean", "Double", "Long", "Object"]
        case "tcl":
            return ["proc", "set", "unset", "if", "elseif", "else", "for", "foreach", "while", "switch", "break", "continue", "return", "expr", "puts", "gets", "global", "upvar", "namespace", "eval", "catch", "error", "source", "package", "require", "list", "lappend", "lindex", "string", "array", "dict"]
        case "nim":
            return ["proc", "func", "method", "iterator", "template", "macro", "var", "let", "const", "type", "object", "enum", "tuple", "if", "elif", "else", "when", "case", "of", "for", "while", "in", "block", "break", "continue", "return", "yield", "import", "include", "from", "export", "try", "except", "finally", "raise", "discard", "nil", "true", "false", "and", "or", "not", "xor", "is", "isnot", "as", "ref", "ptr", "static"]
        case "assembly", "autoit", "latex", "properties", "yaml", "toml", "ini", "csv", "log", "diff", "ignore", "makefile", "dockerfile", "batch", "markdown":
            return []
        default:
            // Unknown or unlisted C-like language: a conservative keyword set beats no highlighting at all.
            return ["function", "const", "let", "var", "import", "export", "class", "return", "if", "else", "for", "while"]
        }
    }

    private static func getCommonTypes(for lang: String) -> [String] {
        switch lang {
        case "java":
            return [
                "String", "Integer", "Long", "Double", "Float", "Boolean", "Byte", "Short", "Character",
                "Object", "List", "ArrayList", "Map", "HashMap", "Set", "HashSet", "Optional",
                "Stream", "CompletableFuture", "Exception", "RuntimeException", "Throwable"
            ]
        case "swift":
            return ["Int", "Double", "Float", "String", "Bool", "Character", "Array", "Dictionary", "Set", "Optional", "Result", "Error"]
        case "typescript":
            return ["string", "number", "boolean", "any", "unknown", "never", "void", "Array", "Promise", "Record", "Partial", "Required"]
        case "rust":
            return ["i8", "i16", "i32", "i64", "i128", "isize", "u8", "u16", "u32", "u64", "u128", "usize", "f32", "f64", "bool", "char", "str", "String", "Vec", "Option", "Result"]
        case "go":
            return ["int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16", "uint32", "uint64", "uintptr", "float32", "float64", "complex64", "complex128", "string", "bool", "byte", "rune", "error"]
        default:
            return []
        }
    }
}
