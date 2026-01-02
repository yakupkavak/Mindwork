//
//  TimingGameUI.swift
//  Mindwork
//
//  Created by Cemre Bayer on 28.12.2025.
//

import SwiftUICore
import SwiftUI

struct TimingGameUI: View {
    @StateObject var viewModel = TimingGameViewModel()
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
                btnSystemIconTransparent(iconSystemName: "info.circle", color: .black) { }
            }

            // Progress Bar (Pattern Game ile aynı)
            ProgressView(value: viewModel.questionProgress)
                .padding(.top)
                .tint(.blue)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            Spacer()

            // Oyun Alanı
            VStack(spacing: 50) {
                Text("Tam merkezde durdur!")
                    .font(.headline)
                    .foregroundColor(.gray)

                ZStack {
                    // Ana Ray
                    Capsule()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 12)
                    
                    // Hedef Alanı (Pattern Game kutuları gibi belirgin)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 60)
                    
                    // Hedef Çizgisi
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 3, height: 40)

                    // Hareket Eden Obje
                    GeometryReader { geo in
                        Circle()
                            .fill(viewModel.gameResult?.color ?? .blue)
                            .frame(width: 35, height: 35)
                            .shadow(color: .black.opacity(0.2), radius: 5)
                            .offset(x: (geo.size.width - 35) * viewModel.barPosition)
                    }
                    .frame(height: 35)
                }
                .padding(.horizontal, 30)

                // Feedback Metni
                if let result = viewModel.gameResult {
                    Text(result.rawValue)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(result.color)
                        .transition(.scale)
                }
            }

            Spacer()

            // Kontrol Butonu
            Button(action: { viewModel.stopAndCheck() }) {
                Text(viewModel.answeredQuestion ? "BEKLEYİN..." : "ŞİMDİ!")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(viewModel.answeredQuestion ? Color.gray : Color.blue)
                    .cornerRadius(20)
                    .shadow(radius: 5)
            }
            .disabled(viewModel.answeredQuestion)
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
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
            acceptFunc: { viewModel.resetGame() },
            deniedFunc: { router.navigateBack() }
        )
    }
}

#Preview {
    TimingGameUI().environmentObject(RouterFeed())
}

