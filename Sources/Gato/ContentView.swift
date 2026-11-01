import GatoKit
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            GameView()
        }
        .task {
            SelfTest.runIfRequested(model: model)
            Snapshot.runIfRequested(model: model, openSettings: openSettings)
        }
    }

    private var sidebar: some View {
        @Bindable var model = model
        return List(SidebarItem.allCases, selection: $model.sidebar) { page in
            Label(page.title, systemImage: page.symbol)
                .tag(page)
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }
}

struct GameView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: Space.xxl) {
            scores
            Text(model.status)
                .font(.title2.weight(.semibold))
                .contentTransition(.opacity)
            BoardView()
            Button("Nueva partida", systemImage: "arrow.counterclockwise") { model.newGame() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut("n")
        }
        .padding(Space.section)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(model.sidebar?.title ?? "El Gato")
        .gridArea("game")
    }

    private var scores: some View {
        HStack(spacing: Space.xxl) {
            score(model.vsComputer ? "Tú (X)" : "Jugador X", model.scoreX)
            score("Empates", model.draws)
            score(model.vsComputer ? "Computadora (O)" : "Jugador O", model.scoreO)
        }
    }

    private func score(_ title: String, _ value: Int) -> some View {
        VStack(spacing: Space.xs) {
            Text("\(value)").font(.largeTitle.monospacedDigit().weight(.bold))
            Text(title).font(.callout).foregroundStyle(.secondary)
        }
        .frame(minWidth: 112)
    }
}

struct BoardView: View {
    @Environment(AppModel.self) private var model
    private let side: CGFloat = 340
    private let gap = Space.sm

    var body: some View {
        let cell = (side - 2 * gap) / 3
        let columns = Array(repeating: GridItem(.fixed(cell), spacing: gap), count: 3)
        LazyVGrid(columns: columns, spacing: gap) {
            ForEach(0..<9, id: \.self) { i in
                CellView(index: i, size: cell)
            }
        }
        .frame(width: side, height: side)
    }
}

struct CellView: View {
    @Environment(AppModel.self) private var model
    let index: Int
    let size: CGFloat

    var body: some View {
        let mark = model.board.cells[index]
        let winning = model.board.winningLine?.contains(index) ?? false
        Button { model.tap(index) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Space.md)
                    .fill(winning ? Palette.accent.opacity(0.25) : Color.primary.opacity(0.06))
                if let mark {
                    Text(mark.rawValue)
                        .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
                        .foregroundStyle(mark == .x ? Palette.accentText : Color.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: size, height: size)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(mark != nil || model.board.isOver)
        .animation(.snappy(duration: 0.2), value: mark)
        .accessibilityLabel(mark.map { "Casilla \(index + 1), \($0.rawValue)" } ?? "Casilla \(index + 1), vacía")
    }
}
