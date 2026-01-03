import SwiftUI

struct FindColorUI: View {
    @StateObject var viewModel = FindColorViewModel()
    @EnvironmentObject var router: RouterFeed
    @State private var showTimeSheet = false
    @State private var offsets: [CGSize] = Array(repeating: .zero, count: 4)

    var body: some View {
        VStack {
            // MARK: Header
            HStack {
                btnSystemIconTransparent(iconSystemName: Icons.left_direction, color: .black) {
                    router.navigateBack()
                }
                Spacer()
                tvBodylineString(
                    text: String(format: NSLocalizedString("question_number", comment: ""), viewModel.questionNumber),
                    color: .black
                )
                Spacer()
                btnSystemIconTransparent(iconSystemName: "ellipsis.circle", color: .black) {
                    showTimeSheet = true
                }
            }

            ProgressView(value: viewModel.questionProgress)
                .padding(.top)
                .tint(.orange300)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            tvBodylineString(text: String(format: "%.2f", viewModel.timeCounter), color: .black)
                .padding(.top)

            // MARK: Soru Kartı
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.orange)
                .overlay {
                    tvBodyline(text: viewModel.questionTitle, color: .white).padding(8)
                }
                .frame(maxWidth: 500, maxHeight: 100)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            // MARK: Seçenekler (Rastgele Konumlu)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    answerButton(index: 0)
                    Spacer()
                    answerButton(index: 1)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    answerButton(index: 2)
                    Spacer()
                    answerButton(index: 3)
                    Spacer()
                }
                Spacer()
            }
            .frame(maxHeight: .infinity)
            .background(Color.gray.opacity(0.04))
            .cornerRadius(16)

            // MARK: Alt Kontrol Alanı
            VStack(spacing: 6) {
                // Küçük geri bildirim metni (Butonun tam üstünde)
                if viewModel.answeredQuestion {
                    Text(viewModel.isAnswerTrue ? StringKey.true_answer : StringKey.wrong_answer)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(viewModel.isAnswerTrue ? .green : .red)
                        .transition(.opacity.combined(with: .scale))
                } else {
                    // Düzeni bozmamak için boş alan tutuyoruz
                    Text(" ").font(.system(size: 14))
                }

                // Sabit "Sonraki" Butonu
                btnTextGradientInfinity(
                    action: {
                        viewModel.nextQuestion()
                    },
                    text: viewModel.questionNumber == viewModel.lastQuestionNumber
                        ? QuestionStringKeys.finish
                        : QuestionStringKeys.next
                )
                .disabled(!viewModel.answeredQuestion)
                .opacity(!viewModel.answeredQuestion ? 0.6 : 1.0)
                .padding(.horizontal, 64)
            }
            .padding(.bottom, 16)
        }
        .padding()
        .navigationBarHidden(true)
        .onAppear { updateOffsets(animated: false) }
        .onChange(of: viewModel.uiTick) { _, _ in updateOffsets(animated: true) }
        .customAnswerAlert(
            isPresented: $viewModel.gameOver,
            titleKey: StatsKey.title,
            trueCount: StatsKey.trueCount(viewModel.correctCount),
            wrongCount: StatsKey.wrongCount(viewModel.wrongCount),
            averageAnswer: StatsKey.averageAnswer(seconds: viewModel.averageResponseTime),
            accuracy: StatsKey.accuracy(percent: viewModel.percentageTruth),
            acceptText: StringKey.start_again,
            deniedText: StringKey.main_page,
            acceptFunc: { viewModel.startAgain() },
            deniedFunc: { router.navigateBack() }
        )
    }

    // Seçenek Buton Builder'ı
    @ViewBuilder
    private func answerButton(index: Int) -> some View {
        if viewModel.currentOptions.indices.contains(index) {
            let option = viewModel.currentOptions[index]
            ColorAnswerButton(
                title: option.optionText,
                color: option.optionColor
            ) {
                viewModel.checkQuestion(selectedAnswer: index)
            }
            .offset(offsets[index])
            .disabled(viewModel.answeredQuestion)
        }
    }

    private func updateOffsets(animated: Bool) {
        let new = (0..<4).map { _ in
            CGSize(width: CGFloat(Int.random(in: -25...25)),
                   height: CGFloat(Int.random(in: -25...25)))
        }
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                offsets = new
            }
        } else {
            offsets = new
        }
    }
}

#Preview {
    FindColorUI().environmentObject(RouterFeed())
}
