import Foundation
import Combine
import SwiftUI
import FirebaseCore

final class FindColorViewModel: BaseViewModel {
    @Published var timeCounter: Double = 0.0
    @Published var uiTick: Int = 0
    let lastQuestionNumber = 10

    @Published var questionNumber = 1 { didSet { updateProgress() } }
    @Published var questionProgress = 0.1
    @Published var questionTitle: LocalizedStringKey = StringKey.empty
    @Published var questionList: [FindColorModel] = []
    
    // Seçenekler tek bir listede tutulursa rastgele dağıtmak daha kolay olur
    @Published var currentOptions: [FindColorAnswerModel] = []
    
    @Published var answeredQuestion = false
    @Published var isAnswerTrue = false
    @Published var gameOver = false
    
    private var gameTimer = Timer()
    private var uiTimer = Timer()
    
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var averageResponseTime: Double = 0.0
    @Published var percentageTruth: Double = 0.0
    private var totalResponseTime: Double = 0.0
    private var totalAnswered: Int = 0
    
    override init() {
        super.init()
        initalizeList()
        startGameTimer()
        startUiTimer()
    }

    func startAgain() {
        stopGameTimer()
        timeCounter = 0.0
        questionNumber = 1
        answeredQuestion = false
        isAnswerTrue = false
        gameOver = false
        correctCount = 0
        wrongCount = 0
        averageResponseTime = 0.0
        totalResponseTime = 0.0
        totalAnswered = 0
        updateProgress()
        
        let pool = findColorQuestionList
        questionList = Array(pool.shuffled().prefix(lastQuestionNumber))
        applyQuestion(at: 0)
        startGameTimer()
    }

    private func startGameTimer() {
        stopGameTimer()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            self?.timeCounter += 0.01
        }
        RunLoop.main.add(gameTimer, forMode: .common)
    }

    private func stopGameTimer() { gameTimer.invalidate() }

    private func startUiTimer() {
        stopUiTimer()
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.uiTick += 1
        }
        RunLoop.main.add(uiTimer, forMode: .common)
    }

    private func stopUiTimer() { uiTimer.invalidate() }

    private func initalizeList() {
        let pool = findColorQuestionList.shuffled()
        questionList = Array(pool.prefix(lastQuestionNumber))
        applyQuestion(at: 0)
    }

    private func applyQuestion(at index: Int) {
        guard questionList.indices.contains(index) else { return }
        var q = questionList[index]
        
        // MARK: Rastgele Dağılım
        // Seçenekleri karıştırarak her seferinde farklı butona gelmesini sağlıyoruz
        q.options.shuffle()
        currentOptions = q.options
        questionTitle = q.questionTitle
        
        // UI'daki ofsetleri tetiklemek için tick'i artır
        uiTick += 1
    }

    func checkQuestion(selectedAnswer: Int) {
        guard !answeredQuestion, currentOptions.indices.contains(selectedAnswer) else { return }

        stopGameTimer()
        let answer = currentOptions[selectedAnswer]
        answeredQuestion = true
        isAnswerTrue = answer.isTrue

        totalResponseTime += timeCounter
        totalAnswered += 1
        averageResponseTime = totalResponseTime / Double(totalAnswered)

        if answer.isTrue {
            correctCount += 1
        } else {
            wrongCount += 1
        }
    }

    func nextQuestion() {
        if questionNumber == lastQuestionNumber { endGame(); return }
        questionNumber += 1
        timeCounter = 0
        answeredQuestion = false
        applyQuestion(at: questionNumber - 1)
        startGameTimer()
    }

    func endGame() {
        stopGameTimer()
        let total = correctCount + wrongCount
        percentageTruth = total > 0 ? (100 * Double(correctCount) / Double(total)) : 0
        gameOver = true
        
        // Firebase
    }

    private func updateProgress() {
        questionProgress = Double(questionNumber) / Double(lastQuestionNumber)
    }
}
