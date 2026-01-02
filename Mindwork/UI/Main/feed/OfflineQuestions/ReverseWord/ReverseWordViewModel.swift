import Combine
import Foundation
import SwiftUI
import FirebaseFirestore

final class ReverseWordViewModel: BaseViewModel { 

    enum Phase {
        case ready
        case showingWord
        case typing
        case feedback
        case gameOver
    }

    // MARK: - Published (UI State)
    @Published var phase: Phase = .ready
    @Published var currentWord: String = ""
    @Published var isWordHidden: Bool = false
    @Published var userInput: String = ""
    @Published var levelLength: Int = 3
    @Published var score: Int = 0
    @Published var feedbackText: String = ""
    @Published var feedbackColor: Color = .green
    @Published var lastRoundPoints: Int? = nil

    @Published private(set) var totalElapsed: TimeInterval = 0
    @Published private(set) var timeProgress: CGFloat = 0.0
    @Published var isStatsPopupPresented: Bool = false

    @Published private(set) var correctCount: Int = 0
    @Published private(set) var wrongCount: Int = 0

    // MARK: - Config
    private let minLength = 3
    private let maxLength = 10
    private let wordDisplaySeconds: TimeInterval = 1.8
    private let speedThreshold: TimeInterval = 15.0
    private let lastQuestionNumber = 10 // ✅ Soru sınırı eklendi

    private let recentMemoryPerLength = 6
    private var recentWordsByLength: [Int: [String]] = [:]

    private var showTimer: Timer?
    private var totalTimer: Timer?
    private var typingStartDate: Date?
    private var correctStreak: Int = 0
    private var wrongStreak: Int = 0
    private var totalAnswerSeconds: TimeInterval = 0
    private var answeredCount: Int = 0
    private var runningStartDate: Date?

    // MARK: - Computed for UI
    var totalTimeText: String { String(format: "%.2f", totalElapsed) }

    var averageAnswerSeconds: Double {
        guard answeredCount > 0 else { return 0.0 }
        return totalAnswerSeconds / Double(answeredCount)
    }

    var accuracyPercent: Double {
        let total = correctCount + wrongCount
        guard total > 0 else { return 0.0 }
        return (Double(correctCount) / Double(total)) * 100.0
    }

    // MARK: - Public API

    func startRound() {
        guard phase != .gameOver else { return }
        resetRoundUI()

        currentWord = pickNonRepeatingWord(length: levelLength)
        isWordHidden = false
        phase = .showingWord

        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: wordDisplaySeconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.isWordHidden = true
            self.phase = .typing
            self.typingStartDate = Date()
            self.startTotalTimer()
        }
    }

    func submit() {
        guard phase == .typing else { return }
        stopTotalTimer()

        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctAnswer = ReverseWordModel.reversed(currentWord).lowercased()
        let isCorrect = (trimmed == correctAnswer)

        let elapsedThisAnswer = Date().timeIntervalSince(typingStartDate ?? Date())
        totalAnswerSeconds += elapsedThisAnswer
        answeredCount += 1

        let gained = computePoints(isCorrect: isCorrect, wordLength: levelLength, elapsed: elapsedThisAnswer)
        lastRoundPoints = gained

        if isCorrect {
            correctCount += 1
            score += gained
            feedbackText = "Correct!"
            feedbackColor = Color(red: 0.10, green: 0.60, blue: 0.25)
            correctStreak += 1
            wrongStreak = 0
        } else {
            wrongCount += 1
            feedbackText = "Incorrect"
            feedbackColor = Color(red: 0.78, green: 0.18, blue: 0.18)
            wrongStreak += 1
            correctStreak = 0
        }

        // ✅ Oyun Bitiş Kontrolü (2 Yanlış veya 10 Soru)
        if wrongStreak >= 2 || (correctCount + wrongCount) >= lastQuestionNumber {
            endGame()
        } else {
            updateDifficulty()
            phase = .feedback
        }
    }

    // MARK: - Firebase Save logic
    private func endGame() {
        phase = .gameOver
        isStatsPopupPresented = true
        
        let total = Double(max(1, correctCount + wrongCount))
        
        // ✅ Firebase Kayıt İşlemi
        getDataCall {
            try await FirestorageManager.shared.saveGame(
                gameData: GameStoreModel(
                    successRate: Double(self.correctCount) / total,
                    gameType: .reverse_word, // Enum'da bu tipin olduğundan emin olun
                    date: Timestamp(date: Date()),
                    averageTime: self.averageAnswerSeconds
                )
            )
        } onSuccess: { _ in
            print("ReverseWord oyunu başarıyla kaydedildi.")
        } onLoading: {
            // Yükleme durumu gerekirse burada yönetilebilir
        } onError: { error in
            print("Oyun kaydedilemedi: \(error?.localizedDescription ?? "Bilinmeyen hata")")
        }
    }

    func nextRound() {
        resetRoundUI()
        phase = .ready
    }

    func restartGame() {
        hardResetAll()
        isStatsPopupPresented = false
        phase = .ready
    }

    func goToMain() {
        hardResetAll()
        isStatsPopupPresented = false
        phase = .ready
    }

    // MARK: - Helpers (Timer & UI Reset)
    private func resetRoundUI() {
        showTimer?.invalidate()
        showTimer = nil
        userInput = ""
        feedbackText = ""
        isWordHidden = false
        typingStartDate = nil
        lastRoundPoints = nil
    }

    private func hardResetAll() {
        resetRoundUI()
        stopTotalTimer()
        totalElapsed = 0
        timeProgress = 0
        score = 0
        levelLength = minLength
        correctStreak = 0
        wrongStreak = 0
        correctCount = 0
        wrongCount = 0
        totalAnswerSeconds = 0
        answeredCount = 0
        recentWordsByLength = [:]
        currentWord = ""
    }

    private func updateDifficulty() {
        if correctStreak >= 2 {
            levelLength = min(levelLength + 1, maxLength)
            correctStreak = 0
        }
    }

    private func startTotalTimer() {
        guard totalTimer == nil else { return }
        runningStartDate = Date()

        totalTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.runningStartDate else { return }
            let delta = Date().timeIntervalSince(start)
            self.runningStartDate = Date()
            self.totalElapsed += delta

            let maxVisual: TimeInterval = 60.0
            self.timeProgress = CGFloat(min(self.totalElapsed / maxVisual, 1.0))
        }
    }

    private func stopTotalTimer() {
        totalTimer?.invalidate()
        totalTimer = nil
        runningStartDate = nil
    }

    private func pickNonRepeatingWord(length: Int) -> String {
        let list = ReverseWordModel.wordBankByLength[length] ?? (ReverseWordModel.wordBankByLength[minLength] ?? ["cat"])
        let recent = Set(recentWordsByLength[length] ?? [])
        let candidates = list.filter { !recent.contains($0) }
        let chosen = (candidates.randomElement() ?? list.randomElement() ?? "cat")

        var arr = recentWordsByLength[length] ?? []
        arr.append(chosen)
        if arr.count > recentMemoryPerLength {
            arr.removeFirst(arr.count - recentMemoryPerLength)
        }
        recentWordsByLength[length] = arr
        return chosen
    }

    private func computePoints(isCorrect: Bool, wordLength: Int, elapsed: TimeInterval) -> Int {
        guard isCorrect else { return 0 }
        let base = wordLength * 10
        if elapsed > speedThreshold { return base }
        let remaining = max(0.0, speedThreshold - elapsed)
        let speedBonus = Int(remaining * 2.0)
        return base + speedBonus
    }

    deinit {
        showTimer?.invalidate()
        totalTimer?.invalidate()
    }
}
