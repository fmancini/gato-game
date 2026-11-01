import Foundation

public enum Mark: String, Sendable {
    case x = "X", o = "O"
    public var other: Mark { self == .x ? .o : .x }
}

/// A 3x3 board. Cells are numbered 0...8, left to right, top to bottom.
public struct Board: Equatable, Sendable {
    public private(set) var cells: [Mark?] = Array(repeating: nil, count: 9)

    public static let lines: [[Int]] = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],
        [0, 3, 6], [1, 4, 7], [2, 5, 8],
        [0, 4, 8], [2, 4, 6],
    ]

    public init() {}

    public var winner: Mark? {
        for line in Self.lines {
            if let m = cells[line[0]], cells[line[1]] == m, cells[line[2]] == m { return m }
        }
        return nil
    }

    public var winningLine: [Int]? {
        Self.lines.first { l in
            if let m = cells[l[0]] { return cells[l[1]] == m && cells[l[2]] == m }
            return false
        }
    }

    public var isFull: Bool { !cells.contains(where: { $0 == nil }) }
    public var isOver: Bool { winner != nil || isFull }
    public var isDraw: Bool { winner == nil && isFull }
    public var emptyCells: [Int] { cells.indices.filter { cells[$0] == nil } }

    /// Places a mark. Returns false when the cell is taken or the game is over.
    @discardableResult
    public mutating func play(_ index: Int, _ mark: Mark) -> Bool {
        guard cells.indices.contains(index), cells[index] == nil, !isOver else { return false }
        cells[index] = mark
        return true
    }
}

public enum Difficulty: String, CaseIterable, Identifiable, Sendable {
    case easy, hard
    public var id: String { rawValue }
}

public enum Computer {
    /// Picks a move for `mark`. Hard never loses (minimax); easy plays a random
    /// cell, but still takes a win and blocks a loss half of the time.
    public static func move(on board: Board, for mark: Mark, difficulty: Difficulty) -> Int? {
        let empty = board.emptyCells
        guard !empty.isEmpty else { return nil }
        switch difficulty {
        case .hard:
            return empty.max { score(board, playing: $0, as: mark) < score(board, playing: $1, as: mark) }
        case .easy:
            if Bool.random() {
                for m in [mark, mark.other] {
                    if let cell = empty.first(where: { var b = board; b.play($0, m); return b.winner == m }) { return cell }
                }
            }
            return empty.randomElement()
        }
    }

    /// Minimax score of playing `index`: positive is good for `me`. Faster wins score higher.
    private static func score(_ board: Board, playing index: Int, as me: Mark) -> Int {
        var b = board
        b.play(index, me)
        return minimax(b, turn: me.other, me: me)
    }

    private static func minimax(_ board: Board, turn: Mark, me: Mark) -> Int {
        if let w = board.winner { return (w == me ? 1 : -1) * (board.emptyCells.count + 1) }
        if board.isFull { return 0 }
        let scores = board.emptyCells.map { i -> Int in
            var b = board
            b.play(i, turn)
            return minimax(b, turn: turn.other, me: me)
        }
        return turn == me ? scores.max()! : scores.min()!
    }
}
