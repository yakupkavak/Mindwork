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
    
    enum GameState { case ready, running, gameOver }
    
    enum GameColor: CaseIterable, Equatable {
        case green, yellow, red
        var color: Color {
            switch self { case .green: return .green; case .yellow: return .yellow; case .red: return .red }
        }
        var name: String {
            switch self { case .green: return "Yeşil"; case .yellow: return "Sarı"; case .red: return "Kırmızı" }
        }
    }

    func startGame() {
        score = 0
        correctCount = 0
        wrongCount = 0
        totalResponseTime = 0
        gameOver = false
        isProcessingTap = false
        gameState = .running
        setNewTargetColor()
        nextColor()
    }

    private func setNewTargetColor() {
        targetColor = GameColor.allCases.randomElement()!
        message = "Hedef: \(targetColor.name)"
    }

    func handleTap() {
        guard gameState == .running, !isProcessingTap else { return }
        
        isProcessingTap = true
        timer?.invalidate()
        
        if currentColor == targetColor {
            let reactionTime = Date().timeIntervalSince(lastColorChangeTime)
            totalResponseTime += reactionTime
            correctCount += 1
            
            let speedBonus = max(1, Int((initialDelay - reactionTime) * 15))
            score += speedBonus
            
            isProcessingTap = false
            nextColor()
        } else {
            wrongCount = 1 // Firebase istatistiği için
            stopGame(reason: "Yanlış renge bastın!")
        }
    }

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
        
        let dynamicDelay = initialDelay - (Double(correctCount) * speedIncrement)
        let currentDelay = max(minDelay, dynamicDelay)
        
        timer = Timer.scheduledTimer(withTimeInterval: currentDelay, repeats: false) { [weak self] _ in
            guard let self = self, self.gameState == .running else { return }
            
            if !self.isProcessingTap {
                if self.currentColor == self.targetColor {
                    self.wrongCount = 1 // Firebase istatistiği için
                    self.stopGame(reason: "Hedefi kaçırdın!")
                } else {
                    self.nextColor()
                }
            }
        }
    }

    func stopGame(reason: String) {
        gameState = .gameOver
        timer?.invalidate()
        
        if score > highScore { highScore = score }
        averageResponseTime = correctCount > 0 ? totalResponseTime / Double(correctCount) : 0
        message = reason
        
        // Firebase
        getDataCall {
            // Başarı oranı (Doğru / Toplam Deneme)
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
            print("Reflex game saved successfully")
        } onLoading: {
            print("Reflex game saving...")
        } onError: { error in
            print("Reflex game save error: \(error?.localizedDescription ?? "")")
        }
        // Firebase

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.gameOver = true
        }
    }
}
