//
//  MissingLinkUI.swift
//  Mindwork
//
//  Created by Cemre Bayer on 2.01.2026.
//
import SwiftUI

struct MissingLinkUI: View {
    @StateObject var viewModel = MissingLinkViewModel()
    @EnvironmentObject var router: RouterFeed
    
    let columns = [GridItem(.adaptive(minimum: 70))]

    var body: some View {
        VStack {
            // Header: Geri butonu ve Soru Sayısı
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
                Image(systemName: "brain.head.profile").opacity(0) // Denge için
            }

            // Progress Bar
            ProgressView(value: viewModel.questionProgress)
                .padding(.top)
                .tint(.orange300)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            // Timer ve Bilgi Mesajı
            tvBodylineString(text: String(format: "%.2f", viewModel.timeCounter), color: .black).padding(.top)
            
            if let isTrue = viewModel.isTrue {
                tvBodyline(text: isTrue ? StringKey.true_answer : StringKey.wrong_answer, color: isTrue ? .green : .red)
            } else {
                Text(viewModel.questionTitle).font(.subheadline).foregroundColor(.gray).padding(.top, 4)
            }

            // Ana Oyun Alanı (Izgara)
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
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .padding(.top, 20)
            .frame(maxHeight: .infinity)

            // Cevap Şıkları (Sadece quiz fazında ve cevaplanmamışsa)
            VStack(spacing: 15) {
                if !viewModel.preparingGame {
                    Text("Hangi nesne eksik?").font(.caption).bold().foregroundColor(.orange)
                    HStack(spacing: 20) {
                        ForEach(viewModel.options, id: \.self) { option in
                            Button(action: { viewModel.checkAnswer(selected: option) }) {
                                Text(option)
                                    .font(.system(size: 40))
                                    .frame(width: 70, height: 70)
                                    .background(viewModel.answeredQuestion ? Color.gray.opacity(0.2) : Color.orange.opacity(0.15))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.orange, lineWidth: 1)
                                    )
                            }
                            .disabled(viewModel.answeredQuestion)
                        }
                    }
                }
            }
            .padding(.bottom, 40)
            .opacity(viewModel.preparingGame ? 0 : 1)
            .animation(.easeInOut, value: viewModel.preparingGame)
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

#Preview {
    MissingLinkUI().environmentObject(RouterFeed())
}

