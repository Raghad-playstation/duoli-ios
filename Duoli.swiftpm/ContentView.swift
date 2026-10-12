
import SwiftUI

// MARK: - Card Model

struct DessertCard: Identifiable {
    let id = UUID()
    let imageName: String
    var isFaceUp = false
    var isMatched = false
}

// MARK: - Duoli

struct ContentView: View {

    private enum Screen {
        case welcome
        case modes
        case difficulty
        case game
        case results
    }

    private enum GameMode {
        case classic
        case challenge
    }

    // MARK: - State

    @State private var screen: Screen = .welcome
    @State private var mode: GameMode = .classic

    @State private var cards: [DessertCard] = []
    @State private var selectedCards: [UUID] = []

    @State private var isChecking = false
    @State private var pairCount = 2

    @State private var moves = 0
    @State private var totalMoves = 0
    @State private var roundsCleared = 0

    @State private var elapsedSeconds = 0
    @State private var remainingSeconds = 120

    @State private var gameID = UUID()
    @State private var timerID = UUID()

    // MARK: - Saved Records

    @AppStorage("duoliBestClassicEasy")
    private var bestClassicEasy = -1

    @AppStorage("duoliBestClassicMedium")
    private var bestClassicMedium = -1

    @AppStorage("duoliBestClassicHard")
    private var bestClassicHard = -1

    @AppStorage("duoliBestChallengeRounds")
    private var bestChallengeRounds = 0

    // MARK: - Design

    private let retroFont = "VaguelyRetro-Regular"

    private let wrongMatchDelay: UInt64 = 1_300_000_000

    private let desserts = [
        "pie",
        "croissant",
        "strawberry_slice",
        "swiss_roll",
        "blueberry_pancakes",
        "cookie",
        "strawberry_cake",
        "blueberry_cake",
        "cupcake"
    ]

    private let background = Color(
        red: 1.0,
        green: 0.97,
        blue: 0.94
    )

    private let pink = Color(
        red: 1.0,
        green: 0.52,
        blue: 0.47
    )

    private let chocolate = Color(
        red: 0.47,
        green: 0.30,
        blue: 0.27
    )

    private let columns = [
        GridItem(
            .adaptive(minimum: 85, maximum: 115),
            spacing: 12
        )
    ]

    private func retro(_ size: CGFloat) -> Font {
        .custom(retroFont, size: size)
    }

    private func rounded(_ size: CGFloat) -> Font {
        .system(
            size: size,
            weight: .semibold,
            design: .rounded
        )
    }

    // MARK: - Main View

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            Group {
                switch screen {
                case .welcome:
                    welcomeScreen

                case .modes:
                    modesScreen

                case .difficulty:
                    difficultyScreen

                case .game:
                    gameScreen

                case .results:
                    resultsScreen
                }
            }
            .padding(20)
        }
    }

    // MARK: - Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            dessertImage("strawberry_cake", size: 190)

            Text("Duoli")
                .font(retro(62))
                .foregroundColor(pink)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text("A little play, a lot to remember!")
                .font(rounded(19))
                .foregroundColor(chocolate)
                .multilineTextAlignment(.center)

            Spacer()

            mainButton("Let's Play!") {
                screen = .modes
            }

            Spacer()
        }
    }

    // MARK: - Game Modes

    private var modesScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            dessertImage("cupcake", size: 115)

            Text("Choose Your Game")
                .font(retro(31))
                .foregroundColor(pink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            modeButton(
                "Classic Mode",
                subtitle: "Find every pair at your own pace",
                icon: "heart.fill"
            ) {
                mode = .classic
                screen = .difficulty
            }

            modeButton(
                "Sweet Challenge",
                subtitle: "How many rounds can you clear in 2 minutes?",
                icon: "timer"
            ) {
                startChallenge()
            }

            Button("← Back") {
                screen = .welcome
            }
            .font(rounded(17))
            .foregroundColor(chocolate)

            Spacer()
        }
    }

    private func modeButton(
        _ title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(pink)
                    .frame(width: 35)

                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .font(retro(19))
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(rounded(14))
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .foregroundColor(chocolate)
            .padding(20)
            .frame(maxWidth: 360)
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 24)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Difficulty

    private var difficultyScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            dessertImage("cookie", size: 115)

            Text("Choose Difficulty")
                .font(retro(31))
                .foregroundColor(pink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)

            difficultyButton("Easy", pairs: 2)
            difficultyButton("Medium", pairs: 3)
            difficultyButton("Hard", pairs: 6)

            Button("← Back") {
                screen = .modes
            }
            .font(rounded(17))
            .foregroundColor(chocolate)

            Spacer()
        }
    }

    private func difficultyButton(
        _ title: String,
        pairs: Int
    ) -> some View {
        Button {
            startClassic(pairs: pairs)
        } label: {
            HStack {
                Text(title)
                    .font(retro(23))

                Spacer()

                Text("\(pairs) pairs")
                    .font(rounded(16))
            }
            .foregroundColor(chocolate)
            .padding(20)
            .frame(maxWidth: 350)
            .background(.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 24)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game Screen

    private var gameScreen: some View {
        VStack(spacing: 16) {
            HStack {
                Button("← Exit") {
                    exitGame()
                }

                Spacer()

                Text("Duoli")
                    .font(retro(20))
            }
            .font(rounded(16))
            .foregroundColor(chocolate)

            Spacer(minLength: 4)

            Text(
                mode == .classic
                ? "Find the Pair!"
                : "Sweet Challenge!"
            )
            .font(retro(31))
            .foregroundColor(pink)
            .minimumScaleFactor(0.65)
            .lineLimit(1)

            if mode == .challenge {
                Text("Round \(roundsCleared + 1)")
                    .font(retro(18))
                    .foregroundColor(chocolate)
            }

            Text(
                mode == .classic
                ? formattedTime(elapsedSeconds)
                : formattedTime(remainingSeconds)
            )
            .font(
                .system(
                    size: 42,
                    weight: .heavy,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .foregroundColor(
                mode == .challenge && remainingSeconds <= 20
                ? .red
                : pink
            )

            HStack {
                Text("Moves: \(moves)")

                Spacer()

                Text(
                    "Pairs: \(cards.filter { $0.isMatched }.count / 2)/\(pairCount)"
                )
            }
            .font(rounded(16))
            .foregroundColor(chocolate)
            .frame(maxWidth: 390)

            if mode == .challenge {
                Text("Rounds cleared: \(roundsCleared)")
                    .font(rounded(15))
                    .foregroundColor(chocolate)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(cards) { card in
                    Button {
                        flipCard(card.id)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    card.isMatched
                                    ? Color(
                                        red: 0.82,
                                        green: 0.94,
                                        blue: 0.82
                                    )
                                    : card.isFaceUp
                                    ? .white
                                    : pink
                                )

                            if card.isFaceUp || card.isMatched {
                                Image(card.imageName)
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .padding(8)
                                    .transition(.opacity)
                            } else {
                                Text("?")
                                    .font(retro(37))
                                    .foregroundColor(.white)
                                    .transition(.opacity)
                            }
                        }
                        .frame(height: 100)
                        .animation(
                            .easeInOut(duration: 0.22),
                            value: card.isFaceUp
                        )
                        .animation(
                            .easeInOut(duration: 0.22),
                            value: card.isMatched
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        card.isMatched ||
                        card.isFaceUp ||
                        isChecking
                    )
                }
            }
            .frame(maxWidth: 390)

            Spacer(minLength: 4)

            Button(
                mode == .classic
                ? "Restart Game"
                : "Restart Challenge"
            ) {
                if mode == .classic {
                    startClassic(pairs: pairCount)
                } else {
                    startChallenge()
                }
            }
            .font(retro(17))
            .foregroundColor(chocolate)
        }
    }

    // MARK: - Results

    private var resultsScreen: some View {
        VStack(spacing: 20) {
            Spacer()

            dessertImage("strawberry_cake", size: 140)

            Text(
                mode == .classic
                ? "Sweet Success!"
                : "Challenge Complete!"
            )
            .font(retro(30))
            .foregroundColor(pink)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.7)

            if mode == .classic {
                resultLine(
                    "Your Time",
                    formattedTime(elapsedSeconds)
                )

                resultLine("Moves", "\(moves)")

                let best = bestTime(for: pairCount)

                if best >= 0 {
                    resultLine(
                        "Best Time",
                        formattedTime(best)
                    )
                }
            } else {
                resultLine(
                    "Rounds Cleared",
                    "\(roundsCleared)"
                )

                resultLine(
                    "Total Moves",
                    "\(totalMoves)"
                )

                resultLine(
                    "Best Challenge",
                    "\(bestChallengeRounds) rounds"
                )
            }

            Spacer()

            mainButton("Play Again") {
                if mode == .classic {
                    startClassic(pairs: pairCount)
                } else {
                    startChallenge()
                }
            }

            Button("Choose Game Mode") {
                stopTimer()
                screen = .modes
            }
            .font(retro(16))
            .foregroundColor(chocolate)

            Button("Home") {
                stopTimer()
                screen = .welcome
            }
            .font(retro(16))
            .foregroundColor(chocolate)

            Spacer()
        }
    }

    private func resultLine(
        _ label: String,
        _ value: String
    ) -> some View {
        HStack {
            Text(label)

            Spacer()

            Text(value)
                .bold()
        }
        .font(rounded(16))
        .foregroundColor(chocolate)
        .padding(16)
        .frame(maxWidth: 350)
        .background(.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    // MARK: - Shared Components

    private func dessertImage(
        _ name: String,
        size: CGFloat
    ) -> some View {
        Image(name)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: size, height: size)
    }

    private func mainButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(retro(23))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 18)
                .frame(maxWidth: 290)
                .background(pink)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Game Setup

    private func startClassic(pairs: Int) {
        stopTimer()

        mode = .classic
        pairCount = pairs

        elapsedSeconds = 0
        totalMoves = 0
        roundsCleared = 0

        createCards(pairs: pairs)

        screen = .game
        startTimer()
    }

    private func startChallenge() {
        stopTimer()

        mode = .challenge

        remainingSeconds = 120
        elapsedSeconds = 0

        roundsCleared = 0
        totalMoves = 0

        createCards(pairs: 2)

        screen = .game
        startTimer()
    }

    private func startNextChallengeRound() {
        guard remainingSeconds > 0 else {
            finishChallenge()
            return
        }

        let nextPairs = roundsCleared == 1 ? 3 : 6

        createCards(pairs: nextPairs)
        screen = .game
    }

    private func createCards(pairs: Int) {
        gameID = UUID()

        pairCount = pairs
        moves = 0

        isChecking = false
        selectedCards = []

        let chosen = Array(
            desserts.shuffled().prefix(pairs)
        )

        let imageNames = chosen + chosen

        cards = imageNames.map {
            DessertCard(imageName: $0)
        }

        cards.shuffle()
    }

    // MARK: - Matching Logic

    private func flipCard(_ id: UUID) {
        guard screen == .game else { return }
        guard !isChecking else { return }
        guard selectedCards.count < 2 else { return }

        guard let index = cards.firstIndex(
            where: { $0.id == id }
        ) else {
            return
        }

        guard !cards[index].isFaceUp else { return }
        guard !cards[index].isMatched else { return }

        withAnimation(.easeInOut(duration: 0.22)) {
            cards[index].isFaceUp = true
        }

        selectedCards.append(id)

        guard selectedCards.count == 2 else {
            return
        }

        moves += 1
        totalMoves += 1
        isChecking = true

        let firstID = selectedCards[0]
        let secondID = selectedCards[1]

        guard
            let firstIndex = cards.firstIndex(
                where: { $0.id == firstID }
            ),
            let secondIndex = cards.firstIndex(
                where: { $0.id == secondID }
            )
        else {
            selectedCards = []
            isChecking = false
            return
        }

        if cards[firstIndex].imageName ==
            cards[secondIndex].imageName {

            withAnimation(.easeInOut(duration: 0.22)) {
                cards[firstIndex].isMatched = true
                cards[secondIndex].isMatched = true
            }

            selectedCards = []
            isChecking = false

            if cards.allSatisfy({ $0.isMatched }) {
                completeRound()
            }

        } else {
            let currentGameID = gameID

            Task { @MainActor in
                try? await Task.sleep(
                    nanoseconds: wrongMatchDelay
                )

                guard gameID == currentGameID else {
                    return
                }

                withAnimation(.easeInOut(duration: 0.22)) {
                    for selectedID in [firstID, secondID] {
                        if let cardIndex = cards.firstIndex(
                            where: { $0.id == selectedID }
                        ) {
                            cards[cardIndex].isFaceUp = false
                        }
                    }
                }

                selectedCards = []
                isChecking = false
            }
        }
    }

    // MARK: - Round Completion

    private func completeRound() {
        gameID = UUID()

        if mode == .classic {
            stopTimer()
            saveClassicRecord()
            screen = .results
        } else {
            roundsCleared += 1

            if roundsCleared > bestChallengeRounds {
                bestChallengeRounds = roundsCleared
            }

            startNextChallengeRound()
        }
    }

    // MARK: - Records

    private func bestTime(for pairs: Int) -> Int {
        switch pairs {
        case 2:
            return bestClassicEasy
        case 3:
            return bestClassicMedium
        default:
            return bestClassicHard
        }
    }

    private func saveClassicRecord() {
        let currentBest = bestTime(for: pairCount)

        guard currentBest < 0 ||
              elapsedSeconds < currentBest else {
            return
        }

        switch pairCount {
        case 2:
            bestClassicEasy = elapsedSeconds
        case 3:
            bestClassicMedium = elapsedSeconds
        default:
            bestClassicHard = elapsedSeconds
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerID = UUID()
        let currentTimerID = timerID

        Task { @MainActor in
            while timerID == currentTimerID {
                try? await Task.sleep(
                    nanoseconds: 1_000_000_000
                )

                guard timerID == currentTimerID else {
                    return
                }

                if mode == .classic {
                    elapsedSeconds += 1
                } else {
                    remainingSeconds -= 1

                    if remainingSeconds <= 0 {
                        remainingSeconds = 0
                        finishChallenge()
                        return
                    }
                }
            }
        }
    }

    private func stopTimer() {
        timerID = UUID()
    }

    private func finishChallenge() {
        guard mode == .challenge else { return }

        stopTimer()
        gameID = UUID()

        if roundsCleared > bestChallengeRounds {
            bestChallengeRounds = roundsCleared
        }

        screen = .results
    }

    private func exitGame() {
        stopTimer()
        gameID = UUID()

        selectedCards = []
        isChecking = false

        screen = .modes
    }

    // MARK: - Time Formatting

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remaining = seconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            remaining
        )
    }
}
