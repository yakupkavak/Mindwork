import SwiftUI

struct ReflexUI: View {
    @StateObject private var vm = ReflexGameViewModel()
    @EnvironmentObject var router: RouterFeed
    @State private var circleScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                // MARK: - Header (Pattern Game Stili)
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

                // MARK: - Hedef Kartı
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
                // Geri sayım sırasında hedef rengin görünmesi için opacity ayarlandı
                .opacity(vm.gameState == .ready ? 0.0 : 1.0)

                Spacer()

                // MARK: - Oyun Alanı
                ZStack {
                    Circle()
                        .fill(vm.currentColor.color.opacity(0.2))
                        .frame(width: 270, height: 270)
                        .blur(radius: 40)
                    
                    Circle()
                        .fill(vm.currentColor.color)
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale) // Basma efekti
                        .shadow(color: vm.currentColor.color.opacity(0.3), radius: 15)
                        .onTapGesture {
                            if vm.gameState == .running {
                                triggerHaptic()
                                // İçe çökme efekti
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

                Text(vm.gameState == .countdown ? "HAZIRLAN..." : vm.message)
                    .font(.footnote).bold()
                    .foregroundColor(.gray)
                    .frame(height: 40)

                Spacer()
            }
            .padding(.vertical)
            .blur(radius: vm.gameState == .ready ? 10 : 0)

            // MARK: - "Nasıl Oynanır?" Giriş Ekranı
            if vm.gameState == .ready {
                Color.white.opacity(0.95).ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 15) {
                        Text("NASIL OYNANIR?")
                            .font(.title2).bold()
                        
                        Text("Ekranda değişen renkler arasından\nhedef rengi yakaladığında dokun.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Text("Yanlış renge basarsan oyun biter!")
                            .font(.footnote)
                            .foregroundColor(.red.opacity(0.8))
                    }
                    
                    btnTextGradientInfinity(action: {
                        vm.startGame()
                    }, text: "OYUNU BAŞLAT")
                    .padding(.horizontal, 64)
                }
            }
        }
        .navigationBarHidden(true) // Sistem back tuşunu tamamen gizler
        .customAnswerAlert(
            isPresented: $vm.gameOver,
            titleKey: LocalizedStringKey("Oyun Bitti"),
            trueCount: LocalizedStringKey("Doğru: \(vm.correctCount)"),
            wrongCount: LocalizedStringKey("\(vm.message)"),
            averageAnswer: LocalizedStringKey(String(format: "Hızın: %.2f sn", vm.averageResponseTime)),
            accuracy: LocalizedStringKey("Skor: \(vm.score)"),
            acceptText: LocalizedStringKey("Yeniden Dene"),
            deniedText: "Ana Ekran",
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
