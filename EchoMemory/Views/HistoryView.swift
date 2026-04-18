import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedPeriod: Period = .week
    @State private var chartAppeared = false

    enum Period: String, CaseIterable {
        case week = "Semana"
        case month = "Mes"
    }

    var todayEntry: EmotionalEntry? {
        appState.emotionalEntries.last
    }

    var visibleEntries: [EmotionalEntry] {
        switch selectedPeriod {
        case .week: return Array(appState.emotionalEntries.suffix(7))
        case .month: return Array(appState.emotionalEntries.suffix(30))
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
        HStack(spacing: 8) {
            // Y-Axis Legend
            VStack(alignment: .trailing) {
                Text(EmotionalEntry.Mood.great.rawValue)
                    .font(.echoSmall)
                    .foregroundColor(EmotionalEntry.Mood.great.color)
                Spacer()
                Text(EmotionalEntry.Mood.neutral.rawValue)
                    .font(.echoSmall)
                    .foregroundColor(EmotionalEntry.Mood.neutral.color)
                Spacer()
                Text(EmotionalEntry.Mood.sad.rawValue)
                    .font(.echoSmall)
                    .foregroundColor(EmotionalEntry.Mood.sad.color)
            }
            .padding(.vertical, 10)
            .padding(.bottom, 24)
            .frame(width: 50)
            
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let width = geo.size.width - 16
                    let height = geo.size.height - 40
                    let stepX = entries.count > 1 ? width / CGFloat(entries.count - 1) : width
                    let points: [CGPoint] = entries.enumerated().map { i, entry in
                        CGPoint(
                            x: 8 + CGFloat(i) * stepX,
                            y: 10 + (1 - moodValue(entry.mood)) * (height - 10)
                        )
                    }

                    ZStack {
                        // Grid lines
                        ForEach([0, 1, 2], id: \.self) { i in
                            let y = 10 + CGFloat(i) * (height - 10) / 2
                            Path { path in
                                path.move(to: CGPoint(x: 8, y: y))
                                path.addLine(to: CGPoint(x: 8 + width, y: y))
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
                                    colors: [
                                        EmotionalEntry.Mood.great.color.opacity(0.3),
                                        EmotionalEntry.Mood.neutral.color.opacity(0.2),
                                        EmotionalEntry.Mood.sad.color.opacity(0.1)
                                    ],
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
                            .stroke(Color.echoTextSecondary.opacity(0.4), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
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
                            // For larger datasets (e.g. Month)
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
                            if entries.count <= 7 {
                                Text(entries[i].date.shortDay)
                                    .font(.echoSmall)
                                    .foregroundColor(Color.echoTextMuted)
                                    .frame(maxWidth: .infinity)
                            } else {
                                let dayInt = Calendar.current.component(.day, from: entries[i].date)
                                if dayInt % 5 == 0 || i == entries.count - 1 || i == 0 {
                                    Text("\(dayInt)")
                                        .font(.echoSmall)
                                        .foregroundColor(Color.echoTextMuted)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    Spacer()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .position(x: geo.size.width / 2, y: geo.size.height - 12)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.trailing, 16)
        .padding(.leading, 8)
    }
}



// MARK: - Entry Row
struct EntryRow: View {
    let entry: EmotionalEntry

    var body: some View {
        HStack(spacing: 14) {
            // Date
            VStack(spacing: 2) {
                Text(Calendar.current.isDateInToday(entry.date) ? "Hoy" : entry.date.shortDay)
                    .font(.echoSmall)
                    .foregroundColor(Calendar.current.isDateInToday(entry.date) ? Color.echoTeal : Color.echoTextMuted)
                Text(Calendar.current.component(.day, from: entry.date).description)
                    .font(.echoCaption)
                    .fontWeight(Calendar.current.isDateInToday(entry.date) ? .bold : .semibold)
                    .foregroundColor(Calendar.current.isDateInToday(entry.date) ? Color.echoTeal : Color.echoTextPrimary)
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
