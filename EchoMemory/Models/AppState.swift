import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var userName: String = "Carmen"
    @Published var userAge: Int = 47
    @Published var todayMessage: String = "Hoy vas a tomar tu medicamento a las 9 AM."
    @Published var caregiverName: String = "Tu hija"
    @Published var caregiverEmoji: String = "👩🏽"
    @Published var hasUnreadMessage: Bool = true
    @Published var emotionalEntries: [EmotionalEntry] = EmotionalEntry.sampleData()
    @Published var photoMemories: [PhotoMemory] = PhotoMemory.sampleData()
    @Published var reminders: [Reminder] = Reminder.sampleData()
    @Published var voiceMessages: [VoiceMessage] = VoiceMessage.sampleMessages()
    @Published var showWelcomeAnimation: Bool = true
    @Published var showAddReminder: Bool = false

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case photos = "photo.fill"
        case messages = "mic.fill"
        case history = "chart.line.uptrend.xyaxis"

        var label: String {
            switch self {
            case .home: return "Inicio"
            case .photos: return "Fotos"
            case .messages: return "Mensajes"
            case .history: return "Historial"
            }
        }
    }
}
