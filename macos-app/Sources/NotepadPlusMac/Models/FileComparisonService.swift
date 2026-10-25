import Foundation
import AppKit

// MARK: - Diff Line Classification
public enum DiffLineKind: String, Codable, Equatable {
    case unchanged = "Unchanged"
    case added = "Added"       // Exists in right, not in left (green)
    case deleted = "Deleted"   // Exists in left, not in right (red)
    case modified = "Modified" // Changed between left and right (orange)

    public var gutterMarker: String {
        switch self {
        case .added: return "+"
        case .deleted: return "-"
        case .modified: return "~"
        case .unchanged: return " "
        }
    }
}

// MARK: - Detailed Per-Line Diff Information
public struct DiffLineInfo: Identifiable, Equatable {
    public let id = UUID()
    public let lineNumber: Int       // 1-based in source file
    public let kind: DiffLineKind
    public let content: String
    public let modifiedCharacterRanges: [NSRange] // Sub-line ranges with changes (intra-line diff)

    public init(
        lineNumber: Int,
        kind: DiffLineKind,
        content: String,
        modifiedCharacterRanges: [NSRange] = []
    ) {
        self.lineNumber = lineNumber
        self.kind = kind
        self.content = content
        self.modifiedCharacterRanges = modifiedCharacterRanges
    }
}

// MARK: - Contiguous Difference Chunk
public struct DiffChunk: Identifiable, Equatable {
    public let id = UUID()
    public let index: Int
    public let leftLineStart: Int    // 1-based start line in left document (0 if purely added)
    public let leftLineCount: Int    // Number of lines in left document
    public let rightLineStart: Int   // 1-based start line in right document (0 if purely deleted)
    public let rightLineCount: Int   // Number of lines in right document
    public let kind: DiffLineKind

    public var leftLineRange: ClosedRange<Int>? {
        guard leftLineCount > 0, leftLineStart > 0 else { return nil }
        return leftLineStart...(leftLineStart + leftLineCount - 1)
    }

    public var rightLineRange: ClosedRange<Int>? {
        guard rightLineCount > 0, rightLineStart > 0 else { return nil }
        return rightLineStart...(rightLineStart + rightLineCount - 1)
    }

    public init(
        index: Int,
        leftLineStart: Int,
        leftLineCount: Int,
        rightLineStart: Int,
        rightLineCount: Int,
        kind: DiffLineKind
    ) {
        self.index = index
        self.leftLineStart = leftLineStart
        self.leftLineCount = leftLineCount
        self.rightLineStart = rightLineStart
        self.rightLineCount = rightLineCount
        self.kind = kind
    }
}

// MARK: - Complete Comparison Result
public struct DiffResult: Equatable {
    public let leftLines: [DiffLineInfo]
    public let rightLines: [DiffLineInfo]
    public let chunks: [DiffChunk]
    public var activeChunkIndex: Int
    public let addedLinesCount: Int
    public let deletedLinesCount: Int
    public let modifiedLinesCount: Int

    public var addedCount: Int { addedLinesCount }
    public var deletedCount: Int { deletedLinesCount }
    public var modifiedCount: Int { modifiedLinesCount }

    public var totalDifferences: Int {
        chunks.count
    }

    public var isIdentical: Bool {
        totalDifferences == 0
    }

    public var activeChunk: DiffChunk? {
        guard activeChunkIndex >= 0 && activeChunkIndex < chunks.count else { return nil }
        return chunks[activeChunkIndex]
    }

    // Fast O(1) lookup tables by 1-based line number
    public let leftLineMap: [Int: DiffLineInfo]
    public let rightLineMap: [Int: DiffLineInfo]

    public init(
        leftLines: [DiffLineInfo],
        rightLines: [DiffLineInfo],
        chunks: [DiffChunk],
        activeChunkIndex: Int = 0,
        addedLinesCount: Int,
        deletedLinesCount: Int,
        modifiedLinesCount: Int
    ) {
        self.leftLines = leftLines
        self.rightLines = rightLines
        self.chunks = chunks
        self.activeChunkIndex = activeChunkIndex
        self.addedLinesCount = addedLinesCount
        self.deletedLinesCount = deletedLinesCount
        self.modifiedLinesCount = modifiedLinesCount

        var lMap: [Int: DiffLineInfo] = [:]
        for line in leftLines {
            lMap[line.lineNumber] = line
        }
        self.leftLineMap = lMap

        var rMap: [Int: DiffLineInfo] = [:]
        for line in rightLines {
            rMap[line.lineNumber] = line
        }
        self.rightLineMap = rMap
    }
}

// MARK: - Professional Myers Line Diff Engine
public enum FileComparisonService {

    private enum EditOp: Equatable {
        case keep(leftIdx: Int, rightIdx: Int)
        case delete(leftIdx: Int)
        case insert(rightIdx: Int)
    }

    public static func splitLines(_ text: String) -> [String] {
        if text.isEmpty { return [] }
        var lines = text.components(separatedBy: "\n")
        if lines.last == "" && text.hasSuffix("\n") {
            lines.removeLast()
        }
        return lines
    }

    /// Compares two documents line-by-line using Eugene Myers' diff algorithm
    /// with intra-line character range extraction for modified sections.
    public static func compare(leftText: String, rightText: String) -> DiffResult {
        let leftRawLines = splitLines(leftText)
        let rightRawLines = splitLines(rightText)

        // Fast path: Identical texts
        if leftText == rightText {
            let leftLines = leftRawLines.enumerated().map { idx, line in
                DiffLineInfo(lineNumber: idx + 1, kind: .unchanged, content: line)
            }
            let rightLines = rightRawLines.enumerated().map { idx, line in
                DiffLineInfo(lineNumber: idx + 1, kind: .unchanged, content: line)
            }
            return DiffResult(
                leftLines: leftLines,
                rightLines: rightLines,
                chunks: [],
                activeChunkIndex: 0,
                addedLinesCount: 0,
                deletedLinesCount: 0,
                modifiedLinesCount: 0
            )
        }

        // Fast path: Empty left (all added in right)
        if leftText.isEmpty && !rightText.isEmpty {
            let rightLines = rightRawLines.enumerated().map { idx, line in
                DiffLineInfo(lineNumber: idx + 1, kind: .added, content: line)
            }
            let chunk = DiffChunk(
                index: 0,
                leftLineStart: 0,
                leftLineCount: 0,
                rightLineStart: 1,
                rightLineCount: rightLines.count,
                kind: .added
            )
            return DiffResult(
                leftLines: [],
                rightLines: rightLines,
                chunks: [chunk],
                activeChunkIndex: 0,
                addedLinesCount: rightLines.count,
                deletedLinesCount: 0,
                modifiedLinesCount: 0
            )
        }

        // Fast path: Empty right (all deleted from left)
        if !leftText.isEmpty && rightText.isEmpty {
            let leftLines = leftRawLines.enumerated().map { idx, line in
                DiffLineInfo(lineNumber: idx + 1, kind: .deleted, content: line)
            }
            let chunk = DiffChunk(
                index: 0,
                leftLineStart: 1,
                leftLineCount: leftLines.count,
                rightLineStart: 0,
                rightLineCount: 0,
                kind: .deleted
            )
            return DiffResult(
                leftLines: leftLines,
                rightLines: [],
                chunks: [chunk],
                activeChunkIndex: 0,
                addedLinesCount: 0,
                deletedLinesCount: leftLines.count,
                modifiedLinesCount: 0
            )
        }

        // Compute Myers edit script
        let editScript = computeMyersEditScript(a: leftRawLines, b: rightRawLines)

        // Group edits into blocks and pair deletions with insertions as modifications
        var leftLines: [DiffLineInfo] = []
        var rightLines: [DiffLineInfo] = []
        var chunks: [DiffChunk] = []

        var addedCount = 0
        var deletedCount = 0
        var modifiedCount = 0

        var scriptIdx = 0
        let totalOps = editScript.count

        while scriptIdx < totalOps {
            let op = editScript[scriptIdx]

            switch op {
            case .keep(let lIdx, let rIdx):
                leftLines.append(DiffLineInfo(
                    lineNumber: lIdx + 1,
                    kind: .unchanged,
                    content: leftRawLines[lIdx]
                ))
                rightLines.append(DiffLineInfo(
                    lineNumber: rIdx + 1,
                    kind: .unchanged,
                    content: rightRawLines[rIdx]
                ))
                scriptIdx += 1

            case .delete, .insert:
                // Collect contiguous deletion & insertion sequence
                var delIndices: [Int] = []
                var insIndices: [Int] = []

                while scriptIdx < totalOps {
                    let curOp = editScript[scriptIdx]
                    if case .delete(let lIdx) = curOp {
                        delIndices.append(lIdx)
                        scriptIdx += 1
                    } else if case .insert(let rIdx) = curOp {
                        insIndices.append(rIdx)
                        scriptIdx += 1
                    } else {
                        break
                    }
                }

                // Determine if this is a modification (paired del + ins), pure addition, or pure deletion
                let lStart = delIndices.first.map { $0 + 1 } ?? 0
                let rStart = insIndices.first.map { $0 + 1 } ?? 0
                let lCount = delIndices.count
                let rCount = insIndices.count

                if lCount > 0 && rCount > 0 {
                    // Paired modifications
                    let pairMin = min(lCount, rCount)
                    for i in 0..<pairMin {
                        let lIdx = delIndices[i]
                        let rIdx = insIndices[i]
                        let lContent = leftRawLines[lIdx]
                        let rContent = rightRawLines[rIdx]
                        let (lRanges, rRanges) = computeIntraLineRanges(left: lContent, right: rContent)

                        leftLines.append(DiffLineInfo(
                            lineNumber: lIdx + 1,
                            kind: .modified,
                            content: lContent,
                            modifiedCharacterRanges: lRanges
                        ))
                        rightLines.append(DiffLineInfo(
                            lineNumber: rIdx + 1,
                            kind: .modified,
                            content: rContent,
                            modifiedCharacterRanges: rRanges
                        ))
                    }

                    // Any excess lines in either file
                    if lCount > pairMin {
                        for i in pairMin..<lCount {
                            let lIdx = delIndices[i]
                            leftLines.append(DiffLineInfo(
                                lineNumber: lIdx + 1,
                                kind: .deleted,
                                content: leftRawLines[lIdx]
                            ))
                        }
                    }
                    if rCount > pairMin {
                        for i in pairMin..<rCount {
                            let rIdx = insIndices[i]
                            rightLines.append(DiffLineInfo(
                                lineNumber: rIdx + 1,
                                kind: .added,
                                content: rightRawLines[rIdx]
                            ))
                        }
                    }

                    modifiedCount += pairMin
                    deletedCount += max(0, lCount - pairMin)
                    addedCount += max(0, rCount - pairMin)

                    let chunk = DiffChunk(
                        index: chunks.count,
                        leftLineStart: lStart,
                        leftLineCount: lCount,
                        rightLineStart: rStart,
                        rightLineCount: rCount,
                        kind: .modified
                    )
                    chunks.append(chunk)

                } else if lCount > 0 {
                    // Pure deletions (in left only)
                    for lIdx in delIndices {
                        leftLines.append(DiffLineInfo(
                            lineNumber: lIdx + 1,
                            kind: .deleted,
                            content: leftRawLines[lIdx]
                        ))
                    }
                    deletedCount += lCount

                    let chunk = DiffChunk(
                        index: chunks.count,
                        leftLineStart: lStart,
                        leftLineCount: lCount,
                        rightLineStart: 0,
                        rightLineCount: 0,
                        kind: .deleted
                    )
                    chunks.append(chunk)

                } else if rCount > 0 {
                    // Pure additions (in right only)
                    for rIdx in insIndices {
                        rightLines.append(DiffLineInfo(
                            lineNumber: rIdx + 1,
                            kind: .added,
                            content: rightRawLines[rIdx]
                        ))
                    }
                    addedCount += rCount

                    let chunk = DiffChunk(
                        index: chunks.count,
                        leftLineStart: 0,
                        leftLineCount: 0,
                        rightLineStart: rStart,
                        rightLineCount: rCount,
                        kind: .added
                    )
                    chunks.append(chunk)
                }
            }
        }

        // Sort leftLines and rightLines by 1-based lineNumber to guarantee ascending order
        let sortedLeft = leftLines.sorted { $0.lineNumber < $1.lineNumber }
        let sortedRight = rightLines.sorted { $0.lineNumber < $1.lineNumber }

        return DiffResult(
            leftLines: sortedLeft,
            rightLines: sortedRight,
            chunks: chunks,
            activeChunkIndex: 0,
            addedLinesCount: addedCount,
            deletedLinesCount: deletedCount,
            modifiedLinesCount: modifiedCount
        )
    }

    // MARK: - Myers O(ND) Greedy Diff Implementation
    private static func computeMyersEditScript(a: [String], b: [String]) -> [EditOp] {
        let n = a.count
        let m = b.count
        let maxD = n + m
        if maxD == 0 { return [] }

        // V array offset by maxD
        let offset = maxD
        var v = [Int](repeating: 0, count: 2 * maxD + 1)
        var trace: [[Int]] = []

        var foundD = 0
        outerLoop: for d in 0...maxD {
            trace.append(v)
            for k in stride(from: -d, through: d, by: 2) {
                var x: Int
                if k == -d || (k != d && v[k - 1 + offset] < v[k + 1 + offset]) {
                    x = v[k + 1 + offset]
                } else {
                    x = v[k - 1 + offset] + 1
                }
                var y = x - k
                while x < n && y < m && a[x] == b[y] {
                    x += 1
                    y += 1
                }
                v[k + offset] = x
                if x >= n && y >= m {
                    foundD = d
                    break outerLoop
                }
            }
        }

        // Backtrack from trace to reconstruct edit operations
        var script: [EditOp] = []
        var x = n
        var y = m

        for d in stride(from: foundD, through: 1, by: -1) {
            let prevV = trace[d]
            let k = x - y
            var prevK: Int
            if k == -d || (k != d && prevV[k - 1 + offset] < prevV[k + 1 + offset]) {
                prevK = k + 1
            } else {
                prevK = k - 1
            }
            let prevX = prevV[prevK + offset]
            let prevY = prevX - prevK

            while x > prevX && y > prevY {
                script.append(.keep(leftIdx: x - 1, rightIdx: y - 1))
                x -= 1
                y -= 1
            }

            if x == prevX {
                script.append(.insert(rightIdx: prevY))
                y -= 1
            } else {
                script.append(.delete(leftIdx: prevX))
                x -= 1
            }
        }

        while x > 0 && y > 0 {
            script.append(.keep(leftIdx: x - 1, rightIdx: y - 1))
            x -= 1
            y -= 1
        }

        return script.reversed()
    }

    // MARK: - Intra-Line Character Range Extraction
    /// Identifies differing character substrings within two modified lines
    public static func computeIntraLineRanges(left: String, right: String) -> ([NSRange], [NSRange]) {
        let leftUtf16 = Array(left.utf16)
        let rightUtf16 = Array(right.utf16)
        let lLen = leftUtf16.count
        let rLen = rightUtf16.count

        if lLen == 0 || rLen == 0 {
            let lRange = lLen > 0 ? [NSRange(location: 0, length: lLen)] : []
            let rRange = rLen > 0 ? [NSRange(location: 0, length: rLen)] : []
            return (lRange, rRange)
        }

        // Find common prefix
        var prefixLen = 0
        while prefixLen < lLen && prefixLen < rLen && leftUtf16[prefixLen] == rightUtf16[prefixLen] {
            prefixLen += 1
        }

        // Find common suffix
        var suffixLen = 0
        while suffixLen < (lLen - prefixLen) && suffixLen < (rLen - prefixLen) &&
              leftUtf16[lLen - 1 - suffixLen] == rightUtf16[rLen - 1 - suffixLen] {
            suffixLen += 1
        }

        let lDiffLen = lLen - prefixLen - suffixLen
        let rDiffLen = rLen - prefixLen - suffixLen

        let leftRanges = lDiffLen > 0 ? [NSRange(location: prefixLen, length: lDiffLen)] : []
        let rightRanges = rDiffLen > 0 ? [NSRange(location: prefixLen, length: rDiffLen)] : []

        return (leftRanges, rightRanges)
    }
}
