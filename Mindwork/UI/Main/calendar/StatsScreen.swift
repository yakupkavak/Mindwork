import SwiftUI
import Charts
import Kingfisher
import Combine
import FirebaseAuth
import FirebaseFirestore

struct CalendarUI: View {
    @StateObject private var vm = StatsViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        rangePicker
                        
                        // 🔥 AI KART ALANI
                        if let insight = vm.aiInsight {
                            aiFeedbackCard(insight: insight)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            emptyStateCard
                                .transition(.opacity)
                        }
                        
                        chartCard
                        scoresSection
                        badgesSection
                        gamesSection
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await vm.reloadAsync()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                vm.startListening()
            }
        }
    }
}

// MARK: - Helper Components

// Metin genişletme bileşeni (Artık formatlama yapmıyor, temiz metin alıyor)
struct ExpandableText: View {
    let text: String
    let lineLimit: Int
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .lineLimit(isExpanded ? nil : lineLimit)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.easeInOut, value: isExpanded)
            
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Show Less" : "Read More")
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .font(.caption.bold())
                .foregroundColor(.indigo)
                .padding(.top, 2)
            }
        }
    }
}

private struct RangePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(backgroundView)
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        let fillColor: Color = isSelected ? .black : Color(.secondarySystemBackground)
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(fillColor)
    }
}

// MARK: - CalendarUI Extensions & Cards

private extension CalendarUI {
    
    // --- Header ---
    var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Hi, \(vm.user.name)")
                        .font(.title3).fontWeight(.semibold)
                    Text("👋")
                }
                Text("This is your progress report")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            KFImage.profile(urlString: vm.user.profileImageUrl, size: 60)
        }
        .padding(.top, 8)
    }
    
    // --- Range Picker ---
    var rangePicker: some View {
        HStack(spacing: 8) {
            ForEach(StatsRange.allCases, id: \.self) { r in
                RangePill(
                    title: r.rawValue,
                    isSelected: vm.selected == r,
                    action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            vm.selected = r
                        }
                    }
                )
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color(.tertiarySystemBackground))
        )
    }
    
    // --- Boş Durum Kartı ---
    var emptyStateCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Unlock Dr. Insight")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Play 5 games to unlock your personalized AI brain analysis!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // 🔥 GÜNCELLENMİŞ AI KARTI (Formatlama düzeltildi)
    func aiFeedbackCard(insight: AIInsightModel) -> some View {
        let themeColor = colorForPattern(insight.patternType)
        
        return VStack(alignment: .leading, spacing: 0) {
            
            // --- Header: Badge & Score ---
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: iconForPattern(insight.patternType))
                            .foregroundStyle(themeColor)
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.patternType?.uppercased() ?? "ANALYSIS")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(themeColor)
                            .tracking(0.5)
                        
                        Text("Dr. Insight Report")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let score = insight.focusScore {
                    HStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("/100")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemBackground).opacity(0.5))
            
            Divider()
            
            // --- İçerik ---
            VStack(alignment: .leading, spacing: 14) {
                
                // Başlık
                Text(insight.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // 🔥 Mesaj (ExpandableText içinde formatlama uyguluyoruz)
                ExpandableText(
                    text: formatGameNames(insight.message),
                    lineLimit: 3
                )
                
                // 🔥 İstatistik Rozeti (Burada formatlama EKSİKTİ, eklendi)
                if let stat = insight.improvementStat {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.green)
                        
                        // BURASI DÜZELTİLDİ: formatGameNames()
                        Text(formatGameNames(stat))
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // 🔥 Aksiyon Kutusu (Formatlama uygulandı)
                if let tip = insight.actionableTip {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title3)
                            .foregroundStyle(.yellow)
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CLINICAL RECOMMENDATION")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            // BURASI DÜZELTİLDİ: formatGameNames()
                            Text(formatGameNames(tip))
                                .font(.callout)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.yellow.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
        .padding(.vertical, 4)
    }
    
    // --- Helper Logic (Formatlama) ---
    
    // 🔥 Metin içindeki which_different gibi kelimeleri düzelten fonksiyon
    func formatGameNames(_ rawText: String) -> String {
        var processedText = rawText
        
        let replacements: [String: String] = [
            "which_different": "Which Different",
            "colorful_words": "Colorful Words",
            "catch_pair": "Catch Pair",
            "firefly_title": "Firefly",
            "reflex": "Reflex",
            "missing_link": "Missing Link",
            "pattern_game": "Pattern Game",
            "timing": "Timing",
            "reverse_word": "Reverse Word"
        ]
        
        for (key, value) in replacements {
            // Önce tırnaklı versiyonları değiştir (AI bazen 'which_different' yazar)
            processedText = processedText.replacingOccurrences(of: "'\(key)'", with: "'\(value)'")
            processedText = processedText.replacingOccurrences(of: "‘\(key)’", with: "‘\(value)’") // Akıllı tırnak
            
            // Sonra tırnaksız versiyonları değiştir
            processedText = processedText.replacingOccurrences(of: key, with: value)
        }
        
        return processedText
    }
    
    func colorForPattern(_ pattern: String?) -> Color {
        switch pattern {
        case "Optimal Flow State", "Sustained Focus": return .green
        case "Impulsive Tendencies": return .orange
        case "Attentional Drift", "High Variability": return .yellow
        case "Cognitive Fatigue": return .blue
        default: return .indigo
        }
    }
    
    func iconForPattern(_ pattern: String?) -> String {
        switch pattern {
        case "Optimal Flow State": return "trophy.fill"
        case "Sustained Focus": return "brain.head.profile"
        case "Impulsive Tendencies": return "bolt.fill"
        case "Attentional Drift": return "eye.slash.fill"
        case "High Variability": return "waveform.path.ecg"
        case "Cognitive Fatigue": return "battery.25"
        default: return "sparkles"
        }
    }
    
    // --- Existing Chart/Score Views ---
    
    var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart(vm.series) { point in
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Gradient(colors: [
                    Color.green.opacity(0.25),
                    Color.green.opacity(0.05)
                ]))
                
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(.init(lineWidth: 2))
                .foregroundStyle(.green)
                
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .symbolSize(10)
                .foregroundStyle(.green.opacity(0.6))
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            
            HStack {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(vm.selected.rawValue)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.background))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
    }
    
    var scoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Scores")
                .font(.headline)
            
            VStack(spacing: 10) {
                scoreRow(icon: "timer", title: labelForTimeTitle(), value: formatMinutesDouble(vm.totalMinutes))
                scoreRow(icon: "checkmark.seal", title: "Success Rate", value: "\(Int(vm.successRate * 100))%")
                scoreRow(icon: "flag.checkered", title: goalTitle(), value: vm.goalDone ? "Done" : "Pending")
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.background))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
    }
    
    func formatMinutesDouble(_ minutes: Double) -> String {
        String(format: "%.2f min", minutes)
    }
    
    func scoreRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.green.opacity(0.15)))
                .foregroundStyle(.green)
                .clipShape(Circle())
            VStack(alignment: .leading) {
                Text(title).font(.subheadline)
                Text(value).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
    var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.badges) { b in
                        VStack(spacing: 8) {
                            Image(systemName: b.systemImage)
                                .font(.title2)
                                .foregroundStyle(b.earned ? .yellow : .secondary)
                                .frame(width: 56, height: 56)
                                .background(
                                    Circle()
                                        .fill(b.earned ? Color.yellow.opacity(0.15) : Color(.secondarySystemBackground))
                                )
                            Text(b.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.background))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(b.earned ? Color.yellow.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.background))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
    }
    
    var levelSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Level 4 • XP", systemImage: "star.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(vm.levelXP.current)/\(vm.levelXP.max)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(vm.levelXP.current), total: Double(vm.levelXP.max))
                .tint(.green)
                .animation(.easeInOut(duration: 0.35), value: vm.levelXP.current)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.background))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
    }
    
    var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(vm.categories) { c in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(c.name, systemImage: c.icon)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text("Level XP \(c.levelXP.current)/\(c.levelXP.max)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: c.progress)
                            .tint(.green)
                            .animation(.easeInOut(duration: 0.35), value: c.progress)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.background))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
    }
    
    var gamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Statistics")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(vm.games) { g in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(g.name)
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(String(format: "Avg %.2f s", g.avgSeconds))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        ProgressView(value: g.successRate)
                            .tint(.green)
                            .animation(.easeInOut(duration: 0.35), value: g.successRate)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text("Success Rate \(Int(g.successRate * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(.background))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
    }
}

private extension CalendarUI {
    func formatMinutes(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes) minute" }
        let h = minutes / 60
        let m = minutes % 60
        return "\(h)h \(m)m"
    }
    func labelForTimeTitle() -> String {
        switch vm.selected {
        case .today: return "Today's Time"
        case .week:  return "This Week's Time"
        case .month: return "This Month Time"
        }
    }
    func goalTitle() -> String {
        switch vm.selected {
        case .today: return "Daily Goal"
        case .week:  return "Weekly Goal"
        case .month: return "Monthly Goal"
        }
    }
}

struct StatsScreen_Previews: PreviewProvider {
    static var previews: some View {
        CalendarUI()
            .environment(\.colorScheme, .light)
    }
}
