import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPeriod: Period = .week
    @State private var chartAppeared = false

    enum Period: String, CaseIterable {
        case day = "Día"
        case week = "Semana"
        case month = "Mes"
    }

    var todayEntry: EmotionalEntry? {
        appState.emotionalEntries.last
    }

    var visibleEntries: [EmotionalEntry] {
        switch selectedPeriod {
        case .day: return Array(appState.emotionalEntries.suffix(1))
        case .week: return Array(appState.emotionalEntries.suffix(7))
        case .month: return Array(appState.emotionalEntries.suffix(30))
        }
    }

    var insightMessage: String {
        guard let today = todayEntry, let yesterday = appState.emotionalEntries.dropLast().last else {
            return "Registra cómo te sientes cada día."
        }
        if today.mood == .great && yesterday.mood != .great {
            return "Hoy te sentiste mejor que ayer. 💚"
        } else if today.mood == .sad {
            return "Hoy fue un día difícil. Está bien. 💜"
        } else {
            return "Llevas \(appState.emotionalEntries.filter { $0.mood == .great }.count) días sintiéndote bien."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Historial Emocional")
                        .font(.echoHeadline)
                        .foregroundColor(Color.echoTextPrimary)
                    Text("Cómo te has sentido")
                        .font(.echoCaption)
                        .foregroundColor(Color.echoTextSecondary)
                }
                Spacer()

                // Period selector
                HStack(spacing: 0) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Button {
                            withAnimation(.spring(response: 0.4)) { selectedPeriod = period }
                        } label: {
                            Text(period.rawValue)
                                .font(.echoSmall)
                                .fontWeight(selectedPeriod == period ? .semibold : .regular)
                                .foregroundColor(selectedPeriod == period ? Color.echoTeal : Color.echoTextMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selectedPeriod == period ? Color.echoTeal.opacity(0.12) : Color.clear)
                                .cornerRadius(10)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.echoTextPrimary.opacity(0.06), radius: 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // MARK: - Insight Banner
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 18))
                            .foregroundColor(Color.echoAmber)
                        Text(insightMessage)
                            .font(.echoBody)
                            .foregroundColor(Color.echoTextPrimary)
                        Spacer()
                    }
                    .padding(16)
                    .background(Color(hex: "#FFFBEC"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.echoAmber.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    // MARK: - Emotion Line Chart
                    EmotionLineChart(entries: visibleEntries, appeared: chartAppeared)
                        .frame(height: 180)
                        .padding(.horizontal, 20)
                        .echoCard()
                        .padding(.horizontal, 20)

                    // MARK: - Legend
                    HStack(spacing: 20) {
                        ForEach(EmotionalEntry.Mood.allCases, id: \.self) { mood in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(mood.color)
                                    .frame(width: 10, height: 10)
                                Text(mood.rawValue)
                                    .font(.echoSmall)
                                    .foregroundColor(Color.echoTextSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // MARK: - Today's Mood Logger
                    if selectedPeriod == .day {
                        MoodLoggerCard()
                            .padding(.horizontal, 20)
                    }

                    // MARK: - Entry list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tus días")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextPrimary)
                            .padding(.horizontal, 20)

                        ForEach(visibleEntries.reversed()) { entry in
                            EntryRow(entry: entry)
                                .padding(.horizontal, 20)
                        }
                    }

                    Spacer(minLength: 20)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 1.0)) {
                    chartAppeared = true
                }
            }
        }
    }
}

// MARK: - Emotion Line Chart (custom, no Charts framework needed)
struct EmotionLineChart: View {
    let entries: [EmotionalEntry]
    let appeared: Bool

    func moodValue(_ mood: EmotionalEntry.Mood) -> CGFloat {
        switch mood {
        case .great:   return 1.0
        case .neutral: return 0.5
        case .sad:     return 0.0
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let width = geo.size.width - 32
                let height = geo.size.height - 40
                let stepX = entries.count > 1 ? width / CGFloat(entries.count - 1) : width
                let points: [CGPoint] = entries.enumerated().map { i, entry in
                    CGPoint(
                        x: 16 + CGFloat(i) * stepX,
                        y: 10 + (1 - moodValue(entry.mood)) * (height - 10)
                    )
                }

                ZStack {
                    // Grid lines
                    ForEach([0, 1, 2], id: \.self) { i in
                        let y = 10 + CGFloat(i) * (height - 10) / 2
                        Path { path in
                            path.move(to: CGPoint(x: 16, y: y))
                            path.addLine(to: CGPoint(x: 16 + width, y: y))
                        }
                        .stroke(Color.echoTextMuted.opacity(0.1), lineWidth: 1)
                    }

                    // Gradient fill under line
                    if points.count > 1 {
                        Path { path in
                            path.move(to: CGPoint(x: points[0].x, y: height + 10))
                            path.addLine(to: points[0])
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                            path.addLine(to: CGPoint(x: points.last!.x, y: height + 10))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.echoTeal.opacity(0.2), Color.echoTeal.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .opacity(appeared ? 1 : 0)
                    }

                    // Line
                    if points.count > 1 {
                        Path { path in
                            path.move(to: points[0])
                            for point in points.dropFirst() {
                                path.addLine(to: point)
                            }
                        }
                        .trim(from: 0, to: appeared ? 1 : 0)
                        .stroke(Color.echoTeal, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .animation(.easeInOut(duration: 1.2), value: appeared)
                    }

                    // Data points
                    if entries.count <= 7 {
                        ForEach(entries.indices, id: \.self) { i in
                            let entry = entries[i]
                            let point = points[i]
                            Circle()
                                .fill(entry.mood.color)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .position(point)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(Double(i) * 0.08), value: appeared)
                        }
                    } else {
                        // For larger datasets (e.g. Month), show a dot for the current day only or smaller dots
                        ForEach(entries.indices, id: \.self) { i in
                            let entry = entries[i]
                            let point = points[i]
                            Circle()
                                .fill(entry.mood.color)
                                .frame(width: 6, height: 6)
                                .position(point)
                                .opacity(appeared ? 1 : 0)
                                .animation(.spring(response: 0.5).delay(Double(i) * 0.02), value: appeared)
                        }
                    }
                }

                // Day labels at bottom
                HStack(spacing: 0) {
                    ForEach(entries.indices, id: \.self) { i in
                        if entries.count <= 7 || i % 5 == 0 || i == entries.count - 1 {
                            Text(entries.count <= 7 ? entries[i].date.shortDay : "\(Calendar.current.component(.day, from: entries[i].date))")
                                .font(.echoSmall)
                                .foregroundColor(Color.echoTextMuted)
                                .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .position(x: geo.size.width / 2, y: geo.size.height - 12)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 0)
    }
}

// MARK: - Mood Logger Card
struct MoodLoggerCard: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedMood: EmotionalEntry.Mood? = nil
    @State private var logged = false

    var body: some View {
        VStack(spacing: 14) {
            Text("¿Cómo te sientes hoy?")
                .font(.echoSubheadline)
                .foregroundColor(Color.echoTextPrimary)

            HStack(spacing: 20) {
                ForEach(EmotionalEntry.Mood.allCases, id: \.self) { mood in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedMood = mood
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(mood.emoji)
                                .font(.system(size: 36))
                                .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                            Text(mood.rawValue)
                                .font(.echoSmall)
                                .foregroundColor(selectedMood == mood ? mood.color : Color.echoTextMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedMood == mood ? mood.color.opacity(0.12) : Color.clear)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedMood == mood ? mood.color : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }

            if let mood = selectedMood, !logged {
                Button {
                    withAnimation {
                        appState.emotionalEntries.append(
                            EmotionalEntry(date: Date(), mood: mood)
                        )
                        logged = true
                    }
                } label: {
                    Text("Guardar")
                        .font(.echoCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.echoTeal)
                        .cornerRadius(14)
                }
            }

            if logged {
                Label("¡Registrado con amor!", systemImage: "checkmark.circle.fill")
                    .font(.echoCaption)
                    .foregroundColor(Color.moodGreen)
            }
        }
        .padding(20)
        .echoCard()
    }
}

// MARK: - Entry Row
struct EntryRow: View {
    let entry: EmotionalEntry

    var body: some View {
        HStack(spacing: 14) {
            // Date
            VStack(spacing: 2) {
                Text(entry.date.shortDay)
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextMuted)
                Text(Calendar.current.component(.day, from: entry.date).description)
                    .font(.echoCaption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.echoTextPrimary)
            }
            .frame(width: 36)

            // Color indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(entry.mood.color)
                .frame(width: 4, height: 40)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.mood.emoji)
                    Text(entry.mood.rawValue)
                        .font(.echoCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(entry.mood.color)
                }
                if let note = entry.note {
                    Text(note)
                        .font(.echoSmall)
                        .foregroundColor(Color.echoTextSecondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .echoCard(cornerRadius: 14)
    }
}
