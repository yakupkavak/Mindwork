import SwiftUI

struct PatternGameUI: View {
    @StateObject var viewModel = PatternGameViewModel()
    @EnvironmentObject var router: RouterFeed

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header (Soru Sayacı)
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

                ProgressView(value: viewModel.questionProgress)
                    .padding(.top, 10)
                    .tint(.orange)
                    .padding(.horizontal, 20)

                // Timer ve Geri Bildirim
                VStack(spacing: 5) {
                    Text(String(format: "%.2f", viewModel.timeCounter))
                        .font(.system(.body, design: .monospaced))
                    
                    if let isTrue = viewModel.isTrue {
                        Text(isTrue ? "MÜKEMMEL!" : "TEKRAR DENE!")
                            .font(.headline).bold()
                            .foregroundColor(isTrue ? .green : .red)
                    } else {
                        Text("Eksik parçayı sence hangisi tamamlar?")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                .padding(.top, 15)

                // Soru Alanı
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.orange.opacity(0.05))
                        .frame(height: 160)
                        .padding(.horizontal, 15)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.displaySequence.count, id: \.self) { index in
                            PatternItemView(item: viewModel.displaySequence[index])
                        }
                    }
                }
                .padding(.top, 20)

                Spacer()

                // Seçenekler
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.options, id: \.self) { item in
                        Button(action: {
                            viewModel.checkAnswer(item)
                        }) {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                                .frame(height: 100)
                                .overlay(PatternItemView(item: item))
                                .overlay(
                                    // Doğru/Yanlış Çerçeve Geri Bildirimi
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(getBorderColor(for: item), lineWidth: 4)
                                )
                        }
                        .disabled(viewModel.answeredQuestion)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .blur(radius: viewModel.gameState == .ready ? 10 : 0)

            if viewModel.gameState == .ready {
                startOverlay
            }
        }
        .navigationBarHidden(true)
        .customAnswerAlert(
            isPresented: $viewModel.gameOver,
            titleKey: LocalizedStringKey("MindWorks Tamamlandı"),
            trueCount: LocalizedStringKey("Doğru: \(viewModel.correctCount)"),
            wrongCount: LocalizedStringKey("Yanlış: \(viewModel.wrongCount)"),
            averageAnswer: LocalizedStringKey(String(format: "Hız: %.2f sn", viewModel.averageResponseTime)),
            accuracy: LocalizedStringKey(String(format: "Başarı: %%.0f", viewModel.percentageTruth)),
            acceptText: LocalizedStringKey("Yeniden Başla"),
            deniedText: LocalizedStringKey("Kapat"),
            acceptFunc: { viewModel.startAgain() },
            deniedFunc: { router.navigateBack() }
        )
    }

    // Doğru şık yeşil, yanlış seçilen kırmızı
    private func getBorderColor(for item: PatternGameViewModel.PatternItem) -> Color {
        guard viewModel.answeredQuestion else { return .clear }
        
        if item == viewModel.correctOption {
            return .green
        }
        
        if item == viewModel.selectedOption && viewModel.isTrue == false {
            return .red
        }
        
        return .clear
    }

    private var startOverlay: some View {
        ZStack {
            Color.white.opacity(0.97).ignoresSafeArea()
            VStack(spacing: 25) {
                Image(systemName: "lightbulb.circle.fill")
                    .font(.system(size: 90)).foregroundColor(.orange)
                
                VStack(spacing: 12) {
                    Text("NASIL OYNANIR?").font(.title2).bold()
                    VStack(alignment: .leading, spacing: 10) {
                        instructionRow(icon: "1.circle.fill", text: "Önce dizideki sayıların veya şekillerin artış mantığını çöz.")
                        instructionRow(icon: "2.circle.fill", text: "Şekillerin sayısına veya kenar sayılarına dikkat et.")
                        instructionRow(icon: "3.circle.fill", text: "Soru işareti yerine gelecek doğru öğeyi aşağıdan seç.")
                    }
                    .padding(.horizontal, 30)
                }

                btnTextGradientInfinity(action: {
                    withAnimation { viewModel.startGame() }
                }, text: "OYUNA BAŞLA").padding(.horizontal, 64)
            }
        }
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon).foregroundColor(.orange)
            Text(text).font(.subheadline).foregroundColor(.secondary)
        }
    }
}

// MARK: - Pattern Item View
struct PatternItemView: View {
    let item: PatternGameViewModel.PatternItem
    
    var body: some View {
        ZStack {
            switch item {
            case .number(let val):
                Text("\(val)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(width: 55, height: 55)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2)
            case .placeholder:
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 55, height: 55)
                    .overlay(Text("?").bold().foregroundColor(.orange))
            case .shape(let icon, let count):
                let safeCount = max(1, count)
                VStack(spacing: 2) {
                    let gridItems = Array(repeating: GridItem(.flexible(), spacing: 2), count: min(safeCount, 3))
                    LazyVGrid(columns: gridItems, spacing: 2) {
                        ForEach(0..<min(safeCount, 9), id: \.self) { _ in
                            Image(systemName: icon)
                                .font(.system(size: safeCount > 4 ? 8 : 12))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(width: 55, height: 55)
                .background(Color.white)
                .cornerRadius(12)
            case .color(let color):
                RoundedRectangle(cornerRadius: 12).fill(color)
                    .frame(width: 55, height: 55)
            }
        }
    }
}

#Preview {
    PatternGameUI().environmentObject(RouterFeed())
}

