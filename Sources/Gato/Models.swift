import Foundation
import GatoKit

/// The sidebar pages: one per way to play. Snapshot mode walks through every case.
enum SidebarItem: String, CaseIterable, Identifiable {
    case computer, twoPlayers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .computer: "Contra la computadora"
        case .twoPlayers: "Dos jugadores"
        }
    }

    var symbol: String {
        switch self {
        case .computer: "desktopcomputer"
        case .twoPlayers: "person.2"
        }
    }
}

/// App-wide state that menus, toolbars, and views share.
@Observable
final class AppModel {
    var sidebar: SidebarItem? = .computer {
        didSet { if sidebar != oldValue { resetScores() } }
    }
    var board = Board()
    var turn: Mark = .x
    var firstPlayer: Mark = .x
    var scoreX = 0
    var scoreO = 0
    var draws = 0
    /// In "Contra la computadora" the person plays X.
    var computerThinking = false
    /// Settings reopens on the last tab. Test and snapshot runs leave it alone.
    var settingsTab: SettingsTab = SettingsTab(rawValue: UserDefaults.standard.string(forKey: "settings.tab") ?? "") ?? .general {
        didSet { if !Store.isOverridden { UserDefaults.standard.set(settingsTab.rawValue, forKey: "settings.tab") } }
    }

    var vsComputer: Bool { sidebar != .twoPlayers }

    var difficulty: Difficulty {
        Difficulty(rawValue: UserDefaults.standard.string(forKey: "difficulty") ?? "") ?? .hard
    }

    var status: String {
        if let w = board.winner {
            if vsComputer { return w == .x ? "¡Ganaste!" : "Ganó la computadora" }
            return "¡Ganó \(w.rawValue)!"
        }
        if board.isDraw { return "Empate" }
        if vsComputer { return computerThinking ? "Pensando…" : "Tu turno (X)" }
        return "Turno de \(turn.rawValue)"
    }

    func tap(_ index: Int) {
        guard !computerThinking, !(vsComputer && turn == .o) else { return }
        place(index)
    }

    private func place(_ index: Int) {
        guard board.play(index, turn) else { return }
        if let w = board.winner {
            if w == .x { scoreX += 1 } else { scoreO += 1 }
        } else if board.isDraw {
            draws += 1
        } else {
            turn = turn.other
            computerTurnIfNeeded()
        }
    }

    private func computerTurnIfNeeded() {
        guard vsComputer, turn == .o, !board.isOver else { return }
        computerThinking = true
        let snapshot = board
        let level = difficulty
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            // A new game may have started while waiting.
            guard computerThinking, board == snapshot else { return }
            computerThinking = false
            if let move = Computer.move(on: board, for: .o, difficulty: level) { place(move) }
        }
    }

    /// New round: the starting player alternates.
    func newGame() {
        board = Board()
        computerThinking = false
        firstPlayer = firstPlayer.other
        turn = firstPlayer
        computerTurnIfNeeded()
    }

    func resetScores() {
        scoreX = 0; scoreO = 0; draws = 0
        board = Board()
        computerThinking = false
        firstPlayer = .x
        turn = .x
    }
}
