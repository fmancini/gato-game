import AppKit
import GatoKit

/// Self-test for agents: runs the app's real functions on a test store,
/// prints PASS or FAIL per check, and quits with exit code 0 or 1.
///   APP_STORE=/tmp/Gato-self.store ~/Applications/Gato.app/Contents/MacOS/Gato --selftest
/// (tools/selftest.sh does this.) Add a check for every story with logic.
@MainActor
enum SelfTest {
    static var requested: Bool { CommandLine.arguments.contains("--selftest") }
    /// Read by AppDelegate.applicationWillTerminate.
    static var exitCode: Int32 = 0
    private static var failures = 0
    private static var count = 0

    static func runIfRequested(model: AppModel) {
        guard requested else { return }
        // Print each line at once, so a crash keeps the lines before it.
        setvbuf(stdout, nil, _IOLBF, 0)
        guard Store.isOverridden else {
            print("SELFTEST refused: set APP_STORE to a file in /tmp")
            finish(code: 1)
            return
        }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            model.sidebar = .twoPlayers
            model.tap(0); model.tap(3); model.tap(1); model.tap(4); model.tap(2)
            check("X wins the top row", model.board.winner == .x)
            check("score counts the win", model.scoreX == 1)
            model.tap(8)
            check("no moves after the game ends", model.board.cells[8] == nil)
            model.newGame()
            check("new game clears the board", model.board.emptyCells.count == 9)
            check("the first player alternates", model.turn == .o)

            model.sidebar = .computer
            check("switching mode resets the score", model.scoreX == 0)
            model.tap(4)
            try? await Task.sleep(for: .seconds(1))
            check("the computer answers", model.board.emptyCells.count == 7)

            print(failures == 0 ? "SELFTEST PASS \(count) checks" : "SELFTEST FAIL \(failures) of \(count) checks")
            finish(code: failures == 0 ? 0 : 1)
        }
    }

    private static func check(_ name: String, _ ok: Bool, _ detail: String = "") {
        count += 1
        if !ok { failures += 1 }
        print(ok ? "PASS \(name)" : "FAIL \(name)\(detail.isEmpty ? "" : ": \(detail)")")
    }

    /// Quits through NSApp.terminate, never exit(), and closes sheets first:
    /// an open sheet refuses terminate, and the run would wait forever.
    static func finish(code: Int32) {
        exitCode = code
        for window in NSApp.windows { if let sheet = window.attachedSheet { window.endSheet(sheet) } }
        NSApp.terminate(nil)
    }
}
