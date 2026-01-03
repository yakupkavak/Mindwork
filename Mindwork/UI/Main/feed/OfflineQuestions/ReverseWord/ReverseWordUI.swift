///
//  ReverseWordUI.swift
//  Mindwork
//
//  Created by Sena Yıldız on 21.12.2025.

import SwiftUI

struct ReverseWordUI: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ReverseWordViewModel()

    var body: some View {
        ZStack {
            VStack(spacing: 14) {

                // Header (smaller like WordCube)
                VStack(spacing: 4) {
                    Text("Reverse Word")
                        .font(.system(size: 34, weight: .bold))

                    Text("Level: \(vm.levelLength) letters")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray)

                    Text("Score: \(vm.score)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.orange)
                }
                .padding(.top, 6)

                // Time label (total time)
                Text(vm.totalTimeText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.gray.opacity(0.75))
                    .padding(.top, 2)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color.orange.opacity(0.95))
                            .frame(width: max(10, geo.size.width * vm.timeProgress), height: 6)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 22)

                // Main Card (reduced height + typography)
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.95),
                                    Color.orange.opacity(0.65)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 260)
                        .padding(.horizontal, 20)

                    VStack(spacing: 14) {

                        if vm.phase == .ready {
                            Text("Get Ready")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)

                            Text("You will see a word briefly. Then\ntype it backwards. ")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.95))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 18)
                            
                            Text("If you make two mistakes in a row, the game is over.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 18)
                        }

                        if vm.phase == .showingWord {
                            Text("Memorize This Word")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)

                            Text(vm.currentWord)
                                .font(.system(size: 44, weight: .heavy))
                                .foregroundStyle(.white)
                                .padding(.top, 4)
                        }

                        if vm.phase == .typing || vm.phase == .feedback {
                            Text("Now Type It Backwards")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)

                            TextField("Type the reversed word...", text: $vm.userInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.95))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .padding(.horizontal, 22)
                                .disabled(vm.phase == .feedback)

                            if vm.phase == .feedback {
                                Text(vm.feedbackText)
                                    .font(.system(size: 22, weight: .heavy))
                                    .foregroundStyle(vm.feedbackColor)
                                    .shadow(color: Color.black.opacity(0.20), radius: 1, x: 0, y: 1)

                                if let p = vm.lastRoundPoints {
                                    Text(p > 0 ? "+\(p)" : "+0")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.98))
                                        .padding(.top, -4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 26)
                }

                Spacer(minLength: 8)

                Text(bottomHint)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.gray.opacity(0.7))
                    .padding(.bottom, 4)

                Button(action: bottomButtonAction) {
                    Text(bottomButtonTitle)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange.opacity(0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
                .disabled(isBottomButtonDisabled)

            }
            .padding(.top, 6)

            // Game Over Popup
            if vm.isStatsPopupPresented {
                StatsPopupView(
                    correct: vm.correctCount,
                    wrong: vm.wrongCount,
                    averageSeconds: vm.averageAnswerSeconds,
                    accuracy: vm.accuracyPercent,
                    onMain: {
                        vm.goToMain()
                        dismiss()
                    },
                    onRestart: {
                        vm.restartGame()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.18), value: vm.isStatsPopupPresented)
    }

    private var bottomButtonTitle: String {
        switch vm.phase {
        case .ready: return "Start Round"
        case .showingWord: return "..."
        case .typing: return "Submit"
        case .feedback: return "Next"
        case .gameOver: return "..."
        }
    }

    private var bottomHint: String {
        switch vm.phase {
        case .ready:
            return "Tap the button below to start the round."
        case .showingWord:
            return "Look carefully..."
        case .typing:
            return "Type it backwards, then submit."
        case .feedback:
            return "Tap the button below to continue."
        case .gameOver:
            return ""
        }
    }

    private var isBottomButtonDisabled: Bool {
        if vm.phase == .showingWord { return true }
        if vm.phase == .gameOver { return true }
        if vm.phase == .typing {
            return vm.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return false
    }

    private func bottomButtonAction() {
        switch vm.phase {
        case .ready:
            vm.startRound()
        case .showingWord:
            break
        case .typing:
            vm.submit()
        case .feedback:
            vm.nextRound()
        case .gameOver:
            break
        }
    }
}

// MARK: - Popup View (UI)
private struct StatsPopupView: View {

    let correct: Int
    let wrong: Int
    let averageSeconds: Double
    let accuracy: Double

    let onMain: () -> Void
    let onRestart: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 14) {

                Text("İstatistikler")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.black)

                VStack(spacing: 10) {
                    Text("Doğru: \(correct)")
                        .font(.system(size: 18, weight: .medium))

                    Text("Yanlış: \(wrong)")
                        .font(.system(size: 18, weight: .medium))

                    Text("Ortalama cevap: \(formatSeconds(averageSeconds)) sn")
                        .font(.system(size: 16, weight: .medium))

                    Text("Doğruluk: \(formatPercent(accuracy))")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundStyle(.black)

                VStack(spacing: 10) {
                    Button(action: onMain) {
                        Text("Ana ekran")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: onRestart) {
                        Text("Yeniden oyna")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.95))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(maxWidth: 300)
            .background(Color(white: 0.90).opacity(0.97))
            .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    private func formatSeconds(_ s: Double) -> String {
        let formatted = String(format: "%.2f", s)
        return formatted.replacingOccurrences(of: ".", with: ",")
    }

    private func formatPercent(_ p: Double) -> String {
        let formatted = String(format: "%.2f%%", p)
        return formatted.replacingOccurrences(of: ".", with: ",")
    }
}


#Preview {
    ReverseWordUI()
}
