import Foundation

// MARK: - File Type Registry
/// Single source of truth for mapping a file name (or its content) to a language,
/// and for deciding whether a file can sensibly be opened as text.
public enum FileTypeRegistry {

    private static let extensionTable: [(language: String, extensions: [String])] = [
        ("Java", ["java"]),
        ("Swift", ["swift"]),
        ("Kotlin", ["kt", "kts"]),
        ("JavaScript", ["js", "mjs", "cjs", "jsx", "es6"]),
        ("TypeScript", ["ts", "tsx", "mts", "cts"]),
        ("Python", ["py", "pyw", "pyi", "pyx", "gyp", "gypi", "wsgi"]),
        ("C", ["c", "h", "glsl", "vert", "frag"]),
        ("C++", ["cpp", "hpp", "cc", "cxx", "c++", "hh", "hxx", "ipp", "inl", "tpp", "ino", "cu", "cuh", "metal"]),
        ("C#", ["cs", "csx"]),
        ("Objective-C", ["mm"]),
        ("Go", ["go"]),
        ("Rust", ["rs"]),
        ("HTML", ["html", "htm", "xhtml", "vue", "svelte", "astro", "ejs", "hbs", "handlebars", "mustache",
                  "jsp", "asp", "aspx", "cshtml", "razor", "erb", "twig", "njk", "jinja", "jinja2", "j2", "liquid"]),
        ("CSS", ["css", "pcss", "postcss"]),
        ("Sass", ["scss", "sass", "less", "styl"]),
        ("XML", ["xml", "plist", "svg", "xsd", "wsdl", "xsl", "xslt", "xaml", "csproj", "vbproj", "fsproj",
                 "props", "targets", "resx", "storyboard", "xib", "entitlements", "nuspec", "rss", "atom",
                 "gpx", "kml", "fxml", "mobileconfig", "xliff", "config", "iml", "dtd"]),
        ("JSON", ["json", "json5", "jsonc", "geojson", "webmanifest", "ipynb", "har", "jsonl", "ndjson", "code-workspace"]),
        ("YAML", ["yaml", "yml", "clang-format"]),
        ("TOML", ["toml"]),
        ("INI", ["ini", "cfg", "cnf", "desktop", "editorconfig", "gitconfig", "service", "socket", "timer"]),
        ("Properties", ["properties", "env", "conf", "prefs"]),
        ("CSV", ["csv", "tsv"]),
        ("SQL", ["sql", "psql", "pgsql", "ddl"]),
        ("Shell", ["sh", "bash", "zsh", "command", "ksh", "fish", "dash", "bats", "envrc"]),
        ("Batch", ["bat", "cmd"]),
        ("PowerShell", ["ps1", "psm1", "psd1"]),
        ("Markdown", ["md", "markdown", "mdown", "mkd", "mdx"]),
        ("Log", ["log"]),
        ("Gradle", ["gradle"]),
        ("Ruby", ["rb", "ruby", "gemspec", "rake", "rbw", "podspec"]),
        ("PHP", ["php", "phtml", "php3", "php4", "php5", "phps"]),
        ("Dart", ["dart"]),
        ("Lua", ["lua"]),
        ("Perl", ["pl", "pm"]),
        ("R", ["r", "rmd"]),
        ("Julia", ["jl"]),
        ("Zig", ["zig"]),
        ("Scala", ["scala", "sc", "sbt"]),
        ("Elixir", ["ex", "exs"]),
        ("Erlang", ["erl", "hrl"]),
        ("Haskell", ["hs", "lhs"]),
        ("LaTeX", ["tex", "latex", "sty", "cls", "bib"]),
        ("CMake", ["cmake"]),
        ("Diff", ["diff", "patch"]),
        ("Verilog", ["v", "sv", "svh"]),
        ("VHDL", ["vhd", "vhdl"]),
        ("Visual Basic", ["vb", "vbs", "bas"]),
        ("Nim", ["nim"]),
        ("ActionScript", ["as"]),
        ("Ada", ["ada", "adb", "ads"]),
        ("Assembly", ["asm", "s"]),
        ("AutoIt", ["au3"]),
        ("Fortran", ["f", "f90", "f95", "f03", "for"]),
        ("F#", ["fs", "fsi", "fsx"]),
        ("Groovy", ["groovy", "gvy"]),
        ("GraphQL", ["graphql", "gql", "graphqls"]),
        ("Lisp", ["lisp", "lsp", "cl", "el", "scm", "rkt", "clj", "cljs", "cljc", "edn"]),
        ("OCaml", ["ml", "mli"]),
        ("Pascal", ["pas", "pp", "dpr"]),
        ("TCL", ["tcl"]),
        ("CoffeeScript", ["coffee"]),
        ("D", ["d"]),
        ("Terraform", ["tf", "tfvars", "hcl"]),
        ("Protobuf", ["proto"]),
        ("Dockerfile", ["dockerfile"]),
        ("Makefile", ["mk", "mak"]),
        ("Plain Text", ["txt", "text", "rst", "adoc", "org", "nfo"])
    ]

    private static let filenameTable: [(language: String, names: [String])] = [
        ("XML", ["pom.xml"]),
        ("Gradle", ["build.gradle", "settings.gradle", "build.gradle.kts", "settings.gradle.kts"]),
        ("CMake", ["cmakelists.txt"]),
        ("Ruby", ["gemfile", "rakefile", "podfile", "fastfile", "vagrantfile", "brewfile", "guardfile", "capfile", "berksfile"]),
        ("Dockerfile", ["dockerfile", "containerfile"]),
        ("Makefile", ["makefile", "gnumakefile"]),
        ("Groovy", ["jenkinsfile"]),
        ("Shell", [".bashrc", ".zshrc", ".profile", ".bash_profile", ".bash_aliases", ".bash_logout",
                   ".zprofile", ".zshenv", ".zlogin", ".kshrc", "pkgbuild"]),
        ("Properties", [".env", ".flaskenv", ".npmrc", ".yarnrc", ".pypirc"]),
        ("Ignore", [".gitignore", ".dockerignore", ".npmignore", ".eslintignore", ".prettierignore",
                    ".gitkeep", ".slugignore", ".helmignore", ".hgignore", ".vscodeignore", ".cfignore"]),
        ("INI", [".gitmodules", ".editorconfig", ".gitconfig", ".pylintrc", ".flake8"]),
        ("Properties", [".gitattributes"]),
        ("JSON", [".babelrc", ".eslintrc", ".prettierrc", ".stylelintrc", ".swcrc", ".jshintrc", ".watchmanconfig",
                  "composer.lock", "pipfile.lock"]),
        ("YAML", [".clang-format", ".clang-tidy", ".travis.yml"]),
        ("TOML", ["cargo.lock", "poetry.lock", "pipfile"]),
        ("Python", ["sconstruct", "sconscript", "wscript"])
    ]

    private static let extensionLookup: [String: String] = {
        var map: [String: String] = [:]
        for entry in extensionTable {
            for ext in entry.extensions { map[ext] = entry.language }
        }
        return map
    }()

    private static let filenameLookup: [String: String] = {
        var map: [String: String] = [:]
        for entry in filenameTable {
            for name in entry.names { map[name] = entry.language }
        }
        return map
    }()

    /// Extensions that are never meaningful to show as text.
    public static let binaryExtensions: Set<String> = [
        "numbers", "pages", "key", "zip", "tar", "gz", "tgz", "bz2", "xz", "7z", "rar", "dmg", "pkg", "iso",
        "exe", "dll", "bin", "dylib", "so", "o", "a", "class", "jar", "war", "apk", "ipa", "app",
        "png", "jpg", "jpeg", "gif", "ico", "icns", "bmp", "tiff", "tif", "webp", "heic", "psd",
        "pdf", "docx", "doc", "xlsx", "xls", "pptx", "ppt", "odt", "ods",
        "mp3", "mp4", "m4a", "mov", "avi", "mkv", "wav", "flac", "aac", "ogg", "webm",
        "ttf", "otf", "woff", "woff2", "sqlite", "sqlite3", "db", "pyc", "pyo", "wasm"
    ]

    /// Every extension the registry recognises, for tests and Finder integration checks.
    public static var knownExtensions: Set<String> { Set(extensionLookup.keys) }

    public static func isKnownBinaryExtension(_ url: URL) -> Bool {
        binaryExtensions.contains(url.pathExtension.lowercased())
    }

    /// Detects the language for a file name, falling back to content sniffing for extensionless files.
    public static func language(forFilename filename: String, content: String = "") -> String {
        let lowerName = filename.lowercased()

        if let named = filenameLookup[lowerName] { return named }

        // Dotfiles have no pathExtension in Foundation (".env" -> ""), so match prefixes/suffixes explicitly.
        if lowerName == ".env" || lowerName.hasPrefix(".env.") || lowerName.hasSuffix(".env") { return "Properties" }
        if lowerName.hasPrefix("dockerfile.") { return "Dockerfile" }
        if lowerName.hasPrefix("requirements") && lowerName.hasSuffix(".txt") { return "Properties" }

        let ext = (lowerName as NSString).pathExtension
        switch ext {
        case "m":
            if content.contains("#import") || content.contains("@interface") || content.contains("@implementation") {
                return "Objective-C"
            }
            return "MATLAB"
        case "h":
            if content.contains("@interface") || content.contains("@protocol") { return "Objective-C" }
            if content.contains("namespace ") || content.contains("template <") || content.contains("template<")
                || content.contains("#include <iostream>") || content.contains("class ") { return "C++" }
            return "C"
        default:
            break
        }
        if !ext.isEmpty, let language = extensionLookup[ext] { return language }

        // Dotfile whose whole name is an extension-like token (".gitignore" handled above, ".bashrc" etc.)
        if lowerName.hasPrefix("."), !lowerName.dropFirst().contains("."),
           let language = extensionLookup[String(lowerName.dropFirst())] {
            return language
        }

        return languageFromContent(content)
    }

    private static func languageFromContent(_ content: String) -> String {
        guard !content.isEmpty else { return "Plain Text" }
        let firstLine = content.prefix(while: { $0 != "\n" && $0 != "\r" })

        if firstLine.hasPrefix("#!") {
            // "#!/usr/bin/env -S python3 -u" -> pick the first non-flag token after env.
            var tokens = firstLine.dropFirst(2).split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            if let first = tokens.first, (first as NSString).lastPathComponent == "env" {
                tokens.removeFirst()
                tokens.removeAll(where: { $0.hasPrefix("-") })
            }
            let interpreter = ((tokens.first ?? "") as NSString).lastPathComponent.lowercased()
            if interpreter.hasPrefix("python") { return "Python" }
            if ["bash", "sh", "zsh", "ksh", "dash", "fish"].contains(interpreter) { return "Shell" }
            if ["node", "nodejs", "deno", "bun"].contains(interpreter) { return "JavaScript" }
            if interpreter.hasPrefix("ruby") { return "Ruby" }
            if interpreter.hasPrefix("perl") { return "Perl" }
            if interpreter.hasPrefix("php") { return "PHP" }
            if interpreter == "lua" || interpreter == "luajit" { return "Lua" }
            if interpreter == "rscript" { return "R" }
            if interpreter == "pwsh" || interpreter == "powershell" { return "PowerShell" }
            if interpreter == "swift" { return "Swift" }
            return "Plain Text"
        }

        let lowerHead = content.prefix(256).lowercased()
        if lowerHead.hasPrefix("<?xml") { return "XML" }
        if lowerHead.hasPrefix("<!doctype html") || lowerHead.hasPrefix("<html") { return "HTML" }
        return "Plain Text"
    }

    // MARK: - Binary Detection
    /// Heuristic: NUL bytes (outside a UTF-16 BOM'd file) or a high proportion of control bytes mean binary.
    public static func looksBinary(_ data: Data) -> Bool {
        guard !data.isEmpty else { return false }
        if FileCodec.detectBOM(in: data) != nil { return false }
        let sample = data.prefix(8192)
        var controlBytes = 0
        for byte in sample {
            if byte == 0 { return true }
            if byte < 9 || (byte > 13 && byte < 32 && byte != 27) { controlBytes += 1 }
        }
        return Double(controlBytes) / Double(sample.count) > 0.3
    }
}

// MARK: - Encoding Codec
/// Decodes file bytes into text (detecting BOMs and legacy encodings) and encodes text back
/// using the document's chosen encoding, so saving never silently changes a file's encoding.
public enum FileCodec {

    public struct DecodeResult {
        public let text: String
        public let encoding: DocumentEncoding
    }

    public enum EncodeError: LocalizedError {
        case unrepresentable(DocumentEncoding)

        public var errorDescription: String? {
            switch self {
            case .unrepresentable(let enc):
                return "The document contains characters that cannot be saved as \(enc.rawValue). Change the encoding (for example to UTF-8) and save again."
            }
        }
    }

    public static func detectBOM(in data: Data) -> DocumentEncoding? {
        let bytes = [UInt8](data.prefix(3))
        if bytes.count >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF { return .utf8BOM }
        if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE { return .utf16LE }
        if bytes.count >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF { return .utf16BE }
        return nil
    }

    public static func decode(_ data: Data) -> DecodeResult {
        switch detectBOM(in: data) {
        case .utf8BOM:
            let body = data.dropFirst(3)
            return DecodeResult(text: String(decoding: body, as: UTF8.self), encoding: .utf8BOM)
        case .utf16LE:
            let text = String(data: data.dropFirst(2), encoding: .utf16LittleEndian) ?? String(decoding: data.dropFirst(2), as: UTF8.self)
            return DecodeResult(text: text, encoding: .utf16LE)
        case .utf16BE:
            let text = String(data: data.dropFirst(2), encoding: .utf16BigEndian) ?? String(decoding: data.dropFirst(2), as: UTF8.self)
            return DecodeResult(text: text, encoding: .utf16BE)
        default:
            break
        }

        if let utf8 = String(data: data, encoding: .utf8) {
            return DecodeResult(text: utf8, encoding: .utf8)
        }
        // Not valid UTF-8: legacy single-byte text (Windows-1252 first, ISO-8859-1 never fails).
        if let cp1252 = String(data: data, encoding: .windowsCP1252) {
            return DecodeResult(text: cp1252, encoding: .windows1252)
        }
        return DecodeResult(text: String(data: data, encoding: .isoLatin1) ?? String(decoding: data, as: UTF8.self), encoding: .latin1)
    }

    public static func encode(_ text: String, as encoding: DocumentEncoding) throws -> Data {
        var data = Data()
        let encoded: Data?
        switch encoding {
        case .utf8:
            encoded = text.data(using: .utf8)
        case .utf8BOM:
            data.append(contentsOf: [0xEF, 0xBB, 0xBF])
            encoded = text.data(using: .utf8)
        case .utf16LE:
            data.append(contentsOf: [0xFF, 0xFE])
            encoded = text.data(using: .utf16LittleEndian)
        case .utf16BE:
            data.append(contentsOf: [0xFE, 0xFF])
            encoded = text.data(using: .utf16BigEndian)
        case .ascii:
            encoded = text.data(using: .ascii)
        case .windows1252:
            encoded = text.data(using: .windowsCP1252) ?? text.data(using: .isoLatin1)
        case .latin1:
            encoded = text.data(using: .isoLatin1)
        }
        guard let body = encoded else { throw EncodeError.unrepresentable(encoding) }
        data.append(body)
        return data
    }

    public static func write(_ text: String, to url: URL, as encoding: DocumentEncoding) throws {
        try encode(text, as: encoding).write(to: url, options: .atomic)
    }
}
