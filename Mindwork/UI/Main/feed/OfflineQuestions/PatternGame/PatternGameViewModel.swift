//
//  PatternGameViewModel.swift
//  Mindwork
//
//  Created by Cemre Bayer on 2.01.2026.
//
import SwiftUI
import Combine
import FirebaseFirestore

final class PatternGameViewModel: BaseViewModel {
    // MARK: - Fazlar ve Ayarlar
    private let lastQuestionNumber = 10
    
    // MARK: - Published Değişkenler
    @Published var timeCounter: Double = 0.0
    @Published var questionNumber = 1 { didSet { updateProgress() } }
    @Published var questionProgress = 0.1
    @Published var questionTitle: LocalizedStringKey = StringKey.loading
    @Published var isTrue: Bool? = nil
    @Published var gameOver = false
    @Published var answeredQuestion = false

    // Pattern Verileri
    @Published var sequence: [PatternItem] = []
    @Published var options: [PatternItem] = []
    private var correctAnswer: PatternItem?

    // MARK: - İstatistikler
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var averageResponseTime: Double = 0.0
    @Published var percentageTruth: Double = 0.0
    private var totalResponseTime: Double = 0.0
    private var gameTimer = Timer()

    // MARK: - Tip Tanımı (Any yerine daha güvenli yapı)
    enum PatternItem: Equatable {
        case number(Int)
        case color(Color)
        case shape(String)
    }

    override init() {
        super.init()
        generateNewQuestion()
        startGameTimer()
    }

    // MARK: - Oyun Mantığı
    func generateNewQuestion() {
        isTrue = nil
        answeredQuestion = false
        timeCounter = 0
        
        let type = ["arithmetic", "colors", "shapes"].randomElement()!
        
        switch type {
        case "arithmetic":
            setupArithmetic()
        case "colors":
            setupColors()
        default:
            setupShapes()
        }
    }

    private func setupArithmetic() {
        questionTitle = "Sıradaki sayıyı bul!" // Kendi StringKey'ine bağla
        let start = Int.random(in: 1...20)
        let step = Int.random(in: 2...10)
        let seq = (0..<4).map { start + ($0 * step) }
        
        correctAnswer = .number(seq[3])
        sequence = seq.prefix(3).map { .number($0) }
        
        var opts = [seq[3], seq[3] + step, seq[3] - step, Int.random(in: 40...60)]
        options = opts.shuffled().map { .number($0) }
    }

    private func setupColors() {
        questionTitle = "Deseni tamamlayan rengi bul!"
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange]
        let c1 = colors.randomElement()!
        let c2 = colors.filter { $0 != c1 }.randomElement()!
        
        // Örn: A - B - A - ?
        correctAnswer = .color(c2)
        sequence = [.color(c1), .color(c2), .color(c1)]
        options = [c1, c2, Color.pink, Color.teal].shuffled().map { .color($0) }
    }

    private func setupShapes() {
        questionTitle = "Sıradaki şekil hangisi?"
        let shapes = ["circle.fill", "square.fill", "star.fill", "triangle.fill", "heart.fill"]
        let s1 = shapes.randomElement()!
        let s2 = shapes.filter { $0 != s1 }.randomElement()!
        
        // Örn: S1 - S1 - S2 - S1 - S1 - ?
        correctAnswer = .shape(s2)
        sequence = [.shape(s1), .shape(s1), .shape(s2), .shape(s1), .shape(s1)]
        options = [s1, s2, "bolt.fill", "moon.fill"].shuffled().map { .shape($0) }
    }

    func checkAnswer(_ selected: PatternItem) {
        guard !answeredQuestion else { return }
        answeredQuestion = true
        
        if selected == correctAnswer {
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
            generateNewQuestion()
        }
    }

    private func endGame() {
            gameTimer.invalidate()
            let total = Double(max(1, correctCount + wrongCount))
            percentageTruth = (Double(correctCount) / total) * 100
            gameOver = true
            
            // Hata veren kısmı bu şekilde güncelle:
            getDataCall {
                try await FirestorageManager.shared.saveGame(
                    gameData: GameStoreModel(
                        successRate: Double(self.correctCount) / total,
                        gameType: .pattern_game,
                        date: Timestamp(date: Date()),
                        averageTime: self.averageResponseTime
                    )
                )
            } onSuccess: { _ in
                print("Desen oyunu başarıyla kaydedildi.")
            } onLoading: {
                // İstersen bir loading state tetikleyebilirsin
            } onError: { error in
                print("Oyun kaydedilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
            }
        }

    func startAgain() {
        questionNumber = 1
        correctCount = 0
        wrongCount = 0
        totalResponseTime = 0
        generateNewQuestion()
        startGameTimer()
    }

    // MARK: - Timer & Helpers
    private func startGameTimer() {
        gameTimer.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.timeCounter += 0.01
        }
        RunLoop.main.add(gameTimer, forMode: .common)
    }

    private func accumulateStats() {
        totalResponseTime += timeCounter
        averageResponseTime = totalResponseTime / Double(max(1, correctCount + wrongCount))
    }

    private func updateProgress() {
        questionProgress = Double(questionNumber) / Double(lastQuestionNumber)
    }
}
