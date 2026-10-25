import Foundation

public enum SearchModeType: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case extended = "Extended (\\n, \\r, \\t, \\0, \\x...)"
    case regex = "Regular expression"
    case fuzzy = "Fuzzy search"

    public var id: String { rawValue }
}

public struct SearchOptions: Equatable {
    public var caseSensitive: Bool
    public var wholeWord: Bool
    public var isRegex: Bool
    public var wrapAround: Bool
    public var backward: Bool
    public var searchMode: SearchModeType
    public var dotMatchesNewline: Bool
    public var inSelection: Bool

    public init(
        caseSensitive: Bool = false,
        wholeWord: Bool = false,
        isRegex: Bool = false,
        wrapAround: Bool = true,
        backward: Bool = false,
        searchMode: SearchModeType = .normal,
        dotMatchesNewline: Bool = false,
        inSelection: Bool = false
    ) {
        self.caseSensitive = caseSensitive
        self.wholeWord = wholeWord
        self.isRegex = isRegex || (searchMode == .regex)
        self.wrapAround = wrapAround
        self.backward = backward
        self.searchMode = searchMode
        self.dotMatchesNewline = dotMatchesNewline
        self.inSelection = inSelection
    }
}

public struct SearchResultItem: Identifiable, Hashable {
    public let id = UUID()
    public let fileTitle: String
    public let fileURL: URL?
    public let lineNumber: Int
    public let lineContent: String
    public let matchRange: NSRange

    public init(
        fileTitle: String,
        fileURL: URL?,
        lineNumber: Int,
        lineContent: String,
        matchRange: NSRange
    ) {
        self.fileTitle = fileTitle
        self.fileURL = fileURL
        self.lineNumber = lineNumber
        self.lineContent = lineContent
        self.matchRange = matchRange
    }
}

public struct SearchResult: Equatable {
    public let matchingRanges: [NSRange]
    public let totalCount: Int
    public let activeIndex: Int // 0 if none, 1-based index if active
    public let errorMessage: String?

    public init(
        matchingRanges: [NSRange] = [],
        totalCount: Int = 0,
        activeIndex: Int = 0,
        errorMessage: String? = nil
    ) {
        self.matchingRanges = matchingRanges
        self.totalCount = totalCount
        self.activeIndex = activeIndex
        self.errorMessage = errorMessage
    }
}

public final class SearchEngine {

    /// Parses escape sequences for Notepad++ Extended Search Mode (\n, \r, \t, \0, \xNN, \\)
    public static func parseExtendedString(_ input: String) -> String {
        var result = ""
        var iterator = input.makeIterator()
        while let ch = iterator.next() {
            if ch == "\\" {
                if let nextCh = iterator.next() {
                    switch nextCh {
                    case "n": result.append("\n")
                    case "r": result.append("\r")
                    case "t": result.append("\t")
                    case "0": result.append("\0")
                    case "\\": result.append("\\")
                    case "x":
                        var hexStr = ""
                        if let h1 = iterator.next() { hexStr.append(h1) }
                        if let h2 = iterator.next() { hexStr.append(h2) }
                        if let byteVal = UInt8(hexStr, radix: 16) {
                            result.append(Character(UnicodeScalar(byteVal)))
                        } else {
                            result.append("\\x" + hexStr)
                        }
                    default:
                        result.append(nextCh)
                    }
                } else {
                    result.append("\\")
                }
            } else {
                result.append(ch)
            }
        }
        return result
    }

    /// Finds all matching ranges in `text` based on `query` and `options`.
    public static func findAll(
        in text: String,
        query: String,
        options: SearchOptions,
        selectedRange: NSRange? = nil
    ) -> SearchResult {
        guard !query.isEmpty else {
            return SearchResult(matchingRanges: [], totalCount: 0, activeIndex: 0, errorMessage: nil)
        }

        let nsText = text as NSString
        var searchBounds = NSRange(location: 0, length: nsText.length)
        if options.inSelection, let sel = selectedRange, sel.length > 0 && sel.location + sel.length <= nsText.length {
            searchBounds = sel
        }
        guard searchBounds.length > 0 else {
            return SearchResult(matchingRanges: [], totalCount: 0, activeIndex: 0, errorMessage: nil)
        }

        var regexOptions: NSRegularExpression.Options = []
        if !options.caseSensitive {
            regexOptions.insert(.caseInsensitive)
        }
        if options.dotMatchesNewline {
            regexOptions.insert(.dotMatchesLineSeparators)
        }

        let pattern: String
        let actualQuery: String
        if options.searchMode == .extended {
            actualQuery = parseExtendedString(query)
            let escaped = NSRegularExpression.escapedPattern(for: actualQuery)
            pattern = options.wholeWord ? "\\b\(escaped)\\b" : escaped
        } else if options.searchMode == .fuzzy {
            // Fuzzy search: inserts wildcards between non-space characters
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            let fuzzyParts = trimmed.map { NSRegularExpression.escapedPattern(for: String($0)) }
            pattern = fuzzyParts.joined(separator: ".*?")
        } else if options.isRegex || options.searchMode == .regex {
            pattern = query
        } else {
            let escaped = NSRegularExpression.escapedPattern(for: query)
            pattern = options.wholeWord ? "\\b\(escaped)\\b" : escaped
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let matches = regex.matches(in: text, options: [], range: searchBounds)
            var ranges = matches.map { $0.range }

            if options.backward {
                ranges.reverse()
            }

            var activeIdx = 0
            if let current = selectedRange, !ranges.isEmpty {
                if let idx = ranges.firstIndex(where: { $0.location == current.location && $0.length == current.length }) {
                    activeIdx = idx + 1
                } else if !options.backward, let nextIdx = ranges.firstIndex(where: { $0.location >= current.location }) {
                    activeIdx = nextIdx + 1
                } else if options.backward, let prevIdx = ranges.firstIndex(where: { $0.location <= current.location }) {
                    activeIdx = prevIdx + 1
                } else {
                    activeIdx = 1
                }
            } else if !ranges.isEmpty {
                activeIdx = 1
            }

            return SearchResult(
                matchingRanges: ranges,
                totalCount: ranges.count,
                activeIndex: activeIdx,
                errorMessage: nil
            )
        } catch {
            return SearchResult(
                matchingRanges: [],
                totalCount: 0,
                activeIndex: 0,
                errorMessage: "Invalid search expression: \(error.localizedDescription)"
            )
        }
    }

    /// Calculates the next match index given the current selection/cursor position.
    public static func nextIndex(
        from currentRange: NSRange,
        in ranges: [NSRange],
        wrap: Bool
    ) -> Int? {
        guard !ranges.isEmpty else { return nil }

        if let idx = ranges.firstIndex(where: { $0.location > currentRange.location }) {
            return idx
        }

        if wrap {
            return 0
        }

        return nil
    }

    /// Calculates the previous match index given the current selection/cursor position.
    public static func previousIndex(
        from currentRange: NSRange,
        in ranges: [NSRange],
        wrap: Bool
    ) -> Int? {
        guard !ranges.isEmpty else { return nil }

        if let idx = ranges.lastIndex(where: { $0.location < currentRange.location }) {
            return idx
        }

        if wrap {
            return ranges.count - 1
        }

        return nil
    }

    /// Replaces a single occurrence at `targetRange` in `text` with `replacement`.
    public static func replace(
        in text: String,
        targetRange: NSRange,
        with replacement: String,
        options: SearchOptions = SearchOptions()
    ) -> (newText: String, newRange: NSRange)? {
        let nsText = text as NSString
        guard targetRange.location != NSNotFound,
              targetRange.location + targetRange.length <= nsText.length else {
            return nil
        }

        let actualReplacement = options.searchMode == .extended ? parseExtendedString(replacement) : replacement
        let newText = nsText.replacingCharacters(in: targetRange, with: actualReplacement)
        let newRange = NSRange(location: targetRange.location, length: (actualReplacement as NSString).length)
        return (newText, newRange)
    }

    /// Replaces all occurrences in `text` based on `query` and `options`.
    public static func replaceAll(
        in text: String,
        query: String,
        replacement: String,
        options: SearchOptions
    ) -> (newText: String, count: Int, error: String?) {
        guard !query.isEmpty else { return (text, 0, nil) }

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        guard fullRange.length > 0 else { return (text, 0, nil) }

        var regexOptions: NSRegularExpression.Options = []
        if !options.caseSensitive {
            regexOptions.insert(.caseInsensitive)
        }
        if options.dotMatchesNewline {
            regexOptions.insert(.dotMatchesLineSeparators)
        }

        let pattern: String
        let actualQuery: String
        let actualReplacement: String
        if options.searchMode == .extended {
            actualQuery = parseExtendedString(query)
            actualReplacement = parseExtendedString(replacement)
            let escaped = NSRegularExpression.escapedPattern(for: actualQuery)
            pattern = options.wholeWord ? "\\b\(escaped)\\b" : escaped
        } else if options.isRegex || options.searchMode == .regex {
            pattern = query
            actualReplacement = replacement
        } else {
            let escaped = NSRegularExpression.escapedPattern(for: query)
            pattern = options.wholeWord ? "\\b\(escaped)\\b" : escaped
            actualReplacement = replacement
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            let matches = regex.matches(in: text, options: [], range: fullRange)
            let count = matches.count
            guard count > 0 else { return (text, 0, nil) }

            let template = (options.isRegex || options.searchMode == .regex)
                ? actualReplacement
                : NSRegularExpression.escapedTemplate(for: actualReplacement)

            let replaced = regex.stringByReplacingMatches(
                in: text,
                options: [],
                range: fullRange,
                withTemplate: template
            )

            return (replaced, count, nil)
        } catch {
            return (text, 0, "Regex error: \(error.localizedDescription)")
        }
    }

    /// Finds matches with line numbers and line content in given text.
    public static func findLines(
        in text: String,
        fileTitle: String,
        fileURL: URL?,
        query: String,
        options: SearchOptions
    ) -> [SearchResultItem] {
        let result = findAll(in: text, query: query, options: options)
        guard !result.matchingRanges.isEmpty else { return [] }

        let nsText = text as NSString
        var items: [SearchResultItem] = []

        for range in result.matchingRanges {
            let lineRange = nsText.lineRange(for: range)
            let lineContent = nsText.substring(with: lineRange).trimmingCharacters(in: .newlines)

            var lineNumber = 1
            var pos = 0
            while pos < range.location {
                let nextNL = nsText.range(of: "\n", options: [], range: NSRange(location: pos, length: range.location - pos))
                if nextNL.location == NSNotFound { break }
                lineNumber += 1
                pos = nextNL.location + nextNL.length
            }

            items.append(SearchResultItem(
                fileTitle: fileTitle,
                fileURL: fileURL,
                lineNumber: lineNumber,
                lineContent: lineContent,
                matchRange: range
            ))
        }

        return items
    }

    /// Scans a directory on disk, matching file filters and collecting occurrences.
    public static func findInFiles(
        directory: String,
        filters: String,
        query: String,
        options: SearchOptions,
        recursive: Bool,
        includeHidden: Bool
    ) -> [SearchResultItem] {
        guard !query.isEmpty, !directory.isEmpty else { return [] }
        let dirURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: dirURL.path) else { return [] }

        var filterPatterns = filters.components(separatedBy: CharacterSet(charactersIn: ";, "))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if filterPatterns.isEmpty { filterPatterns = ["*.*"] }

        var results: [SearchResultItem] = []
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isHiddenKey]
        let enumeratorOptions: FileManager.DirectoryEnumerationOptions = recursive ? [] : [.skipsSubdirectoryDescendants]

        guard let enumerator = FileManager.default.enumerator(
            at: dirURL,
            includingPropertiesForKeys: resourceKeys,
            options: enumeratorOptions
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  resourceValues.isRegularFile == true else { continue }

            if !includeHidden && (resourceValues.isHidden == true || fileURL.lastPathComponent.hasPrefix(".")) {
                continue
            }

            let name = fileURL.lastPathComponent
            let matchesFilter = filterPatterns.contains { pattern in
                if pattern == "*.*" || pattern == "*" { return true }
                if pattern.hasPrefix("*.") {
                    let ext = String(pattern.dropFirst(2))
                    return fileURL.pathExtension.lowercased() == ext.lowercased()
                }
                return fnmatch(pattern, name, 0) == 0
            }

            guard matchesFilter else { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }

            let fileMatches = findLines(
                in: content,
                fileTitle: name,
                fileURL: fileURL,
                query: query,
                options: options
            )
            results.append(contentsOf: fileMatches)
        }

        return results
    }

    /// Replaces matches in files on disk and writes them back.
    public static func replaceInFiles(
        directory: String,
        filters: String,
        query: String,
        replacement: String,
        options: SearchOptions,
        recursive: Bool,
        includeHidden: Bool
    ) -> (replacedFiles: Int, totalReplacements: Int, error: String?) {
        guard !query.isEmpty, !directory.isEmpty else { return (0, 0, "Missing directory or query") }
        let dirURL = URL(fileURLWithPath: (directory as NSString).expandingTildeInPath)
        guard FileManager.default.fileExists(atPath: dirURL.path) else { return (0, 0, "Directory does not exist") }

        var filterPatterns = filters.components(separatedBy: CharacterSet(charactersIn: ";, "))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if filterPatterns.isEmpty { filterPatterns = ["*.*"] }

        var replacedFiles = 0
        var totalReplacements = 0

        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .isHiddenKey]
        let enumeratorOptions: FileManager.DirectoryEnumerationOptions = recursive ? [] : [.skipsSubdirectoryDescendants]

        guard let enumerator = FileManager.default.enumerator(
            at: dirURL,
            includingPropertiesForKeys: resourceKeys,
            options: enumeratorOptions
        ) else { return (0, 0, "Failed to enumerate directory") }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                  resourceValues.isRegularFile == true else { continue }

            if !includeHidden && (resourceValues.isHidden == true || fileURL.lastPathComponent.hasPrefix(".")) {
                continue
            }

            let name = fileURL.lastPathComponent
            let matchesFilter = filterPatterns.contains { pattern in
                if pattern == "*.*" || pattern == "*" { return true }
                if pattern.hasPrefix("*.") {
                    let ext = String(pattern.dropFirst(2))
                    return fileURL.pathExtension.lowercased() == ext.lowercased()
                }
                return fnmatch(pattern, name, 0) == 0
            }

            guard matchesFilter else { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }

            let (newContent, count, err) = replaceAll(in: content, query: query, replacement: replacement, options: options)
            if let err = err { return (replacedFiles, totalReplacements, err) }

            if count > 0 {
                do {
                    try newContent.write(to: fileURL, atomically: true, encoding: .utf8)
                    replacedFiles += 1
                    totalReplacements += count
                } catch {
                    // Continue with other files
                }
            }
        }

        return (replacedFiles, totalReplacements, nil)
    }
}
