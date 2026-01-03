import SwiftUI
import Combine

final class PatternGameViewModel: BaseViewModel {
    enum GameState { case ready, playing }
    enum PatternItem: Equatable, Hashable {
        case number(Int)
        case color(Color)
        case shape(String) // Yıldız, kare, daire vb.
        case placeholder
    }

    @Published var displaySequence: [PatternItem] = []
    var fullSequence: [PatternItem] = []
    @Published var options: [PatternItem] = []
    @Published var questionNumber: Int = 1
    @Published var gameState: GameState = .ready
    @Published var gameOver: Bool = false
    @Published var answeredQuestion: Bool = false
    @Published var isTrue: Bool? = nil
    @Published var timeCounter: Double = 0.0
    
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    var totalResponseTime: Double = 0.0
    var percentageTruth: Double = 0.0
    var averageResponseTime: Double = 0.0
    
    private var timer: Timer?
    private var correctItem: PatternItem?
    private var lastRuleType: Int = -1 // Aynı kuralın üst üste gelmemesi için
    private var questionStartTime: Date?
    var questionProgress: Double { Double(questionNumber) / 10.0 }

    func startGame() {
        gameState = .playing
        questionNumber = 1
        correctCount = 0
        wrongCount = 0
        totalResponseTime = 0
        generateQuestion()
    }

    func generateQuestion() {
        answeredQuestion = false
        isTrue = nil
        
        // MARK: - Gelişmiş Kural Seti
        var ruleType = Int.random(in: 0...5)
        while ruleType == lastRuleType { ruleType = Int.random(in: 0...5) }
        lastRuleType = ruleType
        
        var tempSequence: [PatternItem] = []
        
        switch ruleType {
        case 0: // Matematiksel: 2x + 1 Kuralı
            var current = Int.random(in: 1...4)
            for _ in 0..<5 {
                tempSequence.append(.number(current))
                current = (current * 2) + 1
            }
        case 1: // Fibonacci
            var a = 1, b = 1
            for _ in 0..<6 {
                tempSequence.append(.number(a))
                let next = a + b
                a = b
                b = next
            }
        case 2: // Şekil Dizisi (Daire, Kare, Daire, Kare...)
            let shapes = ["circle.fill", "square.fill"].shuffled()
            for i in 0..<6 {
                tempSequence.append(.shape(i % 2 == 0 ? shapes[0] : shapes[1]))
            }
        case 3: // Azalan Kareler
            let start = Int.random(in: 6...9)
            for i in stride(from: start, to: start-5, by: -1) {
                tempSequence.append(.number(i * i))
            }
        case 4: // Üçgensel Sayılar
            for i in 1...6 {
                tempSequence.append(.number((i * (i + 1)) / 2))
            }
        case 5: // Karışık Renk ve Sayı (Zor Seviye)
            let colors: [Color] = [.red, .blue, .green]
            let selectedColor = colors.randomElement()!
            for i in 1...5 {
                tempSequence.append(.color(selectedColor.opacity(Double(i) * 0.2)))
            }
        default:
            tempSequence = [.number(2), .number(4), .number(6), .number(8)]
        }

        fullSequence = tempSequence
        let missingIndex = Int.random(in: 1..<fullSequence.count)
        correctItem = fullSequence[missingIndex]
        
        displaySequence = fullSequence
        displaySequence[missingIndex] = .placeholder
        
        options = generateOptions(correct: correctItem!)
        startTimer()
    }

    private func generateOptions(correct: PatternItem) -> [PatternItem] {
        var opts: [PatternItem] = [correct]
        
        switch correct {
        case .number(let val):
            while opts.count < 4 {
                let off = Int.random(in: -10...10)
                if off != 0 && val + off > 0 {
                    let opt = PatternItem.number(val + off)
                    if !opts.contains(opt) { opts.append(opt) }
                }
            }
        case .shape:
            let allShapes = ["circle.fill", "square.fill", "triangle.fill", "star.fill", "hexagon.fill"]
            for s in allShapes.shuffled() {
                if opts.count < 4 {
                    let opt = PatternItem.shape(s)
                    if !opts.contains(opt) { opts.append(opt) }
                }
            }
        case .color(let color):
            while opts.count < 4 {
                let opt = PatternItem.color(Color.random)
                if !opts.contains(opt) { opts.append(opt) }
            }
        default: break
        }
        return opts.shuffled()
    }

    func checkAnswer(_ selected: PatternItem) {
        guard !answeredQuestion else { return }
        timer?.invalidate()
        answeredQuestion = true
        
        if selected == correctItem {
            isTrue = true
            correctCount += 1
            if let index = displaySequence.firstIndex(of: .placeholder) {
                displaySequence[index] = correctItem!
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
        questionStartTime = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.timeCounter += 0.1
        }
    }

    private func endGame() {
        percentageTruth = (Double(correctCount) / 10.0) * 100
        averageResponseTime = totalResponseTime / 10.0
        gameOver = true
    }
    
    func startAgain() {
        gameOver = false
        startGame()
    }
}

// Yardımcı Renk Üretici
extension Color {
    static var random: Color {
        return Color(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1))
    }
}
