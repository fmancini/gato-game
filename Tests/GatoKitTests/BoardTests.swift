import Testing
@testable import GatoKit

@Test func detectsRowWin() {
    var b = Board()
    for i in [0, 1, 2] { b.play(i, .x) }
    #expect(b.winner == .x)
    #expect(b.winningLine == [0, 1, 2])
}

@Test func rejectsTakenCellAndMovesAfterEnd() {
    var b = Board()
    let first = b.play(4, .x)
    let again = b.play(4, .o)
    #expect(first)
    #expect(!again)
    for i in [0, 8] { b.play(i, .x) }
    #expect(b.winner == .x)
    let late = b.play(1, .o)
    #expect(!late)
}

@Test func detectsDraw() {
    var b = Board()
    let marks: [Mark] = [.x, .o, .x, .x, .o, .o, .o, .x, .x]
    for (i, m) in marks.enumerated() { b.play(i, m) }
    #expect(b.isDraw)
}

@Test func hardTakesWinAndBlocks() {
    var b = Board()
    for i in [0, 1] { b.play(i, .x) }
    #expect(Computer.move(on: b, for: .x, difficulty: .hard) == 2)
    #expect(Computer.move(on: b, for: .o, difficulty: .hard) == 2)
}

@Test func hardNeverLosesToAnyPlay() {
    // Human (X) tries every possible reply; hard O must never lose.
    func explore(_ b: Board, xTurn: Bool) -> Bool {
        if let w = b.winner { return w == .o ? true : false }
        if b.isFull { return true }
        if xTurn {
            return b.emptyCells.allSatisfy { i in var n = b; n.play(i, .x); return explore(n, xTurn: false) }
        }
        var n = b
        n.play(Computer.move(on: b, for: .o, difficulty: .hard)!, .o)
        return explore(n, xTurn: true)
    }
    #expect(explore(Board(), xTurn: true))
}
