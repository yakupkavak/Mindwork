import Foundation
import Combine
import SwiftUI
import FirebaseCore
import FirebaseFirestore

final class PatternGameViewModel: BaseViewModel {
    enum GameState { case ready, playing }
    
    enum PatternItem: Equatable, Hashable {
        case number(Int)
        case color(Color)
        case shape(String, Int)
        case placeholder
    }

    @Published var displaySequence: [PatternItem] = []
    @Published var options: [PatternItem] = []
    @Published var questionNumber: Int = 1
    @Published var gameState: GameState = .ready
    @Published var gameOver: Bool = false
    @Published var answeredQuestion: Bool = false
    @Published var isTrue: Bool? = nil
    @Published var timeCounter: Double = 0.0
    
    @Published var correctOption: PatternItem?
    @Published var selectedOption: PatternItem?
    
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var percentageTruth: Double = 0.0
    @Published var averageResponseTime: Double = 0.0
    
    private var totalResponseTime: Double = 0.0
    private var totalAnswered: Int = 0 // Kayıt için eklendi
    private var timer: Timer?
    private var lastRuleType: Int = -1
    private var questionStartTime: Date?
    var questionProgress: Double { Double(questionNumber) / 10.0 }

    func startGame() {
        gameState = .playing
        questionNumber = 1
        correctCount = 0
        wrongCount = 0
        totalResponseTime = 0
        totalAnswered = 0
        generateQuestion()
    }

    func generateQuestion() {
        answeredQuestion = false
        isTrue = nil
        selectedOption = nil
        
        var ruleType = Int.random(in: 0...3)
        while ruleType == lastRuleType { ruleType = Int.random(in: 0...3) }
        lastRuleType = ruleType
        
        var tempSequence: [PatternItem] = []
        let steps = 4

        switch ruleType {
        case 0: // Basit Artış
            let inc = Int.random(in: 2...5)
            var val = Int.random(in: 1...10)
            for _ in 0..<steps {
                tempSequence.append(.number(val))
                val += inc
            }
        case 1: // Kenar Sayısı Örüntüsü
            let shapeInfo = [
                (icon: "triangle.fill", edges: 3),
                (icon: "square.fill", edges: 4),
                (icon: "pentagon.fill", edges: 5),
                (icon: "hexagon.fill", edges: 6)
            ].randomElement()!
            for i in 1...steps {
                tempSequence.append(.shape(shapeInfo.icon, i))
            }
        case 2: // Katlanarak Artış
            var val = [2, 3, 5].randomElement()!
            for _ in 0..<steps {
                tempSequence.append(.number(val))
                val *= 2
            }
        default: // Şekil Sayısı
            let selectedIcon = ["star.fill", "heart.fill", "circle.fill"].randomElement()!
            let startCount = Int.random(in: 1...2)
            for i in 0..<steps {
                tempSequence.append(.shape(selectedIcon, startCount + i))
            }
        }

        let missingIndex = Int.random(in: 1..<tempSequence.count)
        correctOption = tempSequence[missingIndex]
        displaySequence = tempSequence
        displaySequence[missingIndex] = .placeholder
        options = generateUniqueOptions(correct: correctOption!, ruleType: ruleType)
        startTimer()
    }

    private func generateUniqueOptions(correct: PatternItem, ruleType: Int) -> [PatternItem] {
        var optsSet = Set<PatternItem>()
        optsSet.insert(correct)
        while optsSet.count < 4 {
            switch correct {
            case .number(let val):
                let fake = val + [-2, -1, 1, 2, 5].randomElement()!
                if fake > 0 && fake != val { optsSet.insert(.number(fake)) }
            case .shape(let icon, let count):
                let fakeCount = max(1, count + [-1, 1, 2].randomElement()!)
                if fakeCount != count { optsSet.insert(.shape(icon, fakeCount)) }
            default:
                optsSet.insert(.number(Int.random(in: 1...20)))
            }
        }
        return Array(optsSet).shuffled()
    }

    func checkAnswer(_ selected: PatternItem) {
        guard !answeredQuestion else { return }
        self.selectedOption = selected
        timer?.invalidate()
        answeredQuestion = true
        totalAnswered += 1
        totalResponseTime += timeCounter

        if selected == correctOption {
            isTrue = true
            correctCount += 1
            if let index = displaySequence.firstIndex(of: .placeholder) {
                displaySequence[index] = correctOption!
            }
        } else {
            isTrue = false
            wrongCount += 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if self.questionNumber < 10 {
                self.questionNumber += 1
                self.generateQuestion()
            } else {
                self.endGame()
            }
        }
    }

    private func startTimer() {
        timeCounter = 0.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.timeCounter += 0.1
        }
    }

    // MARK: - Firebase Entegrasyonu
    func endGame() {
        timer?.invalidate()
        
        // 1. Toplam soru sayısını güvenli bir şekilde alalım (genelde 10)
        let totalQuestions = Double(max(1, totalAnswered))
        let correctOnes = Double(correctCount)
        
        // 2. Başarı Oranı Hesaplama (Yüzdelik: 0-100 arası)
        // Örn: (3 / 10) * 100 = 30.0
        self.percentageTruth = (correctOnes / totalQuestions) * 100.0
        
        // 3. Ortalama Hız Hesaplama
        self.averageResponseTime = totalResponseTime / totalQuestions
        
        self.gameOver = true
        
        // MARK: - Firebase Kayıt
        getDataCall {
            try await FirestorageManager.shared.saveGame(
                gameData: GameStoreModel(
                    // Firebase genelde başarıyı 0.0 ile 1.0 arasında bekler (Örn: 0.75)
                    successRate: (correctOnes / totalQuestions),
                    gameType: .pattern_game,
                    date: Timestamp(date: Date()),
                    averageTime: self.averageResponseTime
                )
            )
        } onSuccess: { _ in
            print("Veri başarıyla kaydedildi. Oran: %\(self.percentageTruth)")
        } onLoading: {
        } onError: { error in
            if let error = error {
                print("Hata oluştu: \(error.localizedDescription)")
            }
        }
    }
    
    func startAgain() {
        gameOver = false
        startGame()
    }
}
