import SwiftUI

struct WhichDifferentUI: View {
    @StateObject var viewModel = WhichDifferentViewModel()
    @EnvironmentObject var router: RouterFeed
    @State private var showTimeSheet = false
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack {
            // Top bar
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
            
            // Progress
            ProgressView(value: viewModel.questionProgress)
                .padding(.top)
                .tint(.orange300)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Süre
            tvBodylineString(
                text: String(format: "%.1f", viewModel.timeCounter),
                color: viewModel.timeCounter < 3 ? .red : .black)
                .padding(.top, 6)
            
            // Cevap Mesajı (Correct/Wrong)
            Group {
                if viewModel.answeredQuestion {
                    Text(viewModel.isAnswerTrue ? "Correct!" : "Wrong Answer")
                        .font(.headline)
                        .foregroundColor(viewModel.isAnswerTrue ? .green : .red)
                } else {
                    Text(" ").font(.headline)
                }
            }
            .padding(.top, 2)
            
            // Soru Başlığı
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.orange)
                .overlay {
                    tvBodyline(text: viewModel.questionTitle, color: .white).padding(8)
                }
                .frame(maxWidth: 500, maxHeight: 100)
                .padding(.horizontal, 24)
                .padding(.top, 10)
            
            // Izgara
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(viewModel.currentOptions.enumerated()), id: \.offset) { idx, opt in
                    Button {
                        viewModel.checkQuestion(selectedIndex: idx)
                    } label: {
                        VStack {
                            Image(opt.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, minHeight: 110)
                                .padding(10)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: .gray.opacity(0.2), radius: 5, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(viewModel.answeredQuestion && opt.isDifferent ? Color.green : Color.gray.opacity(0.12),
                                        lineWidth: viewModel.answeredQuestion && opt.isDifferent ? 4 : 1)
                        )
                    }
                    .disabled(viewModel.answeredQuestion)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal)
            
            Spacer()
            
            // Alt Buton
            btnTextGradientInfinity(
                action: { viewModel.nextQuestion() },
                text: viewModel.questionNumber == viewModel.lastQuestionNumber
                    ? QuestionStringKeys.finish
                    : QuestionStringKeys.next
            )
            .disabled(!viewModel.answeredQuestion)
            .opacity(!viewModel.answeredQuestion ? 0.6 : 1.0)
            .padding(.horizontal, 64)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .padding()
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
}
#Preview {
    WhichDifferentUI().environmentObject(RouterFeed())
}
