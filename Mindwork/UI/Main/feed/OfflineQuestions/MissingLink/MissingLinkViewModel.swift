import SwiftUI
import Combine
import FirebaseFirestore

final class MissingLinkViewModel: BaseViewModel {
    private enum Phase { case showing, quiz, finished }
    private var phase: Phase = .showing
    
    private let lastQuestionNumber = 10
    private let showDurationSeconds = 4
    
    @Published var timeCounter: Double = 0.0
    @Published var uiTick: Int = 0
    @Published var questionNumber = 1 { didSet { updateProgress() } }
    @Published var questionProgress = 0.1
    @Published var questionTitle: LocalizedStringKey = "Nesneleri aklında tut!"
    @Published var isTrue: Bool? = nil
    @Published var gameOver = false
    @Published var preparingGame = true
    @Published var answeredQuestion = false
    @Published var selectedOption: String? = nil // Görsel geri bildirim için

    @Published var displayItems: [String] = []
    @Published var options: [String] = []
    private var missingItem: String = ""
    
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var averageResponseTime: Double = 0.0
    @Published var percentageTruth: Double = 0.0
    private var totalResponseTime: Double = 0.0
    
    private let allItems = ["🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍒", "🍑", "🥭", "🍍", "🥥", "🥑", "🥦"]
    private var gameTimer = Timer()
    private var uiTimer = Timer()

    override init() {
        super.init()
        setupNewLevel()
        startUiTimer()
    }

    func setupNewLevel() {
        phase = .showing
        preparingGame = true
        answeredQuestion = true
        isTrue = nil
        uiTick = 0
        selectedOption = nil
        
        let count = min(allItems.count - 4, 3 + (questionNumber / 2))
        let selected = allItems.shuffled().prefix(count).map { String($0) }
        
        missingItem = selected.randomElement()!
        displayItems = selected
        
        var opts = [missingItem]
        let remainingPool = allItems.filter { !selected.contains($0) }.shuffled()
        opts.append(contentsOf: remainingPool.prefix(3))
        options = opts.shuffled()
        
        questionTitle = "Nesneleri aklında tut!"
    }

    private func startQuizPhase() {
        phase = .quiz
        preparingGame = false
        answeredQuestion = false
        timeCounter = 0
        
        withAnimation {
            displayItems.removeAll { $0 == missingItem }
            questionTitle = "Hangi nesne kayboldu?"
        }
        startGameTimer()
    }

    func checkAnswer(selected: String) {
        guard phase == .quiz, !answeredQuestion else { return }
        self.selectedOption = selected
        stopGameTimer()
        answeredQuestion = true
        
        if selected == missingItem {
            correctCount += 1
            isTrue = true
        } else {
            wrongCount += 1
            isTrue = false
        }
        
        accumulateStats()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.nextQuestion()
        }
    }

    func nextQuestion() {
        if questionNumber >= lastQuestionNumber {
            endGame()
        } else {
            questionNumber += 1
            setupNewLevel()
        }
    }

    func getMissingItem() -> String { missingItem }

    private func endGame() {
        phase = .finished
        let total = Double(max(1, correctCount + wrongCount))
        percentageTruth = (Double(correctCount) / 10.0) * 100
        gameOver = true
        
        getDataCall {
            try await FirestorageManager.shared.saveGame(
                gameData: GameStoreModel(
                    successRate: Double(self.correctCount) / 10.0,
                    gameType: .missing_link,
                    date: Timestamp(date: Date()),
                    averageTime: self.averageResponseTime
                )
            )
        } onSuccess: { _ in
            print("Kaydedildi.")
        } onLoading: {
            // Bu kısım eksik olduğu için hata veriyordu
        } onError: { error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
            }
        }
    }

    func startAgain() {
        questionNumber = 1
        correctCount = 0
        wrongCount = 0
        totalResponseTime = 0
        gameOver = false
        setupNewLevel()
    }

    private func startUiTimer() {
        uiTimer.invalidate()
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.phase == .showing {
                self.uiTick += 1
                if self.uiTick >= self.showDurationSeconds { self.startQuizPhase() }
            }
        }
        RunLoop.main.add(uiTimer, forMode: .common)
    }

    private func startGameTimer() {
        gameTimer.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.timeCounter += 0.01
        }
        RunLoop.main.add(gameTimer, forMode: .common)
    }

    private func stopGameTimer() { gameTimer.invalidate() }

    private func accumulateStats() {
        totalResponseTime += timeCounter
        averageResponseTime = totalResponseTime / Double(max(1, correctCount + wrongCount))
    }

    private func updateProgress() {
        questionProgress = Double(questionNumber) / Double(lastQuestionNumber)
    }
}
