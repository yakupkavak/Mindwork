import SwiftUI

struct ReflexUI: View {
    @StateObject private var vm = ReflexGameViewModel()
    @EnvironmentObject var router: RouterFeed
    @State private var circleScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                btnSystemIconTransparent(iconSystemName: Icons.left_direction, color: .black) {
                    router.navigateBack()
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("SKOR").font(.caption2).bold().foregroundColor(.secondary)
                    Text("\(vm.score)").font(.title2).bold()
                }
                Spacer()
                btnSystemIconTransparent(iconSystemName: "arrow.counterclockwise", color: .black) {
                    vm.startGame()
                }
            }
            .padding(.horizontal)

            // Hedef Kartı
            VStack(spacing: 12) {
                Text("DOKUNULACAK RENK")
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
            .padding(.top, 5)

            Spacer()

            // Oyun Alanı
            ZStack {
                Circle()
                    .fill(vm.currentColor.color.opacity(0.2))
                    .frame(width: 270, height: 270)
                    .blur(radius: 40)
                    .animation(.easeInOut, value: vm.currentColor)
                
                Circle()
                    .fill(vm.currentColor.color)
                    .frame(width: 200, height: 200)
                    .scaleEffect(circleScale)
                    .shadow(color: vm.currentColor.color.opacity(0.3), radius: 15)
                    .onTapGesture {
                        triggerHaptic()
                        withAnimation(.interactiveSpring(response: 0.1, dampingFraction: 0.5)) {
                            circleScale = 0.85
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                circleScale = 1.0
                            }
                            vm.handleTap()
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: vm.currentColor)
            }

            Text(vm.message)
                .font(.footnote).bold()
                .foregroundColor(.gray)
                .frame(height: 40)

            Spacer()

            if vm.gameState == .ready {
                btnTextGradientInfinity(action: { vm.startGame() }, text: LocalizedStringKey("BAŞLA"))
                    .padding(.horizontal, 50)
                    .padding(.bottom, 30)
            }
        }
        .padding(.vertical)
        .customAnswerAlert(
            isPresented: $vm.gameOver,
            titleKey: LocalizedStringKey("Oyun Bitti"),
            trueCount: LocalizedStringKey("Doğru: \(vm.correctCount)"),
            wrongCount: LocalizedStringKey("\(vm.message)"),
            averageAnswer: LocalizedStringKey(String(format: "Hızın: %.2f sn", vm.averageResponseTime)),
            accuracy: LocalizedStringKey("Skor: \(vm.score)"),
            acceptText: LocalizedStringKey("Yeniden Dene"),
            deniedText: LocalizedStringKey("Kapat"),
            acceptFunc: { vm.startGame() },
            deniedFunc: { router.navigateBack() }
        )
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    ReflexUI().environmentObject(RouterFeed())
}
