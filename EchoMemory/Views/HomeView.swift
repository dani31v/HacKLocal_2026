import SwiftUI


struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var cardAppeared = false
    @State private var postItAppeared = false
    @State private var reminderIndex = 0
    
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var detectedEmotion: String? = nil
    @State private var isAnalyzing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // MARK: - Header greeting
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hola,")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextSecondary)
                        Text(appState.userName)
                            .font(.echoTitle)
                            .foregroundColor(Color.echoTextPrimary)
                    }
                    Spacer()
                   
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Hoy es")
                            .font(.echoSmall)
                            .foregroundColor(Color.echoTextMuted)
                        Text(Date().dayOfWeekSpanish)
                            .font(.echoCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.black)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                   // .background(Color.echoMint)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // MARK: - Identity Card
                IdentityCard()
                    .opacity(cardAppeared ? 1 : 0)
                    .offset(y: cardAppeared ? 0 : 20)
                    .padding(.horizontal, 20)

                // MARK: - Post-it message of the day
                PostItMessage(message: appState.todayMessage)
                    .opacity(postItAppeared ? 1 : 0)
                    .scaleEffect(postItAppeared ? 1 : 0.9)
                    .padding(.horizontal, 20)
                    

                // MARK: - Reminders
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recordatorios de hoy")
                            .font(.echoSubheadline)
                            .foregroundColor(Color.echoTextPrimary)
                        Spacer()
                        Button {
                            appState.showAddReminder = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.echoCoral)
                        }
                    }
                    .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            let sortedIndices = appState.reminders.indices.sorted {
                                let r1 = appState.reminders[$0]
                                let r2 = appState.reminders[$1]
                                if r1.isCompleted != r2.isCompleted {
                                    return !r1.isCompleted && r2.isCompleted
                                }
                                return r1.timeDate < r2.timeDate
                            }
                            ForEach(sortedIndices, id: \.self) { index in
                                ReminderCard(reminder: $appState.reminders[index])
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // MARK: - Caregiver message
                if appState.hasUnreadMessage {
                    CaregiverMessageBanner()
                        .padding(.horizontal, 20)
                }

                // MARK: - Emotion Registration Card
                VStack(spacing: 16) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("¿Cómo te sientes hoy?")
                                .font(.echoHeadline)
                                .foregroundColor(Color.echoTextPrimary)
                            Text("Sube una foto para actividades personalizadas")
                                .font(.echoSmall)
                                .foregroundColor(Color.echoTextSecondary)
                        }
                        Spacer()
                    }
                    
                    // Image Picker Button (UIKit - No crashea)
                    Button {
                        showImagePicker = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.echoTeal.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.echoTeal)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Seleccionar foto")
                                    .font(.echoSubheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.echoTextPrimary)
                                Text("De tu galería")
                                    .font(.echoSmall)
                                    .foregroundColor(Color.echoTextSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color.echoTextMuted)
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.echoTeal.opacity(0.2), lineWidth: 1.5)
                        )
                    }
                    
                    // Status messages
                    if isAnalyzing {
                        HStack {
                            ProgressView()
                            Text("Analizando tu emoción...")
                                .font(.echoSmall)
                                .foregroundColor(Color.echoTextSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.echoTeal.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    if let emotion = detectedEmotion, !isAnalyzing {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.moodGreen)
                            Text(CapturedEmotion(emotion: emotion, timestamp: Date()).displayMessage)
                                .font(.echoSubheadline)
                                .foregroundColor(Color.echoTextPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.moodGreen.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .echoCard()
                .padding(.horizontal, 20)

                Spacer(minLength: 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                cardAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.4)) {
                postItAppeared = true
            }
        }
        .sheet(isPresented: $appState.showAddReminder) {
            AddReminderSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            guard let image = newImage else { return }
            Task {
                await analyzeImage(image)
            }
        }
    }
    
    
    // MARK: - Image Analysis
    
    private func analyzeImage(_ image: UIImage) async {
        await MainActor.run {
            isAnalyzing = true
            detectedEmotion = nil
        }
        
        do {
            // Detectar emoción usando Vision
            let emotionService = EmotionDetectionService()
            let emotion = try await emotionService.detectEmotion(from: image)
            
            await MainActor.run {
                self.detectedEmotion = emotion
                self.isAnalyzing = false
                
                // Guardar en estado global
                let captured = CapturedEmotion(
                    emotion: emotion,
                    capturedImage: image,
                    timestamp: Date()
                )
                self.appState.todayEmotion = captured
                
                print("🎭 Emoción detectada: \(emotion)")
            }
            
            // Generar actividades automáticamente
            await generateActivitiesForEmotion(emotion)
            
        } catch {
            await MainActor.run {
                self.detectedEmotion = "Neutral"
                self.isAnalyzing = false
                print("❌ Error: \(error.localizedDescription)")
            }
            
            // Generar actividades de fallback
            await generateActivitiesForEmotion("Neutral")
        }
    }
    
    /// Genera actividades usando ChatGPT basadas en la emoción detectada
    private func generateActivitiesForEmotion(_ emotion: String) async {
        // Marcar que estamos generando
        await MainActor.run {
            self.appState.isGeneratingActivities = true
        }
        
        let apiKey = ""
        let chatGPTService = ChatGPTService(apiKey: apiKey)
        
        do {
            let response = try await chatGPTService.generateAdviceAndActivities(
                for: emotion,
                userName: appState.userName
            )
            
            await MainActor.run {
                // Convertir SuggestedActivity a Activity y guardar en AppState
                self.appState.todayActivities = response.activities.map { $0.toActivity() }
                self.appState.isGeneratingActivities = false
                
                print("✅ Actividades generadas: \(self.appState.todayActivities.count)")
                self.appState.todayActivities.forEach { activity in
                    print("  - \(activity.title)")
                }
                
                // También generar algunos recordatorios simples
                self.generateRemindersForEmotion(emotion)
            }
            
        } catch {
            print("❌ Error generando actividades: \(error)")
            
            await MainActor.run {
                self.appState.isGeneratingActivities = false
                // Generar recordatorios al menos
                self.generateRemindersForEmotion(emotion)
            }
        }
    }
    
    /// Genera recordatorios simples (complementarios a las actividades)
    private func generateRemindersForEmotion(_ emotion: String) {
        let lower = emotion.lowercased()
        var suggestions: [Reminder] = []
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        func makeReminder(title: String, detail: String, icon: String, color: Color) -> Reminder {
            let timeString = formatter.string(from: now)
            return Reminder(
                title: title,
                detail: detail,
                time: timeString,
                timeDate: now,
                icon: icon,
                accentColor: color
            )
        }

        if lower.contains("feliz") || lower.contains("alegr") {
            suggestions.append(makeReminder(title: "Llama a un ser querido", detail: "Comparte tu buen momento", icon: "phone.fill", color: Color.moodGreen))
        } else if lower.contains("triste") || lower.contains("baj") {
            suggestions.append(makeReminder(title: "Respira profundo", detail: "Ejercicio de respiración 3 minutos", icon: "lungs.fill", color: Color.echoAmber))
        } else {
            suggestions.append(makeReminder(title: "Hidratación", detail: "Bebe un vaso de agua", icon: "drop.fill", color: Color.echoTeal))
        }

        // Evitar duplicados simples
        for r in suggestions {
            let exists = appState.reminders.contains { $0.title == r.title && abs($0.timeDate.timeIntervalSince(now)) < 60 }
            if !exists {
                appState.reminders.append(r)
            }
        }
    }
}

// MARK: - Identity Card
struct IdentityCard: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.echoAmber.opacity(0.4), Color.echoCoral.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Text(appState.caregiverEmoji)
                    .font(.system(size: 44))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Tu ser querido más cercano")
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextMuted)

                Text(appState.caregiverName)
                    .font(.echoHeadline)
                    .foregroundColor(Color.echoTextPrimary)

                HStack(spacing: 8) {
                    Label("\(appState.userAge) años", systemImage: "person.fill")
                    Spacer()
                    Label(Date().dayMonth, systemImage: "calendar")
                }
                .font(.echoCaption)
                .foregroundColor(Color.echoTextSecondary)
            }
        }
        .padding(20)
        .echoCard()
    }
}

// MARK: - Post-It Message
struct PostItMessage: View {
    let message: String
    @State private var unfolded = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 22))
                .foregroundColor(Color.echoTeal)

            VStack(alignment: .leading, spacing: 6) {
                Text("Mensaje del día")
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextMuted)
                Text(message)
                    .font(.echoSubheadline)
                    .foregroundColor(Color.echoTextPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(hex: "#FFFBEC")
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.echoTeal.opacity(0.3), lineWidth: 1.5)
                )
        )
        .cornerRadius(18)
        .shadow(color: Color.echoTeal.opacity(0.15), radius: 10, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                unfolded = true
            }
        }
    }
}

// MARK: - Reminder Card
struct ReminderCard: View {
    @Binding var reminder: Reminder

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(reminder.accentColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: reminder.icon)
                        .font(.system(size: 18))
                        .foregroundColor(reminder.accentColor)
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        reminder.isCompleted.toggle()
                    }
                } label: {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(reminder.isCompleted ? Color.moodGreen : Color.echoTextMuted)
                }
            }

            Text(reminder.title)
                .font(.echoCaption)
                .fontWeight(.semibold)
                .foregroundColor(Color.echoTextPrimary)

            Text(reminder.detail)
                .font(.echoSmall)
                .foregroundColor(Color.echoTextSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Label(reminder.time, systemImage: "clock.fill")
                .font(.echoSmall)
                .foregroundColor(reminder.accentColor)
        }
        .padding(16)
        .frame(width: 160, height: 160)
        .echoCard()
        .opacity(reminder.isCompleted ? 0.6 : 1)
    }
}

// MARK: - Caregiver Message Banner
struct CaregiverMessageBanner: View {
    @EnvironmentObject var appState: AppState
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 14) {
            // Pulsing heart
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundColor(Color.echoCoral)
                .scaleEffect(heartScale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                        heartScale = 1.2
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.caregiverName) te mandó un mensaje")
                    .font(.echoCaption)
                    .foregroundColor(Color.echoTextPrimary)
                    .fontWeight(.semibold)
                Text("Toca para escuchar")
                    .font(.echoSmall)
                    .foregroundColor(Color.echoTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.echoTextMuted)
        }
        .padding(16)
        .background(Color(hex: "#FFF0F0"))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.echoCoral.opacity(0.25), lineWidth: 1.5)
        )
        .onTapGesture {
            withAnimation {
                appState.selectedTab = .messages
                appState.hasUnreadMessage = false
            }
        }
    }
}

// MARK: - Add Reminder Sheet
struct AddReminderSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var time: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del recordatorio")) {
                    TextField("Título (ej. Pastilla)", text: $title)
                    TextField("Descripción (opcional)", text: $detail)
                }
                
                Section(header: Text("Hora")) {
                    DatePicker("Selecciona la hora", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
            }
            .navigationTitle("Nuevo Recordatorio")
            .navigationBarItems(
                leading: Button("Cancelar") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Guardar") {
                    saveReminder()
                }
                .disabled(title.isEmpty)
                .font(.headline)
            )
        }
    }
    
    private func saveReminder() {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: time)
        
        let newReminder = Reminder(
            title: title,
            detail: detail,
            time: timeString,
            timeDate: time,
            icon: "bell.fill",
            accentColor: Color.echoTeal
        )
        
        withAnimation {
            appState.reminders.append(newReminder)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

extension Notification.Name {
    static let newEmotionCaptured = Notification.Name("NewEmotionCapturedNotification")
}

