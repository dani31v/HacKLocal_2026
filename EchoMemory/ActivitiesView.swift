import SwiftUI

struct AIActivitiesView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedActivity: Activity?
    @State private var showActivityDetail = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // MARK: - Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Actividades")
                            .font(.echoTitle)
                            .foregroundColor(Color.echoTextPrimary)
                        Text("Personalizadas para ti")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // MARK: - Emotion Status
                if let emotion = appState.todayEmotion {
                    EmotionStatusCard(emotion: emotion)
                        .padding(.horizontal, 20)
                } else {
                    NoEmotionCard()
                        .padding(.horizontal, 20)
                }
                
                // MARK: - Activities List
                if appState.isGeneratingActivities {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generando actividades personalizadas...")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else if !appState.todayActivities.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actividades recomendadas")
                            .font(.echoHeadline)
                            .foregroundColor(Color.echoTextPrimary)
                            .padding(.horizontal, 20)
                        
                        ForEach($appState.todayActivities) { $activity in
                            AIActivityCard(activity: $activity)
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    selectedActivity = activity
                                    showActivityDetail = true
                                }
                        }
                    }
                } else if appState.todayEmotion != nil {
                    // Emoción registrada pero sin actividades
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50))
                            .foregroundColor(Color.echoTeal.opacity(0.5))
                        Text("No hay actividades generadas")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                        Text("Intenta registrar tu emoción de nuevo")
                            .font(.echoSmall)
                            .foregroundColor(Color.echoTextMuted)
                    }
                    .padding(40)
                }
                
                Spacer(minLength: 40)
            }
        }
        .sheet(isPresented: $showActivityDetail) {
            if let activity = selectedActivity {
                ActivityDetailView(activity: Binding(
                    get: { activity },
                    set: { newValue in
                        if let index = appState.todayActivities.firstIndex(where: { $0.id == activity.id }) {
                            appState.todayActivities[index] = newValue
                        }
                        selectedActivity = newValue
                    }
                ))
                .environmentObject(appState)
            }
        }
    }
}

// MARK: - Emotion Status Card
struct EmotionStatusCard: View {
    let emotion: CapturedEmotion
    
    var body: some View {
        HStack(spacing: 16) {
            // Emoji grande basado en emoción
            Text(emotionEmoji)
                .font(.system(size: 50))
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Tu emoción de hoy")
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextMuted)
                
                Text(emotion.emotion)
                    .font(.echoTitle)
                    .foregroundColor(Color.echoTextPrimary)
                
                Text(emotion.displayMessage)
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextSecondary)
            }
            
            Spacer()
        }
        .padding(20)
        .cornerRadius(20)
        .background(Color(hex: "#FFFBEC"))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    emotion.isPositive ? Color.moodGreen.opacity(0.3) : Color.echoTeal.opacity(0.2),
                    lineWidth: 1.5
                )
        )
    }
    
    var emotionEmoji: String {
        switch emotion.emotion.lowercased() {
        case "feliz": return "😊"
        case "triste": return "😔"
        case "neutral": return "😐"
        case "enojado": return "😠"
        case "sorprendido": return "😮"
        default: return "🙂"
        }
    }
}

// MARK: - No Emotion Card
struct NoEmotionCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "face.dashed")
                .font(.system(size: 50))
                .foregroundColor(Color.echoTeal.opacity(0.5))
            
            Text("Aún no has registrado tu emoción hoy")
                .font(.echoSubheadline)
                .foregroundColor(Color.echoTextPrimary)
                .multilineTextAlignment(.center)
            
            Text("Ve a Inicio y toma una foto para recibir actividades personalizadas")
                .font(.echoSmall)
                .foregroundColor(Color.echoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button {
                withAnimation {
                    appState.selectedTab = .home
                }
            } label: {
                Text("Ir a Inicio")
                    .font(.echoSubheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(Color.echoTeal)
                    .cornerRadius(14)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#FFFBEC"))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.echoTeal.opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - AI Activity Card
struct AIActivityCard: View {
    @Binding var activity: Activity
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
        
                Circle()
                    .fill(activity.category.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: activity.icon)
                    .font(.system(size: 24))
                    .foregroundColor(activity.category.color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.echoHeadline)
                    .foregroundColor(Color.echoTextPrimary)
                
                Text(activity.description)
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Label(activity.duration, systemImage: "clock.fill")
                        .font(.echoSmall)
                        .foregroundColor(activity.category.color)
                    
                    Text(activity.category.rawValue)
                        .font(.echoSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(activity.category.color.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(activity.category.color.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Checkmark
            Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "chevron.right")
                .font(.system(size: 24))
                .foregroundColor(activity.isCompleted ? Color.moodGreen : Color.echoTextMuted)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    activity.isCompleted ? Color.moodGreen.opacity(0.3) : Color.echoTextMuted.opacity(0.1),
                    lineWidth: 1.5
                )
        )
        .opacity(activity.isCompleted ? 0.7 : 1)
    }
}

// MARK: - Activity Detail View
struct ActivityDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var activity: Activity
    @State private var currentStep = 0
    @State private var showConfetti = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(activity.category.color.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: activity.icon)
                            .font(.system(size: 50))
                            .foregroundColor(activity.category.color)
                    }
                    .padding(.top, 20)
                    
                    // Title & Description
                    VStack(spacing: 8) {
                        Text(activity.title)
                            .font(.echoTitle)
                            .foregroundColor(Color.echoTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(activity.description)
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Info Pills
                    HStack(spacing: 16) {
                        InfoPill(icon: "clock.fill", text: activity.duration, color: activity.category.color)
                        InfoPill(icon: "tag.fill", text: activity.category.rawValue, color: activity.category.color)
                    }
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pasos a seguir")
                            .font(.echoHeadline)
                            .foregroundColor(Color.echoTextPrimary)
                        
                        ForEach(activity.steps.indices, id: \.self) { index in
                            StepRow(
                                stepNumber: index + 1,
                                stepText: activity.steps[index],
                                isCompleted: index <= currentStep,
                                color: activity.category.color
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    currentStep = index
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(hex: "#F8FBFD"))
                    .cornerRadius(18)
                    .padding(.horizontal, 20)
                    
                    // Complete Button
                    if !activity.isCompleted {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                activity.isCompleted = true
                                activity.completedAt = Date()
                                showConfetti = true
                            }
                            
                            // Auto-dismiss después de 1.5 segundos
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Marcar como completada")
                                    .fontWeight(.semibold)
                            }
                            .font(.echoSubheadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(activity.category.color)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 20)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.moodGreen)
                            Text("¡Actividad completada!")
                                .font(.echoSubheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.moodGreen)
                        }
                        .padding(.vertical, 16)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarItems(
                trailing: Button("Cerrar") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .overlay(
            showConfetti ? ConfettiView() : nil
        )
    }
}

// MARK: - Info Pill
struct InfoPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
                .fontWeight(.semibold)
        }
        .font(.echoSmall)
        .foregroundColor(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Step Row
struct StepRow: View {
    let stepNumber: Int
    let stepText: String
    let isCompleted: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : Color.echoTextMuted.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(stepNumber)")
                        .font(.echoSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.echoTextMuted)
                }
            }
            
            Text(stepText)
                .font(.echoSubheadline)
                .foregroundColor(isCompleted ? Color.echoTextPrimary : Color.echoTextSecondary)
                .strikethrough(isCompleted, color: color.opacity(0.5))
            
            Spacer()
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<30) { _ in
                Circle()
                    .fill([Color.echoTeal, Color.echoCoral, Color.echoAmber, Color.moodGreen].randomElement()!)
                    .frame(width: CGFloat.random(in: 8...16), height: CGFloat.random(in: 8...16))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: animate ? UIScreen.main.bounds.height + 50 : -50
                    )
                    .animation(
                        .linear(duration: Double.random(in: 1.5...3.0))
                        .repeatForever(autoreverses: false),
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            animate = true
        }
    }
}
