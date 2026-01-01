import Foundation
import Combine
import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct WhichDifferentOption {
    let imageName: String
    let isDifferent: Bool
}

struct WDImagePair: Equatable {
    let mainImage: String
    let differentImage: String
}

final class WhichDifferentViewModel: BaseViewModel {
    let lastQuestionNumber = 10
    let timeLimit: Double = 10.0
    
    @Published var timeCounter: Double = 10.0
    @Published var uiTick: Int = 0
    @Published var questionNumber = 1 { didSet { updateProgress() } }
    @Published var questionProgress = 0.1
    @Published var questionTitle: LocalizedStringKey = StringKey.empty
    @Published var answeredQuestion = false
    @Published var isAnswerTrue = false
    @Published var gameOver = false
    @Published var currentOptions: [WhichDifferentOption] = []
    
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var averageResponseTime: Double = 0.0
    @Published var percentageTruth: Double = 0.0
    private var totalResponseTime: Double = 0.0
    private var totalAnswered: Int = 0
    
    private var gameTimer = Timer()
    private var uiTimer = Timer()
    
    private var easyPairs: [WDImagePair] = []
    private var mediumPairs: [WDImagePair] = []
    private var hardPairs: [WDImagePair] = []
    private var usedPairs: [WDImagePair] = []

    // MARK: - Zorluk Seviyesi Mantığı (Güncellendi)
    private var pairsPool: [WDImagePair] {
        switch questionNumber {
        case 1...4:
            return easyPairs
        case 5...8:
            return mediumPairs
        case 9...10:
            return hardPairs
        default:
            return easyPairs
        }
    }
    
    override init() {
        super.init()
        setupImagePools()
        initializeGame()
    }
    
    deinit {
        stopGameTimer()
        stopUiTimer()
    }

    private func setupImagePools() {
        let mediumNums = [7, 8, 12, 15, 20, 26, 27]
        let hardNums = [1, 9, 11, 13, 18, 22, 25, 30]
        let specialEasyNames = [("bike", "bike1"), ("family", "family2"), ("mickey1", "mickey2"), ("yemek", "yemek2")]

        for i in 1...30 {
            if i == 23 || i == 28 { continue }
            
            let p1 = WDImagePair(mainImage: "\(i)a", differentImage: "\(i)b")
            let p2 = WDImagePair(mainImage: "\(i)b", differentImage: "\(i)a")
            
            if mediumNums.contains(i) {
                mediumPairs.append(contentsOf: [p1, p2])
            } else if hardNums.contains(i) {
                hardPairs.append(contentsOf: [p1, p2])
            } else {
                easyPairs.append(contentsOf: [p1, p2])
            }
        }

        for namePair in specialEasyNames {
            let p1 = WDImagePair(mainImage: namePair.0, differentImage: namePair.1)
            let p2 = WDImagePair(mainImage: namePair.1, differentImage: namePair.0)
            easyPairs.append(contentsOf: [p1, p2])
        }
        
        easyPairs.shuffle()
        mediumPairs.shuffle()
        hardPairs.shuffle()
    }

    private func applyQuestion() {
        questionTitle = LocalizedStringKey("Which one is different?")
        
        let availablePairs = pairsPool.filter { pair in
            !usedPairs.contains(where: {
                ($0.mainImage == pair.mainImage && $0.differentImage == pair.differentImage) ||
                ($0.mainImage == pair.differentImage && $0.differentImage == pair.mainImage)
            })
        }
        
        let finalPool = availablePairs.isEmpty ? pairsPool : availablePairs
        guard let pair = finalPool.randomElement() else { return }
        
        usedPairs.append(pair)
        
        let differentIndex = Int.random(in: 0..<4)
        var opts: [WhichDifferentOption] = []
        for i in 0..<4 {
            if i == differentIndex {
                opts.append(.init(imageName: pair.differentImage, isDifferent: true))
            } else {
                opts.append(.init(imageName: pair.mainImage, isDifferent: false))
            }
        }
        currentOptions = opts.shuffled()
    }

    func startAgain() {
        stopGameTimer()
        timeCounter = timeLimit
        questionNumber = 1
        answeredQuestion = false
        isAnswerTrue = false
        gameOver = false
        correctCount = 0
        wrongCount = 0
        averageResponseTime = 0.0
        totalResponseTime = 0.0
        totalAnswered = 0
        usedPairs.removeAll()
        updateProgress()
        applyQuestion()
        startGameTimer()
    }
    
    private func initializeGame() {
        updateProgress()
        applyQuestion()
        startGameTimer()
        startUiTimer()
    }
    
    func checkQuestion(selectedIndex: Int) {
        guard !answeredQuestion else { return }
        stopGameTimer()
        answeredQuestion = true
        
        if selectedIndex != -1 && currentOptions.indices.contains(selectedIndex) {
            isAnswerTrue = currentOptions[selectedIndex].isDifferent
            totalResponseTime += (timeLimit - timeCounter)
        } else {
            isAnswerTrue = false
            totalResponseTime += timeLimit
        }
        
        totalAnswered += 1
        averageResponseTime = totalResponseTime / Double(totalAnswered)
        if isAnswerTrue { correctCount += 1 } else { wrongCount += 1 }
    }
    
    func nextQuestion() {
        if questionNumber == lastQuestionNumber { endGame(); return }
        questionNumber += 1
        prepareNewQuestion()
    }
    
    private func prepareNewQuestion() {
        timeCounter = timeLimit
        answeredQuestion = false
        isAnswerTrue = false
        applyQuestion() // Artık yeni questionNumber'a göre pairsPool'dan çekecek
        startGameTimer()
    }
    
    func endGame() {
        stopGameTimer()
        let total = correctCount + wrongCount
        percentageTruth = total > 0 ? (100.0 * Double(correctCount) / Double(total)) : 0.0
        gameOver = true
        
        getDataCall {
            try await FirestorageManager.shared.saveGame(
                gameData: GameStoreModel(
                    successRate: (Double(self.correctCount) / Double(max(1, self.correctCount + self.wrongCount))),
                    gameType: .which_different,
                    date: Timestamp(date: Date()),
                    averageTime: self.averageResponseTime
                )
            )
        } onSuccess: { _ in } onLoading: { } onError: { _ in }
    }
    
    private func startGameTimer() {
        stopGameTimer()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeCounter > 0 { self.timeCounter -= 0.01 }
            else { self.checkQuestion(selectedIndex: -1) }
        }
        RunLoop.main.add(gameTimer, forMode: .common)
    }
    
    private func stopGameTimer() { gameTimer.invalidate() }
    private func startUiTimer() {
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.uiTick += 1 }
        RunLoop.main.add(uiTimer, forMode: .common)
    }
    private func stopUiTimer() { uiTimer.invalidate() }
    private func updateProgress() { questionProgress = Double(questionNumber) / Double(lastQuestionNumber) }
}
