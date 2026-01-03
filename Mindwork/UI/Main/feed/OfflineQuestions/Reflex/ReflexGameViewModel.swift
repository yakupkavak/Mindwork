import SwiftUI
import Combine
import FirebaseFirestore

final class ReflexGameViewModel: BaseViewModel {
    @Published var score = 0
    @Published var highScore = 0
    @Published var currentColor: GameColor = .green
    @Published var targetColor: GameColor = .red
    @Published var gameState: GameState = .ready
    @Published var message = ""
    @Published var gameOver = false
    @Published var countdownText: String = "" // Geri sayım rakamı için
    
    @Published var correctCount = 0
    @Published var wrongCount = 0
    @Published var averageResponseTime: Double = 0.0
    private var totalResponseTime: Double = 0.0
    private var lastColorChangeTime: Date = Date()

    private var timer: Timer?
    private var isProcessingTap = false
    
    private let initialDelay: Double = 1.2
    private let minDelay: Double = 0.45
    private let speedIncrement: Double = 0.02
    
    enum GameState { case ready, countdown, running, gameOver }
    
    enum GameColor: CaseIterable, Equatable {
        case green, yellow, red
        var color: Color {
            switch self { case .green: return .green; case .yellow: return .yellow; case .red: return .red }
        }
        var name: String {
            switch self { case .green: return "Yeşil"; case .yellow: return "Sarı"; case .red: return "Kırmızı" }
        }
    }

    // MARK: - Game Control
    func startGame() {
        score = 0
        correctCount = 0
        wrongCount = 0
        totalResponseTime = 0
        gameOver = false
        isProcessingTap = false
        
        setNewTargetColor()
        
        var startColor: GameColor
            repeat {
                startColor = GameColor.allCases.randomElement()!
            } while startColor == targetColor
            currentColor = startColor
            
            startInitialCountdown()
    }

    private func startInitialCountdown() {
        gameState = .countdown
        var timeLeft = 3
        countdownText = "\(timeLeft)"
        
        // 3 saniyelik başlangıç geri sayımı
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            timeLeft -= 1
            
            if timeLeft > 0 {
                self.countdownText = "\(timeLeft)"
            } else {
                timer.invalidate()
                self.runGameLogic()
            }
        }
    }

    private func runGameLogic() {
        gameState = .running
        setNewTargetColor()
        nextColor()
    }

    private func setNewTargetColor() {
        targetColor = GameColor.allCases.randomElement()!
        message = "Hedef: \(targetColor.name)"
    }

    // MARK: - Tap Handling
    func handleTap() {
        guard gameState == .running, !isProcessingTap else { return }
        
        isProcessingTap = true
        timer?.invalidate()
        
        if currentColor == targetColor {
            let reactionTime = Date().timeIntervalSince(lastColorChangeTime)
            totalResponseTime += reactionTime
            correctCount += 1
            
            // Hız bonusu hesaplama
            let speedBonus = max(1, Int((initialDelay - reactionTime) * 15))
            score += speedBonus
            
            isProcessingTap = false
            nextColor()
        } else {
            wrongCount = 1 // İstatistik için
            stopGame(reason: "Yanlış renge bastın!")
        }
    }

    // MARK: - Color Logic
    private func nextColor() {
        timer?.invalidate()
        if gameState != .running { return }
        
        var next: GameColor
        repeat {
            next = GameColor.allCases.randomElement()!
        } while next == currentColor
        
        currentColor = next
        lastColorChangeTime = Date()
        isProcessingTap = false
        
        // Seviye ilerledikçe hızı artır
        let dynamicDelay = initialDelay - (Double(correctCount) * speedIncrement)
        let currentDelay = max(minDelay, dynamicDelay)
        
        timer = Timer.scheduledTimer(withTimeInterval: currentDelay, repeats: false) { [weak self] _ in
            guard let self = self, self.gameState == .running else { return }
            
            if !self.isProcessingTap {
                if self.currentColor == self.targetColor {
                    self.wrongCount = 1
                    self.stopGame(reason: "Hedefi kaçırdın!")
                } else {
                    self.nextColor()
                }
            }
        }
    }

    // MARK: - Game End
    func stopGame(reason: String) {
        gameState = .gameOver
        timer?.invalidate()
        
        if score > highScore { highScore = score }
        averageResponseTime = correctCount > 0 ? totalResponseTime / Double(correctCount) : 0
        message = reason
        
        // Firebase Veri Kaydı
        saveToFirebase()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.gameOver = true
        }
    }
    
    private func saveToFirebase() {
        getDataCall {
            let total = Double(self.correctCount + self.wrongCount)
            let successRate = total > 0 ? Double(self.correctCount) / total : 0.0
            
            try await FirestorageManager.shared.saveGame(
                gameData: GameStoreModel(
                    successRate: successRate,
                    gameType: .reflex,
                    date: Timestamp(date: Date()),
                    averageTime: self.averageResponseTime
                )
            )
        } onSuccess: { _ in
            print("Reflex game saved")
        } onLoading: {
        } onError: { error in
            print("Reflex save error: \(error?.localizedDescription ?? "")")
        }
    }
}
