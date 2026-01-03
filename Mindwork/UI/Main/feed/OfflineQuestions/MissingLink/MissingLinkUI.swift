import SwiftUI

struct MissingLinkUI: View {
    @StateObject var viewModel = MissingLinkViewModel()
    @EnvironmentObject var router: RouterFeed
    
    let columns = [GridItem(.adaptive(minimum: 70))]

    var body: some View {
        VStack {
            // Header
            HStack {
                btnSystemIconTransparent(iconSystemName: Icons.left_direction, color: .black) {
                    router.navigateBack()
                }
                Spacer()
                Text("SORU \(viewModel.questionNumber) / 10").font(.headline)
                Spacer()
                Image(systemName: "brain").opacity(0)
            }

            ProgressView(value: viewModel.questionProgress)
                .padding(.top)
                .tint(.orange)

            // Timer ve Feedback
            VStack(spacing: 8) {
                Text(String(format: "%.2f", viewModel.timeCounter))
                    .font(.system(.body, design: .monospaced))
                
                if let isTrue = viewModel.isTrue {
                    Text(isTrue ? "HARİKA!" : "ÜZGÜNÜM!")
                        .font(.headline).bold()
                        .foregroundColor(isTrue ? .green : .red)
                } else {
                    Text(viewModel.questionTitle).font(.subheadline).foregroundColor(.gray)
                }
            }
            .padding(.top)

            // Oyun Alanı
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.05))
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.displayItems, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 45))
                            .frame(width: 75, height: 75)
                            .background(Color.white)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.05), radius: 2)
                    }
                }
                .padding()
            }
            .padding(.top, 20)

            // Seçenekler
            VStack(spacing: 15) {
                if !viewModel.preparingGame {
                    Text("Hangi nesne eksik?").font(.caption).bold().foregroundColor(.orange)
                    HStack(spacing: 15) {
                        ForEach(viewModel.options, id: \.self) { option in
                            Button(action: { viewModel.checkAnswer(selected: option) }) {
                                Text(option)
                                    .font(.system(size: 40))
                                    .frame(width: 70, height: 70)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(getBorderColor(for: option), lineWidth: 4)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 2)
                            }
                            .disabled(viewModel.answeredQuestion)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
            .opacity(viewModel.preparingGame ? 0 : 1)
        }
        .padding()
        .navigationBarHidden(true)
        .customAnswerAlert(
            isPresented: $viewModel.gameOver,
            titleKey: LocalizedStringKey("Statistics"), // Dönüşüm eklendi
            trueCount: LocalizedStringKey("Correct: \(viewModel.correctCount)"),
            wrongCount: LocalizedStringKey("Wrong: \(viewModel.wrongCount)"),
            averageAnswer: LocalizedStringKey(String(format: "Average response: %.2f sn", viewModel.averageResponseTime)),
            accuracy: LocalizedStringKey(String(format: "Accuracy: %.2f%%", viewModel.percentageTruth)),
            acceptText: LocalizedStringKey("Start again"),
            deniedText: LocalizedStringKey("Main Screen"),
            acceptFunc: { viewModel.startAgain() },
            deniedFunc: { router.navigateBack() }
        )
    }

    // Doğru/Yanlış Renk Mantığı
    private func getBorderColor(for option: String) -> Color {
        guard viewModel.answeredQuestion else { return Color.orange.opacity(0.2) }
        
        // Kural 1: Doğru cevap her zaman yeşil yanar
        if option == viewModel.getMissingItem() {
            return .green
        }
        
        // Kural 2: Eğer yanlış şık seçildiyse o kırmızı yanar
        if option == viewModel.selectedOption && option != viewModel.getMissingItem() {
            return .red
        }
        
        return Color.clear
    }
}

#Preview {
    MissingLinkUI().environmentObject(RouterFeed())
}

