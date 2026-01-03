import SwiftUI

struct TimingGameUI: View {
    @StateObject var viewModel = TimingGameViewModel()
    @EnvironmentObject var router: RouterFeed

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    btnSystemIconTransparent(iconSystemName: Icons.left_direction, color: .black) {
                        router.navigateBack()
                    }
                    Spacer()
                    tvBodylineString(
                        text: "Level \(viewModel.level)",
                        color: .black
                    )
                    Spacer()
                    btnSystemIconTransparent(iconSystemName: "ellipsis.circle", color: .black) { }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Progress Bar
                ProgressView(value: viewModel.timeLeft, total: 5.0)
                    .padding(.top)
                    .tint(.orange300)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .padding(.horizontal, 20)

                // Timer & Score
                tvBodylineString(
                    text: String(format: "%.2f", viewModel.timeLeft),
                    color: .black
                )
                .padding(.top)
                
                if let result = viewModel.gameResult {
                    tvBodyline(text: LocalizedStringKey(result.rawValue), color: result.color)
                        .padding(.top, 4)
                } else {
                    Text("SCORE: \(viewModel.score)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }

                Spacer()

                // MARK: Game Area
                ZStack {
                    // Background Box
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.orange.opacity(0.1))
                        .frame(height: 160)
                        .padding(.horizontal, 20)

                    GeometryReader { geo in
                        let containerWidth = geo.size.width - 40
                        let ballSize: CGFloat = 40
                        let lineSize: CGFloat = 6
                        
                        let playableTrack = containerWidth - ballSize
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.black.opacity(0.08))
                                .frame(height: 4)
                                .frame(maxWidth: .infinity)

                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: lineSize, height: 70)
                                .offset(x: playableTrack * viewModel.targetPosition + (ballSize/2 - lineSize/2))
                            
                            // Moving Ball
                            Circle()
                                .fill(viewModel.gameResult == .miss ? .red : .orange)
                                .frame(width: ballSize, height: ballSize)
                                .offset(x: playableTrack * viewModel.barPosition)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                    .frame(height: 70)
                }
                Spacer()

                // MARK: Control Button
                VStack(spacing: 12) {
                    btnTextGradientInfinity(
                        action: {
                            viewModel.stopAndCheck()
                        },
                        text: viewModel.answeredQuestion ? "PLEASE WAIT" : "STOP"
                    )
                    .disabled(!viewModel.isGameStarted || viewModel.answeredQuestion)
                    .opacity((!viewModel.isGameStarted || viewModel.answeredQuestion) ? 0.6 : 1.0)
                    .padding(.horizontal, 64)
                }
                .padding(.bottom, 32)
            }
            .blur(radius: viewModel.isGameStarted ? 0 : 10)

            // MARK: Start Overlay
            if !viewModel.isGameStarted && !viewModel.gameOver {
                ZStack {
                    Color.white.opacity(0.92).ignoresSafeArea()
                    
                    VStack(spacing: 25) {
                        Image(systemName: "timer")
                            .font(.system(size: 70))
                            .foregroundColor(.orange)
                        
                        tvBodylineString(text: "HOW TO PLAY?", color: .black)
                        
                        Text("Press the STOP button when the ball is exactly over the orange line.\n\nIf you miss or run out of time, the game is over!")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        btnTextGradientInfinity(
                            action: {
                                withAnimation { viewModel.startGame() }
                            },
                            text: "START GAME"
                        )
                        .padding(.horizontal, 64)
                    }
                }
            }
        }
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
            acceptFunc: {
                viewModel.resetGameValues()
                viewModel.startGame()
            },
            deniedFunc: { router.navigateBack() }
        )
    }
}

#Preview {
    TimingGameUI().environmentObject(RouterFeed())
}

