import SwiftUI

struct PatternGameUI: View {
    @StateObject var viewModel = PatternGameViewModel()
    @EnvironmentObject var router: RouterFeed

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    btnSystemIconTransparent(iconSystemName: Icons.left_direction, color: .black) {
                        router.navigateBack()
                    }
                    Spacer()
                    Text(LocalizedStringKey("SORU \(viewModel.questionNumber) / 10"))
                        .font(.subheadline).bold()
                    Spacer()
                    btnSystemIconTransparent(iconSystemName: "ellipsis.circle", color: .black) { }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                ProgressView(value: viewModel.questionProgress)
                    .padding(.top, 20)
                    .tint(.orange)
                    .scaleEffect(x: 1, y: 2)
                    .padding(.horizontal, 20)

                VStack(spacing: 5) {
                    Text(String(format: "%.2f", viewModel.timeCounter))
                        .font(.system(.body, design: .monospaced))
                    
                    if let isTrue = viewModel.isTrue {
                        Text(isTrue ? "DOĞRU!" : "YANLIŞ!")
                            .font(.headline).bold()
                            .foregroundColor(isTrue ? .green : .red)
                    } else {
                        Text("Mantığı çöz ve eksik öğeyi bul!")
                            .font(.subheadline).foregroundColor(.gray)
                    }
                }
                .padding(.top, 15)

                // MARK: - Soru Alanı (Taşma Çözümü)
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.orange.opacity(0.1))
                        .frame(height: 140)
                        .padding(.horizontal, 20)
                    
                    // Taşmayı önlemek için ScrollView içinde limitli bir alan
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<viewModel.displaySequence.count, id: \.self) { index in
                                PatternItemView(item: viewModel.displaySequence[index])
                            }
                        }
                        .padding(.horizontal, 35) // İçeriden padding vererek kenarlardan kurtarıyoruz
                    }
                }
                .padding(.top, 30)

                Spacer()

                // MARK: - Seçenekler
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(0..<viewModel.options.count, id: \.self) { index in
                        Button(action: {
                            viewModel.checkAnswer(viewModel.options[index])
                        }) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.gray.opacity(0.08))
                                .frame(height: 90)
                                .overlay(PatternItemView(item: viewModel.options[index]))
                        }
                        .disabled(viewModel.answeredQuestion)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .blur(radius: viewModel.gameState == .ready ? 10 : 0)

            if viewModel.gameState == .ready {
                startOverlay
            }
        }
        .navigationBarHidden(true)
        .customAnswerAlert(
            isPresented: $viewModel.gameOver,
            titleKey: LocalizedStringKey("Oyun Bitti"),
            trueCount: LocalizedStringKey("Doğru: \(viewModel.correctCount)"),
            wrongCount: LocalizedStringKey("Yanlış: \(viewModel.wrongCount)"),
            averageAnswer: LocalizedStringKey(String(format: "Hız: %.2f sn", viewModel.averageResponseTime)),
            accuracy: LocalizedStringKey(String(format: "Başarı: %%.0f", viewModel.percentageTruth)),
            acceptText: LocalizedStringKey("Tekrar Dene"),
            deniedText: LocalizedStringKey("Ana Ekran"),
            acceptFunc: { viewModel.startAgain() },
            deniedFunc: { router.navigateBack() }
        )
    }

    private var startOverlay: some View {
        ZStack {
            Color.white.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 30) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80)).foregroundColor(.orange)
                Text("PATTERN MASTER").font(.title2).bold()
                btnTextGradientInfinity(action: {
                    withAnimation { viewModel.startGame() }
                }, text: "BAŞLA").padding(.horizontal, 64)
            }
        }
    }
}

// MARK: - Item View
struct PatternItemView: View {
    let item: PatternGameViewModel.PatternItem
    
    var body: some View {
        ZStack {
            switch item {
            case .number(let val):
                Text("\(val)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(width: 55, height: 55)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2)
            case .placeholder:
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 55, height: 55)
                    .overlay(Text("?").bold().foregroundColor(.orange))
            case .shape(let icon):
                Image(systemName: icon)
                    .font(.system(size: 25))
                    .frame(width: 55, height: 55)
                    .background(Color.white)
                    .cornerRadius(12)
                    .foregroundColor(.blue)
            case .color(let color):
                Circle().fill(color).frame(width: 40, height: 40)
                    .frame(width: 55, height: 55)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
}
#Preview {
    PatternGameUI().environmentObject(RouterFeed())
}

