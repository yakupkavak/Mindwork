import SwiftUI

struct ReflexUI: View {
    @StateObject private var vm = ReflexGameViewModel()
    @EnvironmentObject var router: RouterFeed
    @State private var circleScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // MARK: - Header
                HStack {
                    btnSystemIconTransparent(iconSystemName: Icons.left_direction, color: .black) {
                        router.navigateBack()
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Text("SCORE").font(.caption2).bold().foregroundColor(.secondary)
                        Text("\(vm.score)").font(.title2).bold()
                    }
                    
                    Spacer()
                    
                    btnSystemIconTransparent(iconSystemName: "arrow.counterclockwise", color: .black) {
                        vm.startGame()
                    }
                }
                .padding(.horizontal)

                // MARK: - Target Card
                VStack(spacing: 12) {
                    Text("COLOR TO TAP")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.secondary)
                        .tracking(2)
                    
                    Text(vm.targetColor.name.uppercased())
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundColor(vm.targetColor.color)
                        .padding(.horizontal, 35)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(vm.targetColor.color.opacity(0.12))
                        )
                }
                .opacity(vm.gameState == .ready ? 0.0 : 1.0)

                Spacer()

                // MARK: - Game Area
                ZStack {
                    Circle()
                        .fill(vm.currentColor.color.opacity(0.2))
                        .frame(width: 270, height: 270)
                        .blur(radius: 40)
                    
                    Circle()
                        .fill(vm.currentColor.color)
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)
                        .shadow(color: vm.currentColor.color.opacity(0.3), radius: 15)
                        .onTapGesture {
                            if vm.gameState == .running {
                                triggerHaptic()
                                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.4)) {
                                    circleScale = 0.85
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                        circleScale = 1.0
                                    }
                                    vm.handleTap()
                                }
                            }
                        }
                    
                    if vm.gameState == .countdown {
                        Text(vm.countdownText)
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                Text(vm.gameState == .countdown ? "GET READY..." : vm.message)
                    .font(.footnote).bold()
                    .foregroundColor(.gray)
                    .frame(height: 40)

                Spacer()
            }
            .padding(.vertical)
            .blur(radius: vm.gameState == .ready ? 10 : 0)

            // MARK: - "How to Play?" Intro Screen
            if vm.gameState == .ready {
                Color.white.opacity(0.95).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 15) {
                        Text("HOW TO PLAY?")
                            .font(.title2).bold()
                        
                        Text("Tap when you catch the target color\namong the changing colors on the screen.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Text("Game ends if you tap the wrong color!")
                            .font(.footnote)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    
                    btnTextGradientInfinity(action: {
                        vm.startGame()
                    }, text: "START GAME")
                    .padding(.horizontal, 64)
                }
            }
        }
        .navigationBarHidden(true)
        .customAnswerAlert(
            isPresented: $vm.gameOver,
            titleKey: LocalizedStringKey("Game Over"),
            trueCount: LocalizedStringKey("Correct: \(vm.correctCount)"),
            wrongCount: LocalizedStringKey("\(vm.message)"),
            averageAnswer: LocalizedStringKey(String(format: "Speed: %.2f s", vm.averageResponseTime)),
            accuracy: LocalizedStringKey("Score: \(vm.score)"),
            acceptText: LocalizedStringKey("Try Again"),
            deniedText: "Main Screen",
            acceptFunc: { vm.startGame() },
            deniedFunc: { router.navigateBack() }
        )
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}

#Preview {
    ReflexUI().environmentObject(RouterFeed())
}
