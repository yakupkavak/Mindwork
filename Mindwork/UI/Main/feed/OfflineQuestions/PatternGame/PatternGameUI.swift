//
//  PatternGameUI.swift
//  Mindwork
//
//  Created by Cemre Bayer on 2.01.2026.
//
import SwiftUI

struct PatternGameUI: View {
    @StateObject var viewModel = PatternGameViewModel()
    @EnvironmentObject var router: RouterFeed

    var body: some View {
        VStack {
            // Header
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
                btnSystemIconTransparent(iconSystemName: "ellipsis.circle", color: .black) { }
            }

            // Progress Bar
            ProgressView(value: viewModel.questionProgress)
                .padding(.top)
                .tint(.orange300)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            // Timer ve Feedback
            tvBodylineString(text: String(format: "%.2f", viewModel.timeCounter), color: .black).padding(.top)
            
            if let isTrue = viewModel.isTrue {
                tvBodyline(text: isTrue ? StringKey.true_answer : StringKey.wrong_answer, color: isTrue ? .green : .red)
            } else {
                Text(viewModel.questionTitle).font(.subheadline).foregroundColor(.gray).padding(.top, 4)
            }

            // Pattern Soru Kutusu
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.orange.opacity(0.1))
                    .frame(height: 140)
                
                HStack(spacing: 12) {
                    ForEach(0..<viewModel.sequence.count, id: \.self) { index in
                        PatternItemView(item: viewModel.sequence[index])
                    }
                    
                    // Soru İşareti Alanı
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, dash: [4]))
                        .frame(width: 60, height: 60)
                        .overlay(Text("?").font(.title2).bold().foregroundColor(.orange))
                }
            }
            .padding(.top, 30)

            Spacer()

            // Seçenekler (Keyboards stili)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(0..<viewModel.options.count, id: \.self) { index in
                    Button(action: { viewModel.checkAnswer(viewModel.options[index]) }) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.08))
                            .frame(height: 100)
                            .overlay(PatternItemView(item: viewModel.options[index]))
                    }
                    .disabled(viewModel.answeredQuestion)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .padding()
        .navigationBarHidden(true)
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

// Elemanları Render Eden Alt Görünüm
struct PatternItemView: View {
    let item: PatternGameViewModel.PatternItem
    
    var body: some View {
        switch item {
        case .number(let val):
            Text("\(val)").font(.system(size: 28, weight: .bold, design: .rounded))
        case .color(let color):
            Circle().fill(color).frame(width: 45, height: 45)
        case .shape(let icon):
            Image(systemName: icon).font(.system(size: 32)).foregroundColor(.blue)
        }
    }
}

#Preview {
    PatternGameUI().environmentObject(RouterFeed())
}

