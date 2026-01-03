import SwiftUI
import Combine
import QuartzCore
import FirebaseFirestore

final class TimingGameViewModel: BaseViewModel {
    @Published var barPosition: CGFloat = 0.05
    @Published var targetPosition: CGFloat = 0.5
    @Published var isMovingForward = true
    @Published var gameResult: TimingResult? = nil
    @Published var score = 0
    @Published var level = 1
    @Published var gameOver = false
    @Published var isGameStarted = false
    @Published var answeredQuestion = false
    
    @Published var timeLeft: Double = 5.0
    private let initialTime: Double = 5.0
    
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var percentageTruth: Double = 0.0
    @Published var averageResponseTime: Double = 0.0
    
    // Oyun hızı: Seviye arttıkça hızlanır
    private var speed: CGFloat = 0.012
    private var displayLink: CADisplayLink?
    private var timer: Timer?
    private var startTime: Date?
    private var totalResponseTime: Double = 0.0
    private let baseTime: Double = 5.0

    // MARK: - Game Logic
    func startGame() {
        self.isGameStarted = true
        self.resetGameValues()
        self.setupRound()
    }

    func setupRound() {
        self.gameResult = nil
        self.answeredQuestion = false
        
        self.barPosition = 0.0
        self.isMovingForward = true // Hareket yönünü sıfırla
        
        let calculatedTime = baseTime - (Double(self.level - 1) * 0.2)
                self.timeLeft = max(calculatedTime, 1.5)
        
        self.targetPosition = CGFloat.random(in: 0.05...0.95)
        
        self.startMoving()
        self.startCountdown()
    }

    func startMoving() {
        self.displayLink?.invalidate()
        self.displayLink = CADisplayLink(target: self, selector: #selector(updatePosition))
        self.displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func updatePosition() {
        // Başlangıç hızı çok yüksekse top bir uçta takılı kalabilir.
        // Hızı kontrol edilebilir bir seviyeye çekelim.
        let baseSpeed: CGFloat = 0.015
        let levelBonus: CGFloat = CGFloat(self.level) * 0.001
        let currentSpeed = baseSpeed + levelBonus
        
        if self.isMovingForward {
            self.barPosition += currentSpeed
            // Sağ sınıra ulaştığında (1.0) yönü değiştir
            if self.barPosition >= 1.0 {
                self.barPosition = 1.0 // Taşmayı engelle
                self.isMovingForward = false
            }
        } else {
            self.barPosition -= currentSpeed
            // Sol sınıra ulaştığında (0.0) yönü değiştir
            if self.barPosition <= 0.0 {
                self.barPosition = 0.0 // Taşmayı engelle
                self.isMovingForward = true
            }
        }
    }

    func startCountdown() {
        self.timer?.invalidate()
        self.startTime = Date()
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeLeft > 0 {
                self.timeLeft -= 0.01
            } else {
                self.stopAndCheck(isTimeout: true)
            }
        }
    }

    func stopAndCheck(isTimeout: Bool = false) {
        self.displayLink?.invalidate()
        self.timer?.invalidate()
        self.answeredQuestion = true
        
        let distance = abs(self.barPosition - self.targetPosition)
    
        
        if !isTimeout && distance <= 0.12 { // 0.15'ten 0.12'ye çektik, dengeledik
            if distance <= 0.04 {
                self.gameResult = .perfect
                self.score += 100
            } else {
                self.gameResult = .good
                self.score += 50
            }
            
            self.correctCount += 1
            self.level += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.setupRound()
            }
        } else {
            self.gameResult = .miss
            self.wrongCount += 1
            self.calculateStats()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.endGame()
            }
        }
    }

    func calculateStats() {
        let total = Double(self.correctCount + self.wrongCount)
        if total > 0 {
            self.percentageTruth = (Double(self.correctCount) / total) * 100
            self.averageResponseTime = self.totalResponseTime / total
        }
    }

    func resetGameValues() {
        self.score = 0
        self.level = 1
        self.correctCount = 0
        self.wrongCount = 0
        self.totalResponseTime = 0
        self.gameOver = false
    }

    private func endGame() {
        self.gameOver = true
        self.isGameStarted = false
        
        self.getDataCall {
            try await FirestorageManager.shared.saveGame(
                gameData: GameStoreModel(
                    successRate: self.percentageTruth / 100,
                    gameType: .timing,
                    date: Timestamp(date: Date()),
                    averageTime: self.averageResponseTime
                )
            )
        } onSuccess: { _ in } onLoading: { } onError: { error in
            print("Firebase Error: \(error?.localizedDescription ?? "Error")")
        }
    }
}
